extends Control

@onready var tab_container = $VBoxContainer/TabContainer
@onready var back_btn = $VBoxContainer/BackBtn

# Audio controls
@onready var master_volume = $VBoxContainer/TabContainer/Audio/VBoxContainer/MasterRow/MasterVolume
@onready var master_value = $VBoxContainer/TabContainer/Audio/VBoxContainer/MasterRow/MasterValue
@onready var music_volume = $VBoxContainer/TabContainer/Audio/VBoxContainer/MusicRow/MusicVolume
@onready var music_value = $VBoxContainer/TabContainer/Audio/VBoxContainer/MusicRow/MusicValue
@onready var sfx_volume = $VBoxContainer/TabContainer/Audio/VBoxContainer/SFXRow/SFXVolume
@onready var sfx_value = $VBoxContainer/TabContainer/Audio/VBoxContainer/SFXRow/SFXValue

# Video controls
@onready var fullscreen_checkbox = $VBoxContainer/TabContainer/Video/VBoxContainer/FullscreenCheck
@onready var vsync_checkbox = $VBoxContainer/TabContainer/Video/VBoxContainer/VSyncCheck

# Misc controls
@onready var controller_type_option = $VBoxContainer/TabContainer/Misc/VBoxContainer/ControllerTypeOption

# Scroll container for auto-scrolling
@onready var scroll_container = $VBoxContainer/TabContainer/Controls/VBoxContainer/ScrollContainer

# Controller button names
const XBOX_NAMES = {
	"jump": "A",
	"dash": "B",
	"interact": "X",
	"reset": "Y",
	"view": "View"
}

const PS_NAMES = {
	"jump": "Cross",
	"dash": "Circle",
	"interact": "Square",
	"reset": "Triangle",
	"view": "Share"
}

enum ControllerType { XBOX, PLAYSTATION }
var current_controller_type: int = ControllerType.XBOX

# Keybinding state
var is_waiting_for_input: bool = false
var current_binding_action: String = ""
var current_binding_type: String = ""
var current_binding_button: Button = null
var previous_binding_text: String = ""

signal back_pressed

func _ready() -> void:
	# Allow processing while game is paused (for pause menu)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Load saved settings
	_load_settings()
	
	# Connect audio sliders
	master_volume.value_changed.connect(_on_master_volume_changed)
	music_volume.value_changed.connect(_on_music_volume_changed)
	sfx_volume.value_changed.connect(_on_sfx_volume_changed)
	
	# Connect video checkboxes
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	vsync_checkbox.toggled.connect(_on_vsync_toggled)
	
	# Connect controller type option
	controller_type_option.item_selected.connect(_on_controller_type_changed)
	
	# Connect tab changed signal
	tab_container.tab_changed.connect(_on_tab_changed)
	
	# Disable TabContainer's built-in navigation to prevent stick from changing tabs
	tab_container.set_process_unhandled_input(false)
	
	# Make absolutely sure tabs cannot receive focus
	tab_container.focus_mode = Control.FOCUS_NONE
	tab_container.focus_neighbor_left = tab_container.get_path()  # Self-loop
	tab_container.focus_neighbor_right = tab_container.get_path()  # Self-loop
	for i in range(tab_container.get_tab_count()):
		var tab = tab_container.get_tab_control(i)
		if tab:
			tab.focus_mode = Control.FOCUS_NONE
			# Also disable all children from being focusable
			_disable_children_focus(tab)
			# Set tab focus neighbors to self to prevent navigation
			tab.focus_neighbor_left = tab.get_path()
			tab.focus_neighbor_right = tab.get_path()

func _disable_children_focus(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.focus_mode = Control.FOCUS_NONE
		_disable_children_focus(child)
	
	# Setup keybinding buttons
	_setup_keybinding_buttons()

func _setup_keybinding_buttons() -> void:
	var bindings_container = $VBoxContainer/TabContainer/Controls/VBoxContainer/ScrollContainer/BindingsList
	var reset_defaults_btn = $VBoxContainer/TabContainer/Controls/VBoxContainer/ResetDefaultsBtn
	var rows = []
	
	# Track keyboard buttons to enable/disable based on controller
	var keyboard_buttons = []
	var controller_buttons = []
	
	# Collect all rows first
	for row in bindings_container.get_children():
		if row is HBoxContainer:
			rows.append(row)
	
	# Setup each row with focus neighbors
	for i in range(rows.size()):
		var row = rows[i]
		var action_name = row.name
		# Convert PascalCase node name to snake_case action name
		match action_name:
			"MoveLeft": action_name = "move_left"
			"MoveRight": action_name = "move_right"
			"MoveForward": action_name = "move_forward"
			"MoveBack": action_name = "move_back"
			"Jump": action_name = "jump"
			"Dash": action_name = "dash"
			"Interact": action_name = "interact"
			"Reset": action_name = "Reset"
		var kb_btn = row.get_node("KeyboardBtn")
		var ctrl_btn = row.get_node("ControllerBtn")
		
		# Only connect if not already connected
		if not kb_btn.pressed.is_connected(_on_binding_button_pressed.bind(action_name, "keyboard", kb_btn)):
			kb_btn.pressed.connect(_on_binding_button_pressed.bind(action_name, "keyboard", kb_btn))
		if not ctrl_btn.pressed.is_connected(_on_binding_button_pressed.bind(action_name, "controller", ctrl_btn)):
			ctrl_btn.pressed.connect(_on_binding_button_pressed.bind(action_name, "controller", ctrl_btn))
		
		# Connect focus signals for auto-scrolling (check if already connected)
		if not kb_btn.focus_entered.is_connected(_on_button_focused.bind(kb_btn)):
			kb_btn.focus_entered.connect(_on_button_focused.bind(kb_btn))
		if not ctrl_btn.focus_entered.is_connected(_on_button_focused.bind(ctrl_btn)):
			ctrl_btn.focus_entered.connect(_on_button_focused.bind(ctrl_btn))
		
		# Horizontal navigation between keyboard and controller buttons
		kb_btn.focus_neighbor_right = ctrl_btn.get_path()
		ctrl_btn.focus_neighbor_left = kb_btn.get_path()
		# Prevent navigation escaping to tabs
		kb_btn.focus_neighbor_left = kb_btn.get_path()  # Left stays on keyboard
		ctrl_btn.focus_neighbor_right = ctrl_btn.get_path()  # Right stays on controller
		
		# Vertical navigation - connect to Reset/Back buttons at edges
		if i == 0:
			# First row - UP goes to ResetDefaultsBtn
			kb_btn.focus_neighbor_top = reset_defaults_btn.get_path()
			ctrl_btn.focus_neighbor_top = reset_defaults_btn.get_path()
		else:
			# UP goes to previous row
			var prev_row = rows[i - 1]
			kb_btn.focus_neighbor_top = prev_row.get_node("KeyboardBtn").get_path()
			ctrl_btn.focus_neighbor_top = prev_row.get_node("ControllerBtn").get_path()
		
		if i == rows.size() - 1:
			# Last row - DOWN goes to Back button
			kb_btn.focus_neighbor_bottom = back_btn.get_path()
			ctrl_btn.focus_neighbor_bottom = back_btn.get_path()
		else:
			# DOWN goes to next row
			var next_row = rows[i + 1]
			kb_btn.focus_neighbor_bottom = next_row.get_node("KeyboardBtn").get_path()
			ctrl_btn.focus_neighbor_bottom = next_row.get_node("ControllerBtn").get_path()
	
	# Setup ResetDefaultsBtn navigation - UP stays on ResetDefaultsBtn
	reset_defaults_btn.focus_neighbor_bottom = rows[0].get_node("KeyboardBtn").get_path()
	reset_defaults_btn.focus_neighbor_top = reset_defaults_btn.get_path()
	# LEFT/RIGHT stay on ResetDefaultsBtn to prevent reaching tabs
	reset_defaults_btn.focus_neighbor_left = reset_defaults_btn.get_path()
	reset_defaults_btn.focus_neighbor_right = reset_defaults_btn.get_path()
	
	# Setup Back button navigation - DOWN stays on BackBtn
	back_btn.focus_neighbor_top = rows[rows.size() - 1].get_node("KeyboardBtn").get_path()
	back_btn.focus_neighbor_bottom = back_btn.get_path()
	
	# Update button states based on controller connection
	_update_button_states(keyboard_buttons, controller_buttons)
	
	_update_controller_buttons()

func _update_button_states(keyboard_buttons: Array, controller_buttons: Array) -> void:
	var has_controller = Input.get_connected_joypads().size() > 0
	
	for btn in keyboard_buttons:
		if has_controller:
			btn.disabled = true
			btn.text = "Keyboard"
		else:
			btn.disabled = false
	
	for btn in controller_buttons:
		if has_controller:
			btn.disabled = false
		else:
			btn.disabled = true
			btn.text = "Controller"

func _on_button_focused(button: Button) -> void:
	# Auto-scroll to keep focused button visible
	# Need to calculate global position and convert to scroll container local space
	var scroll_global_pos = scroll_container.global_position
	var button_global_pos = button.global_position
	
	# Calculate relative position within the scroll container
	var button_rel_y = button_global_pos.y - scroll_global_pos.y
	var button_height = button.size.y
	var scroll_height = scroll_container.size.y
	var current_scroll = scroll_container.scroll_vertical
	
	# If button is above visible area, scroll up
	if button_rel_y < 0:
		scroll_container.scroll_vertical = current_scroll + button_rel_y - 5
	# If button is below visible area, scroll down
	elif button_rel_y + button_height > scroll_height:
		scroll_container.scroll_vertical = current_scroll + button_rel_y + button_height - scroll_height + 5

func _on_binding_button_pressed(action: String, type: String, button: Button) -> void:
	if is_waiting_for_input:
		return
	

	is_waiting_for_input = true
	current_binding_action = action
	current_binding_type = type
	current_binding_button = button
	previous_binding_text = button.text  # Store current text before changing
	
	button.text = "Press key..."
	button.grab_focus()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	

	
	# Tab switching with shoulder buttons (R1/L1) - only button presses, not stick
	if not is_waiting_for_input:
		if event is InputEventJoypadButton and event.pressed:
			# Ensure this is actually a shoulder button, not stick input mistakenly detected
			if event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
				# R1 - next tab
				tab_container.current_tab = (tab_container.current_tab + 1) % tab_container.get_tab_count()
				get_viewport().set_input_as_handled()
				return
			elif event.button_index == JOY_BUTTON_LEFT_SHOULDER:
				# L1 - previous tab
				var tab_count = tab_container.get_tab_count()
				tab_container.current_tab = (tab_container.current_tab - 1 + tab_count) % tab_count
				get_viewport().set_input_as_handled()
				return
			elif event.button_index == JOY_BUTTON_B:
				# B button (Circle on PS) - click Back
				_on_back_btn_pressed()
				get_viewport().set_input_as_handled()
				return
		# Also handle Escape key explicitly like Back button
		elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			# Escape - click Back (when not waiting for keybinding input)
			_on_back_btn_pressed()
			get_viewport().set_input_as_handled()
			return
	
	if event.is_action_pressed("ui_cancel") and not is_waiting_for_input:
		_on_back_btn_pressed()
		return
	
	if is_waiting_for_input and current_binding_button:
		# Check for Escape to cancel keybinding
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_cancel_binding()
			get_viewport().set_input_as_handled()
			return
		

		if current_binding_type == "keyboard":
			if event is InputEventKey and event.pressed:
				_accept_binding(event)
				get_viewport().set_input_as_handled()
				return
		elif current_binding_type == "controller":
			if event is InputEventJoypadButton and event.pressed:
				# Menu/Start button (button 7) cancels the assignment
				if event.button_index == JOY_BUTTON_START:
					_cancel_binding()
					get_viewport().set_input_as_handled()
					return
				_accept_binding(event)
				get_viewport().set_input_as_handled()
				return
			elif event is InputEventJoypadMotion and event.pressed:
				_accept_binding(event)
				get_viewport().set_input_as_handled()
				return

func _accept_binding(event: InputEvent) -> void:
	var existing_events = InputMap.action_get_events(current_binding_action)
	for existing in existing_events:
		if current_binding_type == "keyboard" and existing is InputEventKey:
			InputMap.action_erase_event(current_binding_action, existing)
		elif current_binding_type == "controller" and (existing is InputEventJoypadButton or existing is InputEventJoypadMotion):
			InputMap.action_erase_event(current_binding_action, existing)
	
	# Check if this button/key is already assigned to another action
	var actions = ["move_left", "move_right", "move_forward", "move_back", "jump", "dash", "interact", "Reset"]
	for action in actions:
		if action == current_binding_action:
			continue  # Skip the current action we're binding to
		
		var action_events = InputMap.action_get_events(action)
		for existing in action_events:
			var is_match = false
			
			if current_binding_type == "keyboard" and existing is InputEventKey and event is InputEventKey:
				if existing.keycode == event.keycode:
					is_match = true
					
			elif current_binding_type == "controller":
				if existing is InputEventJoypadButton and event is InputEventJoypadButton:
					if existing.button_index == event.button_index:
						is_match = true
				elif existing is InputEventJoypadMotion and event is InputEventJoypadMotion:
					if existing.axis == event.axis and existing.axis_value == event.axis_value:
						is_match = true
			
			if is_match:
				# Remove from the other action
				InputMap.action_erase_event(action, existing)
				# Update the UI for that action
				_update_binding_button_text(action)
				break
	
	InputMap.action_add_event(current_binding_action, event)
	_update_binding_button_text(current_binding_action)
	
	is_waiting_for_input = false
	current_binding_action = ""
	current_binding_type = ""
	current_binding_button = null
	
	_save_settings()

func _cancel_binding() -> void:
	if current_binding_button:
		current_binding_button.text = previous_binding_text  # Restore previous text
	
	is_waiting_for_input = false
	current_binding_action = ""
	current_binding_type = ""
	current_binding_button = null
	previous_binding_text = ""

func _update_binding_button_text(action: String) -> void:
	var _bindings_container = $VBoxContainer/TabContainer/Controls/VBoxContainer/ScrollContainer/BindingsList
	var action_row = _bindings_container.get_node(action.to_pascal_case())
	if not action_row:
		return
	
	var kb_btn = action_row.get_node("KeyboardBtn")
	var ctrl_btn = action_row.get_node("ControllerBtn")
	
	var events = InputMap.action_get_events(action)
	var kb_text = "None"
	var ctrl_text = "None"
	
	for event in events:
		if event is InputEventKey:
			kb_text = event.as_text()
		elif event is InputEventJoypadButton:
			ctrl_text = _get_controller_button_text(event.button_index)
		elif event is InputEventJoypadMotion:
			ctrl_text = _get_axis_text(event.axis, event.axis_value)
	
	kb_btn.text = kb_text
	ctrl_btn.text = ctrl_text

func _get_controller_button_text(button_index: int) -> String:
	# Return Xbox/PS label based on controller type
	var names = XBOX_NAMES if current_controller_type == ControllerType.XBOX else PS_NAMES
	
	# Map button index to name
	match button_index:
		0: return names["jump"]  # A / Cross
		1: return names["dash"]  # B / Circle
		2: return names["interact"]  # X / Square
		3: return names["reset"]  # Y / Triangle
		4: return "LB" if current_controller_type == ControllerType.XBOX else "L1"
		5: return "RB" if current_controller_type == ControllerType.XBOX else "R1"
		6: return names["view"]  # View / Share
		7: return "Menu"  # Start/Options button
		8: return "L3"
		9: return "R3"
		_: return "Btn %d" % button_index

func _get_axis_text(axis: int, value: float) -> String:
	match axis:
		0: return "LS Right" if value > 0 else "LS Left"
		1: return "LS Down" if value > 0 else "LS Up"
		2: return "RS Right" if value > 0 else "RS Left"
		3: return "RS Down" if value > 0 else "RS Up"
		4: return "L2" if current_controller_type == ControllerType.PLAYSTATION else "LT"
		5: return "R2" if current_controller_type == ControllerType.PLAYSTATION else "RT"
	return ""

func _update_controller_buttons() -> void:
	var names = XBOX_NAMES if current_controller_type == ControllerType.XBOX else PS_NAMES
	
	# Update preview labels in Misc tab
	var preview_container = $VBoxContainer/TabContainer/Misc/VBoxContainer/ButtonPreview
	preview_container.get_node("ABtn").text = names["jump"]
	preview_container.get_node("BBtn").text = names["dash"]
	preview_container.get_node("XBtn").text = names["interact"]
	preview_container.get_node("YBtn").text = names["reset"]
	
	# Update all control binding buttons
	var actions = ["move_left", "move_right", "move_forward", "move_back", "jump", "dash", "interact", "Reset"]
	for action in actions:
		_update_binding_button_text(action)

func _enable_tab_focus(tab_idx: int) -> void:
	# First disable focus on all tabs
	for i in range(tab_container.get_tab_count()):
		var tab = tab_container.get_tab_control(i)
		if tab:
			_disable_children_focus(tab)
	
	# Then enable focus only on current tab
	var current_tab = tab_container.get_tab_control(tab_idx)
	if current_tab:
		_set_children_focus_mode(current_tab, Control.FOCUS_ALL)

func _set_children_focus_mode(node: Node, mode: int) -> void:
	for child in node.get_children():
		if child is Control:
			# Only interactive controls should have focus enabled
			if child is Button or child is Slider or child is CheckBox or child is OptionButton:
				child.focus_mode = mode
			else:
				# Non-interactive controls always stay FOCUS_NONE
				child.focus_mode = Control.FOCUS_NONE
			_set_children_focus_mode(child, mode)

func _on_tab_changed(tab: int) -> void:
	# Re-enable focus for interactive elements in the current tab only
	_enable_tab_focus(tab)
	
	# Give focus to first interactive element in the new tab
	match tab:
		0:  # Audio
			_setup_audio_tab_focus()
			# Set Back button's UP to point to last audio element
			back_btn.focus_neighbor_top = sfx_volume.get_path()
			master_volume.grab_focus()
		1:  # Video
			_setup_video_tab_focus()
			# Set Back button's UP to point to last video element
			back_btn.focus_neighbor_top = vsync_checkbox.get_path()
			fullscreen_checkbox.grab_focus()
		2:  # Controls
			# Focus the first binding button (MoveLeft - KeyboardBtn)
			var bindings_container = $VBoxContainer/TabContainer/Controls/VBoxContainer/ScrollContainer/BindingsList
			if bindings_container.get_child_count() > 0:
				var first_row = bindings_container.get_child(0)
				if first_row is HBoxContainer:
					first_row.get_node("KeyboardBtn").grab_focus()
			scroll_container.scroll_vertical = 0  # Reset scroll to top
		3:  # Misc
			_setup_misc_tab_focus()
			# Set Back button's UP to point to misc element
			back_btn.focus_neighbor_top = controller_type_option.get_path()
			controller_type_option.grab_focus()

func _setup_audio_tab_focus() -> void:
	# Prevent navigation up to tabs - first element's UP stays on self
	master_volume.focus_neighbor_top = master_volume.get_path()
	master_volume.focus_neighbor_left = master_volume.get_path()
	master_volume.focus_neighbor_right = master_value.get_path()
	
	# Middle elements - prevent left/right from reaching tabs
	music_volume.focus_neighbor_left = music_volume.get_path()
	music_volume.focus_neighbor_right = music_value.get_path()
	
	sfx_volume.focus_neighbor_left = sfx_volume.get_path()
	sfx_volume.focus_neighbor_right = sfx_value.get_path()
	
	# Last element's DOWN goes to Back button
	sfx_volume.focus_neighbor_bottom = back_btn.get_path()

func _setup_video_tab_focus() -> void:
	# First element - UP stays on self, prevent left/right
	fullscreen_checkbox.focus_neighbor_top = fullscreen_checkbox.get_path()
	fullscreen_checkbox.focus_neighbor_left = fullscreen_checkbox.get_path()
	fullscreen_checkbox.focus_neighbor_right = fullscreen_checkbox.get_path()
	
	# Last element - DOWN goes to Back button
	vsync_checkbox.focus_neighbor_bottom = back_btn.get_path()
	vsync_checkbox.focus_neighbor_left = vsync_checkbox.get_path()
	vsync_checkbox.focus_neighbor_right = vsync_checkbox.get_path()

func _setup_misc_tab_focus() -> void:
	# Only one interactive element - lock all navigation to self except DOWN to Back
	controller_type_option.focus_neighbor_top = controller_type_option.get_path()
	controller_type_option.focus_neighbor_left = controller_type_option.get_path()
	controller_type_option.focus_neighbor_right = controller_type_option.get_path()
	controller_type_option.focus_neighbor_bottom = back_btn.get_path()

func _on_controller_type_changed(index: int) -> void:
	current_controller_type = index
	_update_controller_buttons()
	_save_settings()

func _reset_keybindings_to_defaults() -> void:
	# Default keybindings
	var defaults = {
		"move_left": [KEY_A, JOY_AXIS_LEFT_X, -1.0],
		"move_right": [KEY_D, JOY_AXIS_LEFT_X, 1.0],
		"move_forward": [KEY_W, JOY_AXIS_LEFT_Y, -1.0],
		"move_back": [KEY_S, JOY_AXIS_LEFT_Y, 1.0],
		"jump": [KEY_SPACE, JOY_BUTTON_A],
		"dash": [KEY_SHIFT, JOY_BUTTON_B],
		"interact": [KEY_E, JOY_BUTTON_X],

		"Reset": [KEY_R, JOY_BUTTON_Y]
	}
	
	for action in defaults.keys():
		InputMap.action_erase_events(action)
		
		# Keyboard binding
		if defaults[action][0] is int:
			var key_event = InputEventKey.new()
			key_event.keycode = defaults[action][0]
			InputMap.action_add_event(action, key_event)
		
		# Controller binding
		if defaults[action][1] is int and defaults[action].size() == 3:
			# Axis motion
			var motion_event = InputEventJoypadMotion.new()
			motion_event.axis = defaults[action][1]
			motion_event.axis_value = defaults[action][2]
			InputMap.action_add_event(action, motion_event)
		else:
			# Button
			var button_event = InputEventJoypadButton.new()
			button_event.button_index = defaults[action][1]
			InputMap.action_add_event(action, button_event)
	
	# Update UI
	var actions = ["move_left", "move_right", "move_forward", "move_back", "jump", "dash", "interact", "Reset"]
	for action in actions:
		_update_binding_button_text(action)
	
	_save_settings()

func _on_reset_defaults_pressed() -> void:
	_reset_keybindings_to_defaults()

func _on_back_btn_pressed() -> void:
	is_waiting_for_input = false
	current_binding_action = ""
	current_binding_type = ""
	current_binding_button = null
	back_pressed.emit()
	hide()

func _get_bus_index(bus_name: String) -> int:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")
	return idx

func _on_master_volume_changed(value: float) -> void:
	master_value.text = "%d%%" % int(value)
	var idx = _get_bus_index("Master")
	AudioServer.set_bus_volume_db(idx, linear_to_db(value / 100.0))
	_save_settings()

func _on_music_volume_changed(value: float) -> void:
	music_value.text = "%d%%" % int(value)
	var idx = _get_bus_index("Music")
	AudioServer.set_bus_volume_db(idx, linear_to_db(value / 100.0))
	_save_settings()

func _on_sfx_volume_changed(value: float) -> void:
	sfx_value.text = "%d%%" % int(value)
	var idx = _get_bus_index("SFX")
	AudioServer.set_bus_volume_db(idx, linear_to_db(value / 100.0))
	_save_settings()

func _on_fullscreen_toggled(toggled: bool) -> void:
	if toggled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_save_settings()

func _on_vsync_toggled(toggled: bool) -> void:
	if toggled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_save_settings()

func _save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume.value)
	config.set_value("audio", "music_volume", music_volume.value)
	config.set_value("audio", "sfx_volume", sfx_volume.value)
	config.set_value("video", "fullscreen", fullscreen_checkbox.button_pressed)
	config.set_value("video", "vsync", vsync_checkbox.button_pressed)
	config.set_value("misc", "controller_type", current_controller_type)
	
	# Save keybindings
	var actions = ["move_left", "move_right", "move_forward", "move_back", "jump", "dash", "interact", "Reset"]
	for action in actions:
		var events = InputMap.action_get_events(action)
		config.set_value("keybindings", action, events)
	
	config.save("res://data/settings.cfg")

func _load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("res://data/settings.cfg")
	
	if err == OK:
		# Audio
		master_volume.value = config.get_value("audio", "master_volume", 80.0)
		music_volume.value = config.get_value("audio", "music_volume", 80.0)
		sfx_volume.value = config.get_value("audio", "sfx_volume", 80.0)
		
		# Video
		fullscreen_checkbox.button_pressed = config.get_value("video", "fullscreen", false)
		vsync_checkbox.button_pressed = config.get_value("video", "vsync", true)
		
		# Misc - just Xbox or PlayStation toggle
		current_controller_type = config.get_value("misc", "controller_type", ControllerType.XBOX)
		controller_type_option.select(current_controller_type)
		
		# Load keybindings
		if config.has_section("keybindings"):
			var actions = ["move_left", "move_right", "move_forward", "move_back", "jump", "dash", "interact", "Reset"]
			for action in actions:
				if config.has_section_key("keybindings", action):
					var events = config.get_value("keybindings", action, [])
					if events is Array:
						InputMap.action_erase_events(action)
						for event in events:
							if event is InputEvent:
								InputMap.action_add_event(action, event)
		else:
			# Set defaults
			master_volume.value = 80.0
			music_volume.value = 80.0
			sfx_volume.value = 80.0
			fullscreen_checkbox.button_pressed = false
			vsync_checkbox.button_pressed = true
			current_controller_type = ControllerType.XBOX
			controller_type_option.select(0)
	
	# Update UI
	_on_master_volume_changed(master_volume.value)
	_on_music_volume_changed(music_volume.value)
	_on_sfx_volume_changed(sfx_volume.value)
	_update_controller_buttons()

func show_menu() -> void:
	show()
	# Set to Audio tab first and focus the first element
	tab_container.current_tab = 0
	_enable_tab_focus(0)
	_setup_audio_tab_focus()
	back_btn.focus_neighbor_top = sfx_volume.get_path()
	master_volume.grab_focus.call_deferred()

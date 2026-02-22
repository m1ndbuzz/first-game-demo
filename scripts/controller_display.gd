extends Node

# Controller type enumeration
# AUTO = Detect automatically based on connected controller
# XBOX = Force Xbox button names
# PLAYSTATION = Force PlayStation button names
enum ControllerType { AUTO, XBOX, PLAYSTATION }

# Xbox controller button name mapping
# Maps button indices (0-15) to Xbox-style names
const XBOX_BUTTONS = {
	0: "A", 1: "B", 2: "X", 3: "Y",           # Face buttons
	4: "View", 5: "Xbox", 6: "Menu",          # Center buttons
	7: "LS", 8: "RS",                         # Stick click buttons
	9: "LB", 10: "RB",                        # Shoulder buttons
	11: "D-Up", 12: "D-Down",                 # D-pad vertical
	13: "D-Left", 14: "D-Right",              # D-pad horizontal
	15: "Share"                               # System buttons
}

# PlayStation controller button name mapping
# Maps button indices (0-15) to PlayStation-style names
const PS_BUTTONS = {
	0: "Cross", 1: "Circle", 2: "Square", 3: "Triangle",  # Face buttons
	4: "Select", 5: "PS", 6: "Start",                     # Center buttons
	7: "L3", 8: "R3",                                     # Stick click buttons
	9: "L1", 10: "R1",                                    # Shoulder buttons
	11: "D-Up", 12: "D-Down",                             # D-pad vertical
	13: "D-Left", 14: "D-Right",                          # D-pad horizontal
	15: "Mic"                                             # System buttons
}

# Generic fallback button mapping
# Used when controller type is unknown
const GENERIC_BUTTONS = {
	0: "Btn 0", 1: "Btn 1", 2: "Btn 2", 3: "Btn 3",
	4: "Btn 4", 5: "Btn 5", 6: "Btn 6", 7: "Btn 7",
	8: "Btn 8", 9: "Btn 9", 10: "Btn 10", 11: "Btn 11",
	12: "Btn 12", 13: "Btn 13", 14: "Btn 14", 15: "Btn 15"
}

# Current controller type setting (defaults to AUTO detection)
var current_controller_type: int = ControllerType.AUTO

# Called when the node enters the scene tree
# Loads the user's controller preference from settings
func _ready() -> void:
	load_settings()

# Loads controller type preference from settings file
# Falls back to AUTO if settings file doesn't exist or can't be read
func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("res://data/settings.cfg")
	if err == OK:
		current_controller_type = config.get_value("misc", "controller_type", ControllerType.AUTO)

# Detects if an Xbox controller is connected
# Checks the name of the first connected joypad for Xbox-related keywords
# Returns false if no controllers are connected
func is_xbox_controller() -> bool:
	if Input.get_connected_joypads().size() == 0:
		return false
	@warning_ignore("shadowed_variable_base_class")
	var name = Input.get_joy_name(0).to_lower()
	return "xbox" in name or "xinput" in name or "microsoft" in name

# Detects if a PlayStation controller is connected
# Checks the name of the first connected joypad for PlayStation-related keywords
# Returns false if no controllers are connected
func is_playstation_controller() -> bool:
	if Input.get_connected_joypads().size() == 0:
		return false
	@warning_ignore("shadowed_variable_base_class")
	var name = Input.get_joy_name(0).to_lower()
	return "playstation" in name or "ps" in name or "dualshock" in name or "dualsense" in name or "sony" in name

# Returns the display name for a controller button index
# Uses the appropriate button map based on current settings and auto-detection
# Falls back to "Btn {index}" if button is not in the map
func get_button_name(button_index: int) -> String:
	var button_map = GENERIC_BUTTONS
	
	# Determine which button map to use
	if current_controller_type == ControllerType.XBOX or (current_controller_type == ControllerType.AUTO and is_xbox_controller()):
		button_map = XBOX_BUTTONS
	elif current_controller_type == ControllerType.PLAYSTATION or (current_controller_type == ControllerType.AUTO and is_playstation_controller()):
		button_map = PS_BUTTONS
	
	return button_map.get(button_index, "Btn %d" % button_index)

# Returns the display name for an analog axis input
# Handles right stick (axes 0-1), camera/look (axes 2-3), and triggers (axes 4-5)
# Returns empty string for unknown axes
func get_axis_name(axis: int, value: float) -> String:
	# Check if we should use PlayStation naming (L2/R2) or Xbox naming (LT/RT)
	var is_ps = current_controller_type == ControllerType.PLAYSTATION or is_playstation_controller()
	
	match axis:
		0:
			return "RS Right" if value > 0 else "RS Left"
		1:
			return "RS Down" if value > 0 else "RS Up"
		2:
			return "Cam Right" if value > 0 else "Cam Left"
		3:
			return "Cam Down" if value > 0 else "Cam Up"
		4:
			return "L2" if is_ps else "LT"
		5:
			return "R2" if is_ps else "RT"
	return ""

# Returns a formatted display string for an input action
# Shows both keyboard and controller bindings if available
# Format examples: "Space / A", "W", "Cross", or empty string if no bindings
func get_input_display_text(action: String) -> String:
	# Get all input events mapped to this action
	var events = InputMap.action_get_events(action)
	var kb_text = ""
	var ctrl_text = ""
	
	# Find keyboard and controller bindings
	for event in events:
		if event is InputEventKey:
			# Keyboard key binding
			kb_text = event.as_text()
		elif event is InputEventJoypadButton:
			# Controller button binding
			ctrl_text = get_button_name(event.button_index)
		elif event is InputEventJoypadMotion:
			# Controller axis binding (stick or trigger)
			var axis_name = get_axis_name(event.axis, event.axis_value)
			if axis_name != "":
				ctrl_text = axis_name
	
	# Combine keyboard and controller text
	if kb_text != "" and ctrl_text != "":
		return "%s / %s" % [kb_text, ctrl_text]
	elif kb_text != "":
		return kb_text
	elif ctrl_text != "":
		return ctrl_text
	return ""

# Manually sets the controller type
# Called when user changes the controller type in options menu
func set_controller_type(type: int) -> void:
	current_controller_type = type

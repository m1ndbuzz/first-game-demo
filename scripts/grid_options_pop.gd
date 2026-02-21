extends GridContainer

# Actions you want to ignore (Godot defaults)
const EXCLUDED_ACTIONS = ["ui_accept", "ui_select", "ui_cancel", "ui_focus_next", "ui_focus_prev", "ui_left", "ui_right", "ui_up", "ui_down", "ui_page_up", "ui_page_down", "ui_home", "ui_end"]

func _ready():
	## 1. Clear existing placeholder nodes from the editor
	#for child in get_children():
		#child.queue_free()
	#
	## 2. Add Header Row
	#create_header("Action")
	#create_header("Keyboard")
	#create_header("Controller")
	
	# 3. Get all user-defined actions
	var actions = InputMap.get_actions()
	
	for action in actions:
		if action in EXCLUDED_ACTIONS or action.begins_with("ui_"):
			continue
			
		# Add Label for Action Name
		var label = Label.new()
		label.text = action.capitalize()
		setup_node_style(label)
		add_child(label)
		
		# Add Keyboard Button
		var kb_button = Button.new()
		kb_button.text = get_action_text(action, "key")
		setup_node_style(kb_button)
		add_child(kb_button)
		
		# Add Controller Button
		var joy_button = Button.new()
		joy_button.text = get_action_text(action, "joy")
		setup_node_style(joy_button)
		add_child(joy_button)

func create_header(title: String):
	var label = Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.YELLOW) # Make headers stand out
	setup_node_style(label)
	add_child(label)

func setup_node_style(node: Control):
	# This ensures the "Equal Space" and "Centering" we discussed
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if node is Label:
		node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func get_action_text(action: String, type: String) -> String:
	var events = InputMap.action_get_events(action)
	for event in events:
		# Handle Keyboard Inputs
		if type == "key" and event is InputEventKey:
			# Use physical_keycode if you mapped it as a physical key, 
			# otherwise use keycode for standard mapping
			var code = event.physical_keycode if event.physical_keycode != 0 else event.keycode
			return OS.get_keycode_string(code)
			
		# Handle Controller Inputs
		if type == "joy":
			if event is InputEventJoypadButton:
				return "Button " + str(event.button_index)
			if event is InputEventJoypadMotion:
				return "Axis " + str(event.axis)
				
	return "None"

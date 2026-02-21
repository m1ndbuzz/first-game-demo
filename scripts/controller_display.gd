extends Node

enum ControllerType { AUTO, XBOX, PLAYSTATION }

const XBOX_BUTTONS = {
	0: "A", 1: "B", 2: "X", 3: "Y",
	4: "LB", 5: "RB", 6: "View", 7: "Menu",
	8: "L3", 9: "R3", 10: "D-Up", 11: "D-Down",
	12: "D-Left", 13: "D-Right", 14: "Xbox", 15: "Share"
}

const PS_BUTTONS = {
	0: "Cross", 1: "Circle", 2: "Square", 3: "Triangle",
	4: "L1", 5: "R1", 6: "Create", 7: "Options",
	8: "L3", 9: "R3", 10: "D-Up", 11: "D-Down",
	12: "D-Left", 13: "D-Right", 14: "PS", 15: "Touchpad"
}

const GENERIC_BUTTONS = {
	0: "Btn 0", 1: "Btn 1", 2: "Btn 2", 3: "Btn 3",
	4: "Btn 4", 5: "Btn 5", 6: "Btn 6", 7: "Btn 7",
	8: "Btn 8", 9: "Btn 9", 10: "Btn 10", 11: "Btn 11",
	12: "Btn 12", 13: "Btn 13", 14: "Btn 14", 15: "Btn 15"
}

var current_controller_type: int = ControllerType.AUTO

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("res://data/settings.cfg")
	if err == OK:
		current_controller_type = config.get_value("misc", "controller_type", ControllerType.AUTO)

func is_xbox_controller() -> bool:
	if Input.get_connected_joypads().size() == 0:
		return false
	@warning_ignore("shadowed_variable_base_class")
	var name = Input.get_joy_name(0).to_lower()
	return "xbox" in name or "xinput" in name or "microsoft" in name

func is_playstation_controller() -> bool:
	if Input.get_connected_joypads().size() == 0:
		return false
	@warning_ignore("shadowed_variable_base_class")
	var name = Input.get_joy_name(0).to_lower()
	return "playstation" in name or "ps" in name or "dualshock" in name or "dualsense" in name or "sony" in name

func get_button_name(button_index: int) -> String:
	var button_map = GENERIC_BUTTONS
	
	if current_controller_type == ControllerType.XBOX or (current_controller_type == ControllerType.AUTO and is_xbox_controller()):
		button_map = XBOX_BUTTONS
	elif current_controller_type == ControllerType.PLAYSTATION or (current_controller_type == ControllerType.AUTO and is_playstation_controller()):
		button_map = PS_BUTTONS
	
	return button_map.get(button_index, "Btn %d" % button_index)

func get_axis_name(axis: int, value: float) -> String:
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

func get_input_display_text(action: String) -> String:
	var events = InputMap.action_get_events(action)
	var kb_text = ""
	var ctrl_text = ""
	
	for event in events:
		if event is InputEventKey:
			kb_text = event.as_text()
		elif event is InputEventJoypadButton:
			ctrl_text = get_button_name(event.button_index)
		elif event is InputEventJoypadMotion:
			var axis_name = get_axis_name(event.axis, event.axis_value)
			if axis_name != "":
				ctrl_text = axis_name
	
	if kb_text != "" and ctrl_text != "":
		return "%s / %s" % [kb_text, ctrl_text]
	elif kb_text != "":
		return kb_text
	elif ctrl_text != "":
		return ctrl_text
	return ""

func set_controller_type(type: int) -> void:
	current_controller_type = type

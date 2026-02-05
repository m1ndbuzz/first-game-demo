extends VBoxContainer

const FIRST_LEVEL = preload("res://scenes/levels/first_level.tscn")
@onready var start_btn: Button = $start_btn
@onready var options_btn: Button = $options_btn
@onready var quit_btn: Button = $quit_btn

func _ready() -> void:
	start_btn.grab_focus.call_deferred()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_HIDDEN:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif (event is InputEventKey or event is InputEventJoypadButton) and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_start_btn_pressed() -> void:
	get_tree().change_scene_to_packed(FIRST_LEVEL)


func _on_quit_btn_pressed() -> void:
	get_tree().quit()


func _on_start_btn_mouse_entered() -> void:
	start_btn.grab_focus()


func _on_options_btn_mouse_entered() -> void:
	options_btn.grab_focus()


func _on_quit_btn_mouse_entered() -> void:
	quit_btn.grab_focus()

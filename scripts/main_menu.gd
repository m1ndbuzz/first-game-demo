extends VBoxContainer

const FIRST_LEVEL = preload("res://scenes/levels/first_level.tscn")
const OPTIONS_MENU = preload("res://scenes/options_menu.tscn")
@onready var start_btn: Button = $start_btn
@onready var options_btn: Button = $options_btn
@onready var quit_btn: Button = $quit_btn

var options_menu: Control = null

func _ready() -> void:
	start_btn.grab_focus.call_deferred()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Create options menu instance (deferred to avoid parent busy error)
	call_deferred("_setup_options_menu")
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_HIDDEN:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif (event is InputEventKey or event is InputEventJoypadButton) and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_start_btn_pressed() -> void:
	get_tree().change_scene_to_packed(FIRST_LEVEL)


func _setup_options_menu() -> void:
	options_menu = OPTIONS_MENU.instantiate()
	options_menu.back_pressed.connect(_on_options_back_pressed)
	options_menu.hide()
	get_tree().root.add_child(options_menu)

func _on_quit_btn_pressed() -> void:
	get_tree().quit()


func _on_options_btn_pressed() -> void:
	options_menu.show_menu()
	self.hide()


func _on_options_back_pressed() -> void:
	options_menu.hide()
	self.show()
	options_btn.grab_focus.call_deferred()


func _on_start_btn_mouse_entered() -> void:
	start_btn.grab_focus()


func _on_options_btn_mouse_entered() -> void:
	options_btn.grab_focus()


func _on_quit_btn_mouse_entered() -> void:
	quit_btn.grab_focus()

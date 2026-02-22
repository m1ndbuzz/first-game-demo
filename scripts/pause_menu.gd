extends CenterContainer

const OPTIONS_MENU = preload("res://scenes/options_menu.tscn")
@onready var pause_menu: CenterContainer = $"."
@onready var resume: Button = $VBoxContainer/Resume
@onready var quitBtn: Button = $VBoxContainer/Quit
@onready var options_btn: Button = $VBoxContainer/Options

var options_menu: Control = null

func _ready() -> void:
	SignalManager.menu.connect(menu_action)
	
	# Create options menu instance (deferred to avoid parent busy error)
	call_deferred("_setup_options_menu")

func _setup_options_menu() -> void:
	options_menu = OPTIONS_MENU.instantiate()
	options_menu.back_pressed.connect(_on_options_back_pressed)
	options_menu.hide()
	get_tree().root.add_child(options_menu)
	
func _unhandled_input(event: InputEvent) -> void:
	# Toggle mouse capture with Escape
	if event.is_action_pressed("Menu"):
		SignalManager.emit_signal("menu")
		
		
func _input(event: InputEvent) -> void:
	if not get_tree().paused:
		return
	
	# Handle mouse visibility
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_HIDDEN:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif (event is InputEventKey or event is InputEventJoypadButton) and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Handle Escape or B button to resume
	if visible and not options_menu.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			unpause()
			get_viewport().set_input_as_handled()
		elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
			unpause()
			get_viewport().set_input_as_handled()
		
func menu_action():
	#print("GAME STATE: ", get_tree().paused)
	if get_tree().paused:
		unpause()
	else:
		pause()
		
func unpause():
	get_tree().paused = false
	pause_menu.visible = false
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	#print("unpaused")
	
func pause():
	get_tree().paused = true
	pause_menu.visible = true
	resume.grab_focus()
	#print("paused")
	


func _on_resume_pressed() -> void:
	unpause()


func _on_options_pressed() -> void:
	options_menu.show_menu()
	pause_menu.visible = false


func _on_options_back_pressed() -> void:
	options_menu.hide()
	pause_menu.visible = true
	options_btn.grab_focus.call_deferred()


func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_resume_mouse_entered() -> void:
	resume.grab_focus()


func _on_options_mouse_entered() -> void:
	options_btn.grab_focus()


func _on_quit_mouse_entered() -> void:
	quitBtn.grab_focus()

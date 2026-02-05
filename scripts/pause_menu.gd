extends CenterContainer

@onready var pause_menu: CenterContainer = $"."
@onready var resume: Button = $VBoxContainer/Resume
@onready var quitBtn: Button = $VBoxContainer/Quit
@onready var options: Button = $VBoxContainer/Options



func _ready() -> void:
	SignalManager.menu.connect(menu_action)
	
func _unhandled_input(event: InputEvent) -> void:
	# Toggle mouse capture with Escape
	if event.is_action_pressed("Menu"):
		SignalManager.emit_signal("menu")
		
		
func _input(event: InputEvent) -> void:
	if get_tree().paused:
		if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_HIDDEN:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif (event is InputEventKey or event is InputEventJoypadButton) and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		
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


func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_resume_mouse_entered() -> void:
	resume.grab_focus()


func _on_options_mouse_entered() -> void:
	options.grab_focus()


func _on_quit_mouse_entered() -> void:
	quitBtn.grab_focus()

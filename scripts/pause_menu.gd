extends CenterContainer

@onready var pause_menu: CenterContainer = $"."
@onready var resume: Button = $VBoxContainer/Resume
@onready var quitBtn: Button = $VBoxContainer/Quit


func _ready() -> void:
	SignalManager.menu.connect(menu_action)
	
func _unhandled_input(event: InputEvent) -> void:
	# Toggle mouse capture with Escape
	if event.is_action_pressed("Menu"):
		SignalManager.emit_signal("menu")
		
func menu_action():
	print("GAME STATE: ", get_tree().paused)
	if get_tree().paused:
		unpause()
	else:
		pause()
		
func unpause():
	get_tree().paused = false
	pause_menu.visible = false
	print("unpaused")
	
func pause():
	get_tree().paused = true
	pause_menu.visible = true
	resume.grab_focus()
	print("paused")
	


func _on_resume_pressed() -> void:
	unpause()


func _on_quit_pressed() -> void:
	get_tree().quit()

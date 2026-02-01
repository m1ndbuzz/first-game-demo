extends VBoxContainer

const FIRST_LEVEL = preload("res://levels/first_level.tscn")

func _on_start_btn_pressed() -> void:
	get_tree().change_scene_to_packed(FIRST_LEVEL)


func _on_quit_btn_pressed() -> void:
	get_tree().quit()

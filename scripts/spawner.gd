extends Node3D

var player = preload("res://scenes/knight.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Reset"):
		restart()

	

func restart():
	get_tree().reload_current_scene()
	

	

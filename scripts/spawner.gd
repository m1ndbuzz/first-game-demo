extends Node3D

var player_scene = preload("res://scenes/knight.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Reset"):
		restart()

func restart():
	var player = get_child(0)
	player.free()
	var new_player = player_scene.instantiate()
	new_player.position = Vector3(-9.5,0,35)
	add_child(new_player)
	print("Signal emited")
	SignalManager.restart.emit()

	

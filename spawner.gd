extends Node3D

var player = preload("res://scenes/knight.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Reset"):
		destroy()
		spawn()

func destroy():
	if self.get_child_count() > 0:
		self.get_child(0).queue_free()

func spawn():
	var playerInstance = player.instantiate()
	playerInstance.position = Vector3(-9.5,0.0, 35.0)
	self.add_child(playerInstance)
	

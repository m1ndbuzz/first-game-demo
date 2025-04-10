extends Node3D

func _on_exit_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		var player = $"../../Spawner/Knight"
		player.finished = true
		player.can_move = false

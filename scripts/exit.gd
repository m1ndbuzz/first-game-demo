extends Node3D

var score

func _on_exit_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		var player = $"../../Spawner/Knight"
		var main = $"../.."
		player.finished = true
		player.can_move = false
		print("SCORE str: ", main.time_string)
		print("SCORE el_time: ", main.time_elapsed)
		score = main.time_string
		print("Adding score: ", score)
		Score.add_score(score)

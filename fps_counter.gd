extends CanvasLayer

func _process(_delta: float) -> void:
	$FPS_counter.text = str(Engine.get_frames_per_second())

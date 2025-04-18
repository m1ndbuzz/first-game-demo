extends Node3D
# Variable to track time
var time_elapsed = 0.0
# Reference to the Label node
var timer_label
var player
@export var time_string = ""

func _ready() -> void:
	SignalManager.restart.connect(_restart)
	player = $Spawner/Knight
	timer_label = $CanvasLayer/UI/TimeLabel

func _process(delta):
	
	if player and not player.finished and player.started:
		# Update time
		time_elapsed += delta
		
		# Format the time (minutes:seconds.milliseconds)
		var minutes = int(time_elapsed / 60)
		var seconds = int(time_elapsed) % 60
		# Corrected milliseconds calculation
		var milliseconds = int(fmod(time_elapsed * 1000, 1000))
		time_string = "%02d:%02d.%03d" % [minutes, seconds, milliseconds]
		
		# Update the Label text
		if timer_label:
			timer_label.text = time_string

func _restart():
	time_elapsed = 0.0
	player = $Spawner/Knight
	timer_label.text = "GO!"
	

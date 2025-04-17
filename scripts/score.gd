extends Node

const SAVE_PATH = "res://data/scores.json"
const MAX_SCORES = 10
const LABEL_PATH = "CanvasLayer/UI/ScoresLabel"

var label_ref: Label = null
var scores: Array = []


func _ready():
	# Defer node access until the scene tree is ready
	call_deferred("load_scores")
	SignalManager.restart.connect(_on_scene_reloaded)
	
func add_score(score):
	print("Adding score to the list")
	print(score)
	scores.append(score)
	print("Score list:\n", scores)
	scores.sort_custom(func(a, b): return a < b) # Asending
	if scores.size() > MAX_SCORES:
		scores.resize(MAX_SCORES)
	save_scores()
		

func save_scores():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var scores_json = JSON.stringify(scores)
		print("Saving scores:\n:", scores_json)
		file.store_string(scores_json)
		file.close()
		
func load_scores():
	if not FileAccess.file_exists(SAVE_PATH):
		print("No file to load scores")
		scores = []
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		scores = JSON.parse_string(content) if content != "" else []
		scores.sort_custom(func(a, b): return a < b) # Asending
		print("Loaded scores: \n", scores)
		file.close()
	var score_text = ""
	var counter = 1
	for s in scores:
		score_text+= str(counter) + ". " + s + "\n"
		counter+=1
	if label_ref and is_instance_valid(label_ref):
		label_ref.text = score_text
	else:
		print("Label reference is invalid, refreshing...")
		refresh_label_reference()
		if label_ref:
			label_ref.text = score_text
		
func _on_scene_reloaded():
	print("Signal received")
	load_scores()
	
func refresh_label_reference():
	var root = get_tree().current_scene
	if root:
		# Replace "Path/To/Your/Label" with the actual node path
		label_ref = root.get_node_or_null(LABEL_PATH)
		if label_ref:
			print("Label reference obtained: ", label_ref.name)
		else:
			print("Label not found!")
	else:
		print("No current scene!")
	

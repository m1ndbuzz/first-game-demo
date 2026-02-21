extends VBoxContainer


func _on_back_pressed() -> void:
	SignalManager.emit_signal("options_back")

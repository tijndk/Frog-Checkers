extends Control

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) # laat standaard cursor niet zien

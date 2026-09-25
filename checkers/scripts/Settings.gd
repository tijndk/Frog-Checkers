extends Control

const MAIN = preload("res://scenes/Main.tscn")

@onready var board_size_option: OptionButton = $TileMapLayer/VBoxContainer/BoardSizeOption

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_play_button_pressed():
	var selected_text = board_size_option.get_item_text(
		board_size_option.selected
	)
	
	var new_size = int(selected_text.split(" ")[0])

	GameSettings.board_size = new_size
	
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

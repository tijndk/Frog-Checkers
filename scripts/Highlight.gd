extends Node2D

@export var grid: Resource = preload("res://Grid.tres")

var tile: Vector2

func set_tile(value: Vector2) -> void:
	tile = grid.clamp_to_playable_area(value)
	position = grid.calculate_map_position(tile)

# vierkantje tekenen over een vakje, wordt gebruikt om mogelijke zetten te laten zien
func _draw() -> void:
	draw_rect(
		Rect2(-grid.tile_size / 2, grid.tile_size),
		Color(1, 1, 0, 0.4)
	)

func _ready() -> void:
	# om het highlight vakje fade in/fade out te geven
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "modulate:a", 0.2, 0.8)
	tween.tween_property(self, "modulate:a", 1.0, 0.8)

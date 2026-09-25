extends Node2D

@export var grid: Resource = preload("res://Grid.tres")

var tile: Vector2
var border_only := false

func set_tile(value: Vector2) -> void:
	tile = grid.clamp_to_playable_area(value)
	position = grid.calculate_map_position(tile)

func set_border_only(value: bool) -> void:
	border_only = value
	queue_redraw()

# vierkantje tekenen over een vakje, wordt gebruikt om mogelijke zetten te laten zien
func _draw() -> void:
	var rect := Rect2(-grid.tile_size / 2, grid.tile_size)
	
	if border_only:
		draw_rect(rect, Color(1.0, 1.0, 0.0, 0.6), false, 2.0)
	else:
		draw_rect(rect, Color(1.0, 0.0, 0.0, 0.5))

func _ready() -> void:
	# om het highlight vakje fade in/fade out te geven
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "modulate:a", 0.2, 0.8)
	tween.tween_property(self, "modulate:a", 1.0, 0.8)

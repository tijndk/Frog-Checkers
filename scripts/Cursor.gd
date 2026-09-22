@tool
class_name Cursor
extends Node2D

# signaal dat er op een vakje geklikt is
signal accept_pressed(tile)
# signaal dat er een schijf verplaatst is
signal moved(new_tile)

@export var grid: Resource = preload("res://Grid.tres")
@export var ui_cooldown := 0.1

var _tile: Vector2 = Vector2.ZERO
var tile: Vector2:
	set(value):
		_tile = grid.clamp_to_playable_area(value)
	get:
		return _tile

@onready var _timer: Timer = $Timer

func _ready() -> void:
	_timer.wait_time = ui_cooldown
	position = grid.calculate_map_position(tile)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var board = get_parent()
		var board_position = board.to_local(event.position)
		
		set_tile(grid.calculate_grid_coordinates(board_position))
	elif event.is_action_pressed("click") or \
	event.is_action_pressed("ui_accept"):
		emit_signal("accept_pressed", tile)
		get_viewport().set_input_as_handled()
	
	var should_move := event.is_pressed()
	if event.is_echo():
		should_move = should_move and _timer.is_stopped()
	
	if not should_move:
		return
	
	if event.is_action("ui_right"):
		self.tile += Vector2.RIGHT
	elif event.is_action("ui_up"):
		self.tile += Vector2.UP
	elif event.is_action("ui_left"):
		self.tile += Vector2.LEFT
	elif event.is_action("ui_down"):
		self.tile += Vector2.DOWN

# om een vierkantje te tekenen om de tile waar je muis op staat
func _draw() -> void:
	draw_rect(Rect2(-grid.tile_size / 2, grid.tile_size), Color.ALICE_BLUE, false, 2.0)

# functie die de huidige positie van de cursor bepaalt
func set_tile(value: Vector2) -> void:
	var new_tile: Vector2 = grid.clamp_to_playable_area(value)
	if new_tile.is_equal_approx(tile):
		return
	
	tile = new_tile
	position = grid.calculate_map_position(tile)
	emit_signal("moved", tile)
	_timer.start()

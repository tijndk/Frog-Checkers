class_name Unit
extends Path2D

signal walk_finished

@export var grid: Resource = preload("res://Grid.tres")
# aantal vakjes dat een schijf kan lopen
@export var move_range := 1
# hoe snel een schijf over het bord beweegt
@export var move_speed := 2.0

@onready var _anim_player: AnimationPlayer = $AnimationPlayer
@onready var _path_follow: PathFollow2D = $PathFollow2D

@onready var _dark_sprite: Sprite2D = $PathFollow2D/DarkSprite
@onready var _light_sprite: Sprite2D = $PathFollow2D/LightSprite
@onready var _crown: Sprite2D = $PathFollow2D/Crown

var player = 1
var is_king = false

# coordinaten van op welk vakje de schijf staat
var _tile: Vector2 = Vector2.ZERO
var tile: Vector2:
	set(value):
		_tile = grid.clamp_to_playable_area(value)
	get:
		return _tile

# toggled de "selected" animatie op de schijf
var _selected_value: bool = false

var is_selected: bool:
	set(value):
		_selected_value = value
		
		if not is_node_ready():
			return
		
		if value:
			_anim_player.play("selected")
		else:
			_anim_player.play("idle")
	get:
		return _selected_value

var _walking_value: bool = false

var _is_walking: bool:
	set(value):
		_walking_value = value
		set_process(value)
	get:
		return _walking_value

func _ready() -> void:
	set_process(false)
	_crown.visible = false
	
	self.tile = grid.calculate_grid_coordinates(position)
	position = grid.calculate_map_position(tile)
	
	if not Engine.is_editor_hint():
		curve = Curve2D.new()

func _process(delta: float) -> void:
	_path_follow.progress += move_speed * delta
	
	if _path_follow.progress_ratio >= 1.0:
		self._is_walking = false
		_path_follow.progress = 0.0
		position = grid.calculate_map_position(tile)
		curve.clear_points()
		emit_signal("walk_finished")

func walk_along(path: PackedVector2Array) -> void:
	if path.is_empty():
		return

	curve.add_point(Vector2.ZERO)
	for point in path:
		curve.add_point(grid.calculate_map_position(point) - position)
	tile = path[-1]
	self._is_walking = true

func set_tile(value: Vector2) -> void:
	tile = grid.clamp_to_playable_area(value)
	position = grid.calculate_map_position(tile)

func set_is_selected(value: bool) -> void:
	is_selected = value
	if is_selected:
		_anim_player.play("selected")
	else:
		_anim_player.play("idle")

func _set_is_walking(value: bool) -> void:
	_is_walking = value
	set_process(_is_walking)

# functie om verschillende sprites te hebben
func set_player(value: int) -> void:
	player = value
	
	if player == 1:
		_dark_sprite.visible = true
		_light_sprite.visible = false
	else:
		_dark_sprite.visible = false
		_light_sprite.visible = true
	
func set_king(value: bool) -> void:
	is_king = value
	_crown.visible = value

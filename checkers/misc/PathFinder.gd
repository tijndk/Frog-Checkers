class_name PathFinder
extends RefCounted

const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

var _grid: Resource
var _astar := AStar2D.new()

func _init(grid: Grid, walkable_tiles: Array) -> void:
	_grid = grid
	var tile_mappings := {}
	for tile in walkable_tiles:
		tile_mappings[tile] = _grid.as_index(tile)
	_add_and_connect_points(tile_mappings)

func calculate_point_path(start: Vector2, end: Vector2) -> PackedVector2Array:
	var start_index: int = _grid.as_index(start)
	var end_index: int = _grid.as_index(end)
	if _astar.has_point(start_index) and _astar.has_point(end_index):
		return _astar.get_point_path(start_index, end_index)
	else:
		return PackedVector2Array()

func _add_and_connect_points(tile_mappings: Dictionary) -> void:
	for point in tile_mappings:
		_astar.add_point(tile_mappings[point], point)
	
	for point in tile_mappings:
		for neighbor_index in _find_neighbor_indices(point, tile_mappings):
			_astar.connect_points(tile_mappings[point], neighbor_index)

func _find_neighbor_indices(tile: Vector2, tile_mappings: Dictionary) -> Array:
	var out := []
	for direction in DIRECTIONS:
		var neighbor: Vector2 = tile + direction
		if not tile_mappings.has(neighbor):
			continue
		if not _astar.are_points_connected(tile_mappings[tile], tile_mappings[neighbor]):
			out.push_back(tile_mappings[neighbor])
	return out

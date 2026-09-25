extends TileMapLayer

@export var grid: Resource = preload("res://Grid.tres")

func setup_map() -> void:
	randomize()
	clear()
	
	for y in range(int(grid.size.y)):
		for x in range(int(grid.size.x)):
			var tile = Vector2(x, y)
			
			if grid.is_within_playable_area(tile):
				# "zwarte" tegels
				if is_dark_tile(tile):
					set_cell(Vector2i(x, y), 1, Vector2i(2, 1), 0)
				# "witte" tegels
				else:
					set_cell(Vector2i(x, y), 1, Vector2i(2, 0), 0)
			else:
				# de gras tegels
				var grass_tile = randi_range(0, 1) # om willekeurig een van de twee grasblokjes te gebruiken
				set_cell(Vector2i(x, y), 1, Vector2i(grass_tile, 1), 0)

func is_dark_tile(tile: Vector2) -> bool:
	var sum = int(tile.x + tile.y)
	return sum % 2 == 1

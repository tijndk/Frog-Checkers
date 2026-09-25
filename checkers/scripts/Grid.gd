class_name Grid
extends Resource

@export var board_size: int = 100
@export var border_size: int = 8

# grootte van het speelbare veld
@export var playable_size: Vector2:
	get:
		return Vector2(board_size, board_size)


# grootte van heel het veld/gebied
@export var size: Vector2:
	get:
		return Vector2(
			board_size + border_size * 2,
			board_size + border_size * 2
		)

# grootte van de vakjes in pixels
@export var tile_size: Vector2 = Vector2(16, 16)

# de helft van een tile om het midden van een vakje te berekenen.
# wordt gebruikt om de schijven in het midden te plaatsen
var _half_tile_size: Vector2:
	get:
		return tile_size / 2

# returnt de positie van het midden van een vakje in pixels.
# wordt gebruikt om schijven te plaatsen en ze over het bord te laten bewegen.
func calculate_map_position(grid_position: Vector2) -> Vector2:
	return grid_position * tile_size + _half_tile_size

# returnt de coördinaten van het vakje op het raster op basis van een positie op de kaart.
# wordt gebruikt om te bepalen op welke gridcoördinaten de schijven zijn geplaatst en 
# roepen daarna `calculate_map_position()` aan om ze naar het midden van de cel te verplaatsen.
func calculate_grid_coordinates(map_position: Vector2) -> Vector2:
	return (map_position / tile_size).floor()

# returnt true als de `tile_coordinates` binnen de grid zitten.
# zorgt ervoor dat de cursor en schijven niet over de map limiet kunnen
func is_within_bounds(tile_coordinates: Vector2) -> bool:
	var out := tile_coordinates.x >= 0 and tile_coordinates.x < size.x
	return out and tile_coordinates.y >= 0 and tile_coordinates.y < size.y

func is_within_playable_area(tile_coordinates: Vector2) -> bool:
	var max_x := border_size + playable_size.x - 1
	var max_y := border_size + playable_size.y - 1
	
	var out := tile_coordinates.x >= border_size and tile_coordinates.x <= max_x
	return out and tile_coordinates.y >= border_size and tile_coordinates.y <= max_y

# laat de `grid_position` passen binnen de grenzen van de grid.
func clamp(grid_position: Vector2) -> Vector2:
	var out := grid_position
	
	out.x = clamp(out.x, 0, size.x - 1.0)
	out.y = clamp(out.y, 0, size.y - 1.0)
	
	return out

func clamp_to_playable_area(grid_position: Vector2) -> Vector2:
	var out := grid_position
	
	out.x = clamp(out.x, border_size, border_size + playable_size.x - 1)
	out.y = clamp(out.y, border_size, border_size + playable_size.y - 1)
	
	return out

# kan dit gebruiken om 2d coördinaten om te zetten naar indexen van een array
func as_index(tile: Vector2) -> int:
	return int(tile.x + size.x * tile.y)

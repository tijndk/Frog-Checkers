extends Node2D

const UNIT = preload("res://scenes/Unit.tscn")
const HIGHLIGHT = preload("res://scenes/Highlight.tscn")

@export var grid: Resource = preload("res://Grid.tres")

@onready var board = $Board
@onready var map = $Board/Map

var visual_units = [] # de visuele schijven als sprites
var data_pieces = [] # de schijven als data/code
var possible_moves = [] # mogelijke zetten
var highlights = [] # highlights van mogelijke zetten

var selected_piece = Vector2.ZERO # geselecteerde schijf
var current_player = 1

# diagonale richtingen
const PLAYER_1_DIRECTIONS = [
	Vector2.LEFT + Vector2.DOWN,
	Vector2.RIGHT + Vector2.DOWN
]

const PLAYER_2_DIRECTIONS = [
	Vector2.LEFT + Vector2.UP,
	Vector2.RIGHT + Vector2.UP
]

# om de grootte van het bord te veranderen in settings
func change_board_size(new_size: int):
	grid.board_size = new_size

# functie om de mogelijke zetten te zoeken
func get_possible_moves() -> Array:
	possible_moves.clear() # leeg de `possible_moves` array zodat je alleen zetten per schijf krijgt te zien

	var selected_piece_data = get_piece_at_position(selected_piece)
	
	if selected_piece_data.is_empty():
		print("Geen schijf gevonden op: ", selected_piece)
		return possible_moves
		
	var selected_player = selected_piece_data["player"]
	
	var directions
	
	if selected_player == 1:
		directions = PLAYER_1_DIRECTIONS
	else:
		directions = PLAYER_2_DIRECTIONS
	
	for direction in directions:
		var new_position = selected_piece + direction # nieuwe positie is de positie van de geselecteerde schijf + een richting
		var piece = get_piece_at_position(new_position)
		
		# er staat geen schijf naast
		if piece.is_empty():
			if grid.is_within_playable_area(new_position):
				possible_moves.append({
					"position": new_position,
					"captured_piece": null
				})
		
		# er staat wel een schijf naast
		else:
			# eigen schijf
			if piece["player"] == selected_player:
				print("Eigen schijf gevonden!")
			# tegenstander
			else:
				print("Tegenstander gevonden!")
				
				var jump_position = new_position + direction
				
				if grid.is_within_playable_area(jump_position) and \
				get_piece_at_position(jump_position).is_empty():
					print("Geldige slagpositie!")
					
					possible_moves.append({
						"position": jump_position,
						"captured_piece": piece
					})
		
	return possible_moves

func get_piece_at_position(tile_position: Vector2) -> Dictionary:
	for piece in data_pieces:
		if piece["position"] == tile_position:
			return piece
	
	return {}

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) # laat standaard cursor niet zien
	
	grid.board_size = GameSettings.board_size
	
	map.setup_map()
	setup_board()
	
	var starting_rows = int(grid.playable_size.y / 2 - 1)
	var player_2_start = int(grid.playable_size.y - starting_rows)

	# speler 1
	for y in range(starting_rows):
		for x in range(int(grid.playable_size.x)):
			var tile = Vector2(x, y)
			
			if map.is_dark_tile(tile):
				var board_tile = tile + Vector2(grid.border_size, grid.border_size)
				
				data_pieces.append({
					"position": board_tile,
					"player": 1
				})
	
	# speler 2
	for y in range(player_2_start, int(grid.playable_size.y)):
		for x in range(int(grid.playable_size.x)):
			var tile = Vector2(x, y)
			
			if map.is_dark_tile(tile):
				var board_tile = tile + Vector2(grid.border_size, grid.border_size)
				
				data_pieces.append({
					"position": board_tile,
					"player": 2
				})
		
	# maakt alle zichtbare schijven (Units) aan en zet ze op de juiste plek op het bord
	for piece in data_pieces:
		var visual_unit = UNIT.instantiate()
		board.add_child(visual_unit)
		
		visual_unit.set_player(piece["player"])
		visual_unit.set_tile(piece["position"])
		
		visual_units.append(visual_unit)

# wat er gebeurt wanneer een vakje geselecteerd wordt
func _on_cursor_accept_pressed(tile):
	var clicked_piece = get_piece_at_position(tile)
	
	if not clicked_piece.is_empty():
		if clicked_piece["player"] == current_player:
			# highlights leegmaken zodat je alleen de mogelijke zetten per schijf ziet
			for highlight in highlights:
				highlight.queue_free()
				
			highlights.clear()
			
			selected_piece = tile # selecteer de schijf
			possible_moves = get_possible_moves()
			
			# laat de highlights zien voor de mogelijke zetten voor de geselecteerde schijf
			for possible_move in possible_moves:
				var highlight = HIGHLIGHT.instantiate()
				board.add_child(highlight)
				highlight.set_tile(possible_move["position"])
				highlights.append(highlight)
		else:
			print("Dit is niet jouw schijf.")
	else:
		var selected_move = null
		
		for move in possible_moves:
			if move["position"] == tile:
				selected_move = move
				break
			
		if selected_move != null:
			print("Geldige zet!")
			
			var captured_piece = selected_move["captured_piece"]
			
			if captured_piece != null:
				data_pieces.erase(captured_piece)
				
				for visual_unit in visual_units:
					if visual_unit.tile == captured_piece["position"]:
						print("Geslagen unit gevonden!")
						visual_unit.queue_free() # verwijderd de zichtbare "geslagen" unit/schijf node uit de scene tree
						visual_units.erase(visual_unit) # verwijderd de unit uit de array
						break
			
			for visual_unit in visual_units:
				if visual_unit.tile == selected_piece:
					print("Dit is de juiste unit!")
					visual_unit.set_tile(tile)
					
			# highlights leegmaken zodat je alleen de mogelijke zetten per schijf ziet
			for highlight in highlights:
				highlight.queue_free()
			
			highlights.clear()
			
			for piece in data_pieces:
				if piece["position"] == selected_piece:
					piece["position"] = tile
			
			# selected_piece = tile
			possible_moves.clear()
			
			if current_player == 1:
				current_player = 2
			else:
				current_player = 1
		else:
			print("Geen geldige zet.")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.

func setup_board() -> void:
	var board_pixel_size = grid.size * grid.tile_size
	var viewport_size = get_viewport_rect().size
	
	board.scale = Vector2.ONE
	
	board.position = (viewport_size - board_pixel_size) / 2.0

#func _notification(what):
	#if what == NOTIFICATION_WM_SIZE_CHANGED:
		#setup_board()

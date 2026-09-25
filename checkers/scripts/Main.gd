extends Node2D

const UNIT = preload("res://scenes/Unit.tscn")
const HIGHLIGHT = preload("res://scenes/Highlight.tscn")

@export var grid: Resource = preload("res://Grid.tres")

@onready var board = $Board
@onready var map = $Board/Map
@onready var turn_label: Label = $TurnLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var winner_label: Label = $GameOverPanel/WinnerLabel

var visual_units = [] # de visuele schijven als sprites
var data_pieces = [] # de schijven als data/code
var possible_moves = [] # mogelijke zetten
var highlights = [] # highlights van mogelijke zetten
var mandatory_highlights = []

var selected_piece = Vector2.ZERO # geselecteerde schijf
var current_player = 1
var forced_capture := false
var game_over := false

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
		return possible_moves
		
	var selected_player = selected_piece_data["player"]
	var directions

	if selected_piece_data["is_king"]:
		directions = PLAYER_1_DIRECTIONS + PLAYER_2_DIRECTIONS
	elif selected_player == 1:
		directions = PLAYER_1_DIRECTIONS
	else:
		directions = PLAYER_2_DIRECTIONS
	
	var capture_moves:= []
	var normal_moves := []
	
	for direction in directions:
		var adjacent_position = selected_piece + direction # naaste positie is de positie van de geselecteerde schijf + een richting
		var adjacent_piece = get_piece_at_position(adjacent_position)
		
		# er staat geen schijf naast
		if adjacent_piece.is_empty():
			# normale zet van 1 vakje
			if grid.is_within_playable_area(adjacent_position):
				normal_moves.append({
					"position": adjacent_position,
					"captured_piece": null
				})
		
			# koning kan ook 2 vakjes springen
			if selected_piece_data["is_king"]:
				var two_step_position = selected_piece + direction * 2

				if grid.is_within_playable_area(two_step_position) and \
				get_piece_at_position(two_step_position).is_empty():
					normal_moves.append({
						"position": two_step_position,
						"captured_piece": null
					})
		
		# er staat wel een schijf naast
		elif adjacent_piece["player"] != selected_player:
			var jump_position = selected_piece + direction * 2
			
			if grid.is_within_playable_area(jump_position) and \
			get_piece_at_position(jump_position).is_empty():
				capture_moves.append({
					"position": jump_position,
					"captured_piece": adjacent_piece
				})
		
	if capture_moves.size() > 0:
		possible_moves = capture_moves
	else:
		possible_moves = normal_moves
	
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
	update_turn_label()
	
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
					"player": 1,
					"is_king": false
				})
	
	# speler 2
	for y in range(player_2_start, int(grid.playable_size.y)):
		for x in range(int(grid.playable_size.x)):
			var tile = Vector2(x, y)
			
			if map.is_dark_tile(tile):
				var board_tile = tile + Vector2(grid.border_size, grid.border_size)
				
				data_pieces.append({
					"position": board_tile,
					"player": 2,
					"is_king": false
				})
		
	# maakt alle zichtbare schijven (Units) aan en zet ze op de juiste plek op het bord
	for piece in data_pieces:
		var visual_unit = UNIT.instantiate()
		board.add_child(visual_unit)
		
		visual_unit.set_player(piece["player"])
		visual_unit.set_tile(piece["position"])
		visual_unit.set_king((piece["is_king"]))
		
		visual_units.append(visual_unit)
	
	show_mandatory_capture_highlights()

# wat er gebeurt wanneer een vakje geselecteerd wordt
func _on_cursor_accept_pressed(tile):
	if game_over:
		return
		
	var clicked_piece = get_piece_at_position(tile)
	
	if not clicked_piece.is_empty():
		if clicked_piece["player"] == current_player:
			if forced_capture and tile != selected_piece:
				print("Je moet verder slaan met dezelfde schijf.")
				return
			
			var has_capture = player_has_capture(current_player)
			
			selected_piece = tile # selecteer de schijf
			possible_moves = get_possible_moves()
			
			if has_capture:
				var selected_piece_can_capture := false
				
				for move in possible_moves:
					if move["captured_piece"] != null:
						selected_piece_can_capture = true
						break
				
				if not selected_piece_can_capture:
					possible_moves.clear()
					return
			
			for highlight in mandatory_highlights:
				highlight.queue_free()
			
			mandatory_highlights.clear()
			
			show_possible_moves()
			
			# laat de highlights zien voor de mogelijke zetten voor de geselecteerde schijf
	else:
		var selected_move = null
		
		for move in possible_moves:
			if move["position"] == tile:
				selected_move = move
				break
			
		if selected_move != null:
			var captured_piece = selected_move["captured_piece"]
			
			if captured_piece != null:
				data_pieces.erase(captured_piece)
				
				for visual_unit in visual_units:
					if visual_unit.tile == captured_piece["position"]:
						visual_unit.queue_free() # verwijderd de zichtbare "geslagen" unit/schijf node uit de scene tree
						visual_units.erase(visual_unit) # verwijderd de unit uit de array
						break
			
			for visual_unit in visual_units:
				if visual_unit.tile == selected_piece:
					visual_unit.set_tile(tile)
					
			# highlights leegmaken zodat je alleen de mogelijke zetten per schijf ziet
			for highlight in highlights:
				highlight.queue_free()
			
			highlights.clear()
			
			for piece in data_pieces:
				if piece["position"] == selected_piece:
					piece["position"] = tile

					var last_row_player_1 = grid.border_size + grid.playable_size.y - 1
					var last_row_player_2 = grid.border_size

					if piece["player"] == 1 and tile.y == last_row_player_1:
						piece["is_king"] = true
						for visual_unit in visual_units:
							if visual_unit.tile == tile:
								visual_unit.set_king(true)
								break
								
					elif piece["player"] == 2 and tile.y == last_row_player_2:
						piece["is_king"] = true
						for visual_unit in visual_units:
							if visual_unit.tile == tile:
								visual_unit.set_king(true)
								break
			
			selected_piece = tile
			possible_moves.clear()
			
			if captured_piece != null:
				possible_moves = get_possible_moves()
				
				var has_follow_up_capture := false
				
				for move in possible_moves:
					if move["captured_piece"] != null:
						has_follow_up_capture = true
						break
				
				if has_follow_up_capture:
					forced_capture = true
					show_possible_moves()
					return
			
			forced_capture = false
			possible_moves.clear()
			
			if current_player == 1:
				current_player = 2
			else:
				current_player = 1
			
			if check_game_over():
				return
				
			update_turn_label()
			show_mandatory_capture_highlights()

func setup_board() -> void:
	var board_pixel_size = grid.size * grid.tile_size
	var viewport_size = get_viewport_rect().size
	
	board.scale = Vector2.ONE
	
	board.position = (viewport_size - board_pixel_size) / 2.0

func update_turn_label() -> void:
	if current_player == 1:
		turn_label.text = "Turn: Dark"
	else:
		turn_label.text = "Turn: Light"

# highlights leegmaken zodat je alleen de mogelijke zetten per schijf ziet
func show_possible_moves() -> void:
	for highlight in highlights:
		highlight.queue_free()
		
	highlights.clear()
	
	for possible_move in possible_moves:
		var highlight = HIGHLIGHT.instantiate()
		board.add_child(highlight)
		highlight.set_tile(possible_move["position"])
		highlights.append(highlight)

func player_has_capture(player: int) -> bool:
	var old_selected_piece = selected_piece
	var old_possible_moves = possible_moves.duplicate()
	
	for piece in data_pieces:
		if piece["player"] != player:
			continue
			
		selected_piece = piece["position"]
		var moves = get_possible_moves().duplicate()
		
		for move in moves:
			if move["captured_piece"] != null:
				selected_piece = old_selected_piece
				possible_moves = old_possible_moves
				return true
	
	selected_piece = old_selected_piece
	possible_moves = old_possible_moves
	return false

func show_mandatory_capture_highlights() -> void:
	for highlight in mandatory_highlights:
		highlight.queue_free()
	
	mandatory_highlights.clear()
	
	if forced_capture:
		return
	
	var old_selected_piece = selected_piece
	var old_possible_moves = possible_moves.duplicate()
	
	for piece in data_pieces:
		if piece["player"] != current_player:
			continue
			
		selected_piece = piece["position"]
		var moves = get_possible_moves().duplicate()
		
		for move in moves:
			if move["captured_piece"] != null:
				var highlight = HIGHLIGHT.instantiate()
				board.add_child(highlight)
				highlight.set_tile(piece["position"])
				highlight.set_border_only(true)
				mandatory_highlights.append(highlight)
				break
	
	selected_piece = old_selected_piece
	possible_moves = old_possible_moves

func player_has_legal_move(player: int) -> bool:
	var old_selected_piece = selected_piece
	var old_possible_moves = possible_moves.duplicate()

	for piece in data_pieces:
		if piece["player"] != player:
			continue

		selected_piece = piece["position"]

		if not get_possible_moves().is_empty():
			selected_piece = old_selected_piece
			possible_moves = old_possible_moves
			return true

	selected_piece = old_selected_piece
	possible_moves = old_possible_moves
	return false

func check_game_over() -> bool:
	if player_has_legal_move(current_player):
		return false
		
	var winning_player = 2 if current_player == 1 else 1
	
	if winning_player == 1:
		winner_label.text = "Donker heeft gewonnen!"
	else:
		winner_label.text = "Licht heeft gewonnen!"
	
	game_over_panel.show()
	game_over = true
	return true

func _on_restart_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/TitleScreen.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.

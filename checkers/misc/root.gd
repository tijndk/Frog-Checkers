extends Node2D

var current_player = 1 # 1 = zwart, 2 = wit

func switch_turn():
	if current_player == 1:
		current_player = 2
	else:
		current_player = 1

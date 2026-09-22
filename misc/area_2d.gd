extends Area2D

# variabelen
var tile_size = 16 # grootte van de dambord vakjes
var target: Vector2
var speed = 200.0

@onready var raycast = $RayCast2D

func _ready():
	position = position.snapped(Vector2.ZERO * tile_size)
	position += Vector2.ZERO * tile_size/2
	target = position

func _unhandled_input(event):
	if event.is_action_pressed(&"click"):
		var mouse_pos = get_global_mouse_position()

		# bepaalt op welk vakje de muis staat
		var grid_pos = mouse_pos.snapped(Vector2.ONE * tile_size)
		grid_pos += Vector2.ONE * tile_size / 2

		var difference = grid_pos - position

		# hierdoor kun je alleen diagonaal bewegen
		var x_direction = sign(difference.x)
		var y_direction = sign(difference.y)

		# alleen bewegen wanneer je diagonaal van de schijf klikt
		if x_direction != 0 and y_direction != 0:

			var direction = Vector2(x_direction, y_direction)

			# controleert of er iets in de weg zit (zodat de schijven niet van het bord kunnen)
			raycast.target_position = direction * tile_size
			raycast.force_raycast_update()

			if not raycast.is_colliding():
				target = position + direction * tile_size

func _physics_process(delta):
	# om te kunnen bewegen
	if position.distance_to(target) > 1:
		position = position.move_toward(target, speed * delta)
	else:
		position = target

extends CharacterBody2D

class_name Pacman

var next_movement_direction = Vector2.ZERO
var movement_direction = Vector2.ZERO
var shape_query = PhysicsShapeQueryParameters2D.new()

@export var speed = 300

@onready var direction_pointer = $DirectionPointer
@onready var collision_shape_2d = $CollisionShape2D
@onready var _animated_sprite = $AnimatedSprite2D
@onready var pellets: TileMapLayer = $"../Pellets"

var score: int = 0
@onready var scoreUI: Label = $"../1UP"

func _ready():
	shape_query.shape = collision_shape_2d.shape
	shape_query.collision_mask = 2

func _physics_process(delta):
	get_input()

	if movement_direction == Vector2.ZERO:
		movement_direction = next_movement_direction
	if can_move_in_direction(next_movement_direction, delta):
		movement_direction = next_movement_direction

	velocity = movement_direction * speed

	if movement_direction == Vector2.ZERO or not can_move_in_direction(movement_direction, delta):
		_animated_sprite.play("stop")
	else:
		_animated_sprite.play("moving")

	move_and_slide()
	check_pellet()

func get_input():
	if Input.is_action_pressed("ui_left"):
		next_movement_direction = Vector2.LEFT
		rotation_degrees = 0
	if Input.is_action_pressed("ui_right"):
		next_movement_direction = Vector2.RIGHT
		rotation_degrees = 180
	if Input.is_action_pressed("ui_down"):
		next_movement_direction = Vector2.DOWN
		rotation_degrees = 270
	if Input.is_action_pressed("ui_up"):
		next_movement_direction = Vector2.UP
		rotation_degrees = 90

func can_move_in_direction(dir: Vector2, delta: float) -> bool:
	shape_query.transform = global_transform.translated(dir * speed * delta * 2)
	var result = get_world_2d().direct_space_state.intersect_shape(shape_query)
	return result.size() == 0

func update_score(value: int) -> void:
	score += value
	if score > 999999:
		score = 999999
	scoreUI.text = str(score).pad_zeros(2)

func check_pellet() -> void:
	var cell: Vector2i = pellets.local_to_map(global_position)

	if pellets.get_cell_source_id(cell) == -1:
		return

	var data := pellets.get_cell_tile_data(cell)
	if data == null:
		return

	var pellet_type : String = data.get_custom_data("pellet_type")

	match pellet_type:
		"small":
			update_score(10)
		"big":
			update_score(50)

	pellets.erase_cell(cell)

	if pellets.get_used_cells().is_empty():
		print("All cells collected")

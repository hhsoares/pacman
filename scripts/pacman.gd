extends CharacterBody2D

class_name Pacman

var next_movement_direction = Vector2.ZERO
var movement_direction = Vector2.ZERO
var shape_query = PhysicsShapeQueryParameters2D.new()

@export var speed = 300

@onready var direction_pointer = $DirectionPointer
@onready var collision_shape_2d = $CollisionShape2D

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
	move_and_slide()

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

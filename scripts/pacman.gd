extends CharacterBody2D

class_name Pacman

@export var speed = 300
var movement_direction = Vector2.ZERO

func _physics_process(delta):
	get_input()
	
	velocity = movement_direction * speed
	move_and_slide()

func get_input():
	if Input.is_action_pressed("ui_left"):
		movement_direction = Vector2.LEFT
		rotation_degrees = 0
	if Input.is_action_pressed("ui_right"):
		movement_direction = Vector2.RIGHT
		rotation_degrees = 180
	if Input.is_action_pressed("ui_down"):
		movement_direction = Vector2.DOWN
		rotation_degrees = 270
	if Input.is_action_pressed("ui_up"):
		movement_direction = Vector2.UP
		rotation_degrees = 90

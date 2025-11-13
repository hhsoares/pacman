extends CharacterBody2D
class_name Pinky

@onready var _animated_sprite = $AnimatedSprite2D
@onready var state_machine = $StateMachine
@export var speed: float = 100.0
var direction: Vector2 = Vector2.UP
var is_frightened: bool = false

func _physics_process(delta: float) -> void:
	if not Globals.ghosts_can_move:
		_animated_sprite.play("stop")
		return
	if is_frightened:
		return
		
	if direction == Vector2.LEFT:
		_animated_sprite.play("left")
	elif direction == Vector2.RIGHT:
		_animated_sprite.play("right")
	elif direction == Vector2.UP:
		_animated_sprite.play("up")
	elif direction == Vector2.DOWN:
		_animated_sprite.play("down")

func frighten(seconds: float) -> void:
	# pass duration to state; simplest via exported property
	var frightened_state: Node = state_machine.states.get("frightened")
	if frightened_state:
		frightened_state.duration = seconds
	state_machine.change_state("frightened")

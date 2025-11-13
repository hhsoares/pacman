extends CharacterBody2D
class_name Inky

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

func frighten(duration: float) -> void:
	if not is_instance_valid(state_machine):
		return
	if state_machine.current_state == null:
		return

	var current: State = state_machine.current_state
	var current_name: String = current.name.to_lower()

	# don't frighten if still in box/start logic
	if current_name == "start" or current_name == "spawn":
		return

	var frightened_state: State = state_machine.states.get("frightened") as State
	if frightened_state == null:
		return

	frightened_state.duration = duration
	state_machine.change_state("frightened")

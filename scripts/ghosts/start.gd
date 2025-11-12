extends State

@onready var ghost := owner as CharacterBody2D
@onready var blinky: CharacterBody2D = $"../../../Blinky"
@export var exit_point: Node2D
@export var exit_speed: float = 120.0
@export var arrive_epsilon: float = 2.0

var _target: Vector2
var _has_target := false


func _ready() -> void:
	await get_tree().process_frame
	if exit_point:
		_target = exit_point.global_position
	else:
		_target = blinky.global_position
	_has_target = true


func physics_update(delta: float) -> void:
	if not Globals.ghosts_can_move:
		return

	if ghost is Blinky:
		state_machine.change_state("scatter")
		return

	if ghost is Pinky:
		if not _has_target:
			return

		if ghost.global_position.distance_to(_target) <= arrive_epsilon:
			ghost.global_position = _target
			ghost.velocity = Vector2.ZERO
			state_machine.change_state("scatter")
			return

		var dir := (_target - ghost.global_position).normalized()
		ghost.velocity = dir * exit_speed
		ghost.move_and_slide()

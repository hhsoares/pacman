extends State

@onready var ghost := owner as CharacterBody2D
@onready var pinky: CharacterBody2D = $"../../../Pinky"

@export var move_speed: float = 120.0
@export var arrive_epsilon: float = 2.0

var _inky_timer: float = 0.0
var _clyde_timer: float = 0.0
var _inky_released: bool = false
var _clyde_released: bool = false

var _inky_target: Vector2
var _clyde_target: Vector2


func _ready() -> void:
	await get_tree().process_frame
	_inky_target = pinky.global_position
	_clyde_target = pinky.global_position


func physics_update(delta: float) -> void:
	if not Globals.ghosts_can_move:
		return

	# Blinky starts immediately
	if ghost is Blinky:
		state_machine.change_state("scatter")
		return

	# Pinky leaves first
	if ghost is Pinky:
		state_machine.change_state("spawn")
		return

	# Inky
	if ghost is Inky:
		_inky_timer += delta
		if _inky_timer >= 8.0:
			if ghost.global_position.distance_to(_inky_target) <= arrive_epsilon:
				ghost.global_position = _inky_target
				ghost.velocity = Vector2.ZERO
				state_machine.change_state("spawn")
				return

			var dir := (_inky_target - ghost.global_position).normalized()
			ghost.velocity = dir * move_speed
			ghost.move_and_slide()
		return

	# Clyde
	if ghost is Clyde:
		_clyde_timer += delta
		if _clyde_timer >= 12.0:
			if ghost.global_position.distance_to(_clyde_target) <= arrive_epsilon:
				ghost.global_position = _clyde_target
				ghost.velocity = Vector2.ZERO
				state_machine.change_state("spawn")
				return

			var dir := (_clyde_target - ghost.global_position).normalized()
			ghost.velocity = dir * move_speed
			ghost.move_and_slide()
		return

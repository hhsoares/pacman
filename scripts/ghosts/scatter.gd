extends State

@onready var ghost := owner as CharacterBody2D

const TILE_SIZE := 24.0
const BLINKY_TARGET_TILE := Vector2(12, -14)

func physics_update(delta: float) -> void:
	if ghost is Blinky:
		_move_to_target(BLINKY_TARGET_TILE * TILE_SIZE, delta)

func _move_to_target(target_pos: Vector2, delta: float) -> void:
	var direction := (target_pos - ghost.global_position).normalized()
	ghost.velocity = direction * ghost.speed
	ghost.move_and_slide()

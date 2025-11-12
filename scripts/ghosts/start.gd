extends State

@onready var ghost := owner as CharacterBody2D

func physics_update(delta: float) -> void:
	if not Globals.ghosts_can_move:
		return

	if ghost is Blinky:
		state_machine.change_state("scatter")
	elif ghost is Pinky:
		state_machine.change_state("spawn")

extends State

@onready var ghost := owner as CharacterBody2D

func physics_update(delta: float) -> void:
	if ghost is Blinky:
		state_machine.change_state("scatter")
	if ghost is Pinky:
		pass

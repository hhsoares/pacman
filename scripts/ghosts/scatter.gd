extends State

@onready var ghost := owner as CharacterBody2D

func physics_update(delta: float) -> void:
	if ghost is Blinky:
		print("blinky scatter")

extends Node2D

@onready var left_area2d = $LeftColorRect/Area2D
@onready var right_area2d = $RightColorRect/Area2D

var allow_left_transition = true
var allow_right_transition = true

func _on_left_area_2d_body_entered(body) -> void:
	if body.velocity.x < 0:
		body.position.x = right_area2d.global_position.x + 45
		allow_right_transition = false

func _on_left_area_2d_body_exited(body) -> void:
	allow_right_transition = true

func _on_right_area_2d_body_entered(body) -> void:
	if body.velocity.x > 0:
		body.position.x = left_area2d.global_position.x + 20
		allow_left_transition = false

func _on_right_area_2d_body_exited(body) -> void:
	allow_left_transition = true

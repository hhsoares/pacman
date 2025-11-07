extends Area2D
class_name Fruit

@export var score_value: int = 100  # set per fruit in the editor

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Pacman:
		body.update_score(score_value)
		queue_free()

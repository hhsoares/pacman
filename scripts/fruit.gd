extends Area2D
class_name Fruit

@export var score_value: int = 100

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var t := Timer.new()
	t.wait_time = randf_range(9.0, 10.0)
	t.one_shot = true
	t.timeout.connect(queue_free)
	add_child(t)
	t.start()

func _on_body_entered(body: Node2D) -> void:
	if body is Pacman:
		body.update_score(score_value)
		queue_free()

extends Node2D

@export var blink_interval: float = 0.17

var blink_timer: Timer

func _ready() -> void:
	blink_timer = Timer.new()
	blink_timer.wait_time = blink_interval
	blink_timer.autostart = true
	blink_timer.one_shot = false
	blink_timer.timeout.connect(_on_blink_timeout)
	add_child(blink_timer)

func _on_blink_timeout() -> void:
	visible = not visible

extends State

@onready var ghost := owner as CharacterBody2D
@onready var anim: AnimatedSprite2D = ghost.get_node("AnimatedSprite2D")
@onready var collider: CollisionShape2D = ghost.get_node("CollisionShape2D")

@export var respawn_point: Node2D        # set this in the editor
@export var respawn_delay: float = 3.0

var _time: float = 0.0


func enter() -> void:
	_time = 0.0
	ghost.is_frightened = false
	ghost.is_eaten = true
	ghost.velocity = Vector2.ZERO
	ghost.direction = Vector2.ZERO

	# immediately move ghost to respawn position
	if respawn_point:
		ghost.global_position = respawn_point.global_position

	# hide and disable collisions so Pac-Man can pass through
	ghost.visible = false
	if is_instance_valid(collider):
		collider.disabled = true


func exit() -> void:
	ghost.is_eaten = false
	# safety: make sure ghost is visible and collidable again
	ghost.visible = true
	if is_instance_valid(collider):
		collider.disabled = false


func physics_update(delta: float) -> void:
	_time += delta

	# just wait; no movement while "eyes" are offscreen
	if _time >= respawn_delay:
		_time = 0.0

		# re-enable and send ghost to spawn logic
		ghost.visible = true
		if is_instance_valid(collider):
			collider.disabled = false

		if is_instance_valid(state_machine):
			state_machine.change_state("spawn")

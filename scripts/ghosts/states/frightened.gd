extends State

@onready var ghost := owner as CharacterBody2D
@onready var maze: TileMapLayer = $"../../../Maze"
@onready var anim: AnimatedSprite2D = ghost.get_node("AnimatedSprite2D")

const TILE_SIZE := 24.0

@export var duration: float = 6.0
@export var speed_multiplier: float = 0.5
@export var blink_threshold: float = 2.0

var _time := 0.0
var _orig_speed := 0.0
var _last_cell: Vector2i
var _has_last_cell := false


func enter() -> void:
	_time = 0.0
	_has_last_cell = false
	_orig_speed = ghost.speed
	ghost.speed = _orig_speed * speed_multiplier
	# classic behavior: reverse once on entry
	ghost.direction = -ghost.direction

	ghost.is_frightened = true
	anim.play("blue")


func exit() -> void:
	ghost.speed = _orig_speed
	ghost.is_frightened = false


func physics_update(delta: float) -> void:
	_time += delta
	
	var remaining := duration - _time
	if remaining <= blink_threshold:
		if anim.animation != "blinking":
			anim.play("blinking")
	else:
		if anim.animation != "blue":
			anim.play("blue")
	
	if _time >= duration:
		state_machine.change_state("chase")
		return

	if not Globals.ghosts_can_move:
		return

	var current_cell := _get_current_cell()

	# choose a random valid direction (no reverse)
	if not _has_last_cell:
		_last_cell = current_cell
		_has_last_cell = true
		ghost.direction = _choose_random_dir(current_cell)
	else:
		if current_cell != _last_cell:
			ghost.global_position = _get_cell_center(current_cell)
			_last_cell = current_cell
			ghost.direction = _choose_random_dir(current_cell)

	if ghost.direction == Vector2.ZERO:
		ghost.velocity = Vector2.ZERO
		return

	ghost.velocity = ghost.direction * ghost.speed
	ghost.move_and_slide()


# --- helpers ---

func _get_current_cell() -> Vector2i:
	var local_pos: Vector2 = maze.to_local(ghost.global_position)
	return maze.local_to_map(local_pos)

func _get_cell_center(cell: Vector2i) -> Vector2:
	var local_center := (Vector2(cell) + Vector2(0.5, 0.5)) * TILE_SIZE
	return maze.to_global(local_center)

func _get_adjacent_cells(cell: Vector2i) -> Dictionary:
	return {
		"up": cell + Vector2i(0, -1),
		"down": cell + Vector2i(0, 1),
		"left": cell + Vector2i(-1, 0),
		"right": cell + Vector2i(1, 0),
	}

func _is_walkable(cell: Vector2i) -> bool:
	var source_id := maze.get_cell_source_id(cell)
	if source_id == -1:
		return false
	var data := maze.get_cell_tile_data(cell)
	if data == null:
		return false
	return bool(data.get_custom_data("path"))

func _choose_random_dir(current_cell: Vector2i) -> Vector2:
	var neighbors := _get_adjacent_cells(current_cell)
	var opposite: Vector2 = -ghost.direction   # <-- explicit type

	var candidates: Array[Vector2] = []

	for key in neighbors.keys():
		var neighbor_cell: Vector2i = neighbors[key]

		var dir: Vector2
		match key:
			"up":
				dir = Vector2.UP
			"down":
				dir = Vector2.DOWN
			"left":
				dir = Vector2.LEFT
			"right":
				dir = Vector2.RIGHT
			_:
				dir = Vector2.ZERO

		if dir == opposite:
			continue

		if _is_walkable(neighbor_cell):
			candidates.append(dir)

	# no forward options → allow reverse if possible
	if candidates.is_empty():
		var back_cell := current_cell + Vector2i(int(opposite.x), int(opposite.y))
		if _is_walkable(back_cell):
			return opposite
		return Vector2.ZERO

	return candidates[randi() % candidates.size()]

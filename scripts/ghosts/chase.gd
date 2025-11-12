extends State

@onready var ghost := owner as CharacterBody2D
@onready var maze: TileMapLayer = $"../../../Maze"
@onready var pacman: CharacterBody2D = $"../../../Pac-Man"

const TILE_SIZE := 24.0

var _last_cell: Vector2i
var _has_last_cell: bool = false

var _chase_time: float = 0.0
var _chase_timer_started: bool = false
var _last_pac_dir: Vector2 = Vector2.LEFT


func _ready() -> void:
	_chase_time = 0.0
	_chase_timer_started = true


func physics_update(delta: float) -> void:
	if not Globals.ghosts_can_move:
		return

	# 20s global timer for this state
	if _chase_timer_started and is_instance_valid(state_machine):
		_chase_time += delta
		if _chase_time >= 20.0:
			print("Chase -> Scatter")
			state_machine.change_state("scatter")
			_chase_time = 0
			return

	if ghost is Pinky:
		var current_cell := _get_current_cell()
		var pac_cell := _get_pacman_cell()
		var pac_dir := _get_pacman_dir()

		var ahead := Vector2i(int(pac_dir.x), int(pac_dir.y)) * 4
		var left := Vector2i(int(-pac_dir.y), int(pac_dir.x)) * 4
		var target_cell := pac_cell + ahead + left

		if not _has_last_cell:
			_last_cell = current_cell
			_has_last_cell = true
			ghost.direction = _choose_dir_to_target(current_cell, target_cell)
		else:
			if current_cell != _last_cell:
				ghost.global_position = _get_cell_center(current_cell)
				_last_cell = current_cell
				ghost.direction = _choose_dir_to_target(current_cell, target_cell)

		if ghost.direction == Vector2.ZERO:
			ghost.velocity = Vector2.ZERO
			return

		ghost.velocity = ghost.direction * ghost.speed
		ghost.move_and_slide()

	# movement: Blinky logic
	if ghost is Blinky:
		var current_cell := _get_current_cell()
		var pac_cell := _get_pacman_cell()

		if not _has_last_cell:
			_last_cell = current_cell
			_has_last_cell = true
			ghost.direction = _choose_dir_to_target(current_cell, pac_cell)
		else:
			if current_cell != _last_cell:
				# snap to tile center and pick next direction
				ghost.global_position = _get_cell_center(current_cell)
				_last_cell = current_cell
				ghost.direction = _choose_dir_to_target(current_cell, pac_cell)

		if ghost.direction == Vector2.ZERO:
			ghost.velocity = Vector2.ZERO
			return

		ghost.velocity = ghost.direction * ghost.speed
		ghost.move_and_slide()


func _get_current_cell() -> Vector2i:
	var local_pos: Vector2 = maze.to_local(ghost.global_position)
	return maze.local_to_map(local_pos)

func _get_pacman_cell() -> Vector2i:
	var local_pos: Vector2 = maze.to_local(pacman.global_position)
	return maze.local_to_map(local_pos)

func _get_pacman_dir() -> Vector2:
	var dir: Vector2 = pacman.get("movement_direction")
	if dir == Vector2.ZERO:
		return _last_pac_dir
	_last_pac_dir = dir
	return dir

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

func _choose_dir_to_target(current_cell: Vector2i, target_cell: Vector2i) -> Vector2:
	var best_dir: Vector2 = Vector2.ZERO
	var best_dist: float = INF
	var found := false

	var neighbors := _get_adjacent_cells(current_cell)
	var opposite: Vector2 = -ghost.direction

	for key in neighbors.keys():
		var neighbor_cell: Vector2i = neighbors[key]

		var dir: Vector2
		match key:
			"up": dir = Vector2.UP
			"down": dir = Vector2.DOWN
			"left": dir = Vector2.LEFT
			"right": dir = Vector2.RIGHT

		if dir == opposite:
			continue
		if not _is_walkable(neighbor_cell):
			continue

		var dist: float = abs(neighbor_cell.x - target_cell.x) + abs(neighbor_cell.y - target_cell.y)
		if dist < best_dist:
			best_dist = dist
			best_dir = dir
			found = true

	if found:
		return best_dir

	var back_cell := current_cell + Vector2i(int(opposite.x), int(opposite.y))
	if _is_walkable(back_cell):
		return opposite

	return Vector2.ZERO

func _is_walkable(cell: Vector2i) -> bool:
	var source_id := maze.get_cell_source_id(cell)
	if source_id == -1:
		return false
	var data := maze.get_cell_tile_data(cell)
	if data == null:
		return false
	return bool(data.get_custom_data("path"))

extends State

@onready var ghost := owner as CharacterBody2D
@onready var maze: TileMapLayer = $"../../../Maze"

const TILE_SIZE := 24.0
const BLINKY_TARGET_TILE := Vector2i(12, -14)

var _last_cell: Vector2i
var _has_last_cell: bool = false


func physics_update(delta: float) -> void:
	if not Globals.ghosts_can_move:
		return

	if ghost is Blinky:
		var current_cell := _get_current_cell()

		if not _has_last_cell:
			_last_cell = current_cell
			_has_last_cell = true
			ghost.direction = _choose_dir_to_target(current_cell, BLINKY_TARGET_TILE)
		else:
			if current_cell != _last_cell:
				ghost.global_position = _get_cell_center(current_cell)
				_last_cell = current_cell
				ghost.direction = _choose_dir_to_target(current_cell, BLINKY_TARGET_TILE)

		var next_cell := _last_cell + Vector2i(int(ghost.direction.x), int(ghost.direction.y))
		print("Current:", current_cell,
			" | Next:", next_cell,
			" | Dir:", ghost.direction,
			" | Target:", BLINKY_TARGET_TILE)

		# if we somehow got ZERO, don't move this frame
		if ghost.direction == Vector2.ZERO:
			ghost.velocity = Vector2.ZERO
			return

		ghost.velocity = ghost.direction * ghost.speed
		ghost.move_and_slide()


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


func _choose_dir_to_target(current_cell: Vector2i, target_cell: Vector2i) -> Vector2:
	var best_dir: Vector2 = Vector2.ZERO
	var best_dist: float = INF
	var found: bool = false

	var neighbors := _get_adjacent_cells(current_cell)
	var opposite: Vector2 = -ghost.direction

	print("\nChecking neighbors for cell:", current_cell, " dir:", ghost.direction)

	for key in neighbors.keys():
		var neighbor_cell: Vector2i = neighbors[key]

		var dir: Vector2
		match key:
			"up": dir = Vector2.UP
			"down": dir = Vector2.DOWN
			"left": dir = Vector2.LEFT
			"right": dir = Vector2.RIGHT

		if dir == opposite:
			print("  Skipping", key, "(reverse)")
			continue

		var walkable := _is_walkable(neighbor_cell)
		var dist: float = abs(neighbor_cell.x - target_cell.x) + abs(neighbor_cell.y - target_cell.y)

		print("  ", key, "->", neighbor_cell,
			" walkable:", walkable,
			" dist:", dist)

		if not walkable:
			continue

		if dist < best_dist:
			best_dist = dist
			best_dir = dir
			found = true

	if found:
		print("  => chosen dir:", best_dir)
		return best_dir

	print("  => NO non-reverse walkable neighbor found")

	# sanity debug of reverse cell
	var back_cell := current_cell + Vector2i(int(opposite.x), int(opposite.y))
	var back_walkable := _is_walkable(back_cell)
	print("  Reverse cell:", back_cell, " walkable:", back_walkable)

	if back_walkable:
		print("  => using reverse:", opposite)
		return opposite

	print("  => NO walkable neighbors at all, returning ZERO")
	return Vector2.ZERO


func _is_walkable(cell: Vector2i) -> bool:
	var source_id := maze.get_cell_source_id(cell)
	var data := maze.get_cell_tile_data(cell)

	var path_flag: Variant = null  # explicitly typed, avoids inference error
	if data != null:
		path_flag = data.get_custom_data("path")

	print("    [is_walkable] cell:", cell,
		" source_id:", source_id,
		" data_null:", data == null,
		" path_custom:", path_flag)

	if source_id == -1:
		return false
	if data == null:
		return false

	return bool(path_flag)

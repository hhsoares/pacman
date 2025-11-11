extends State

@onready var ghost := owner as CharacterBody2D
@onready var maze: TileMapLayer = $"../../../Maze"

const TILE_SIZE := 24.0
const BLINKY_TARGET_TILE := Vector2(12, -14)
const TILE_CENTER_TOLERANCE := 1.0

func physics_update(delta: float) -> void:
	if not Globals.ghosts_can_move:
		return

	if ghost is Blinky:
		var current_cell := _get_current_cell()
		var dir := _choose_dir_to_target(current_cell, BLINKY_TARGET_TILE)
		
		print("Current cell:", current_cell, 
			" Target:", BLINKY_TARGET_TILE, 
			" Direction:", dir)

func _get_current_cell() -> Vector2i:
	var local_pos: Vector2 = maze.to_local(ghost.global_position)
	var cell: Vector2i = maze.local_to_map(local_pos)
	return cell

func _get_adjacent_cells(cell: Vector2i) -> Dictionary:
	return {
		"up": cell + Vector2i(0, -1),
		"down": cell + Vector2i(0, 1),
		"left": cell + Vector2i(-1, 0),
		"right": cell + Vector2i(1, 0),
	}

func _choose_dir_to_target(current_cell: Vector2i, target_cell: Vector2i) -> Vector2:
	var best_dir: Vector2 = ghost.direction
	var best_dist: float = INF

	var neighbors := _get_adjacent_cells(current_cell)
	var opposite: Vector2 = -ghost.direction

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

		if dir == opposite:
			continue

		if not _is_walkable(neighbor_cell):
			continue

		var dist: float = abs(neighbor_cell.x - target_cell.x) + abs(neighbor_cell.y - target_cell.y)

		if dist < best_dist:
			best_dist = dist
			best_dir = dir

	return best_dir

func _is_walkable(cell: Vector2i) -> bool:
	if maze.get_cell_source_id(cell) == -1:
		return false

	var data := maze.get_cell_tile_data(cell)
	if data == null:
		return false

	return bool(data.get_custom_data("path"))

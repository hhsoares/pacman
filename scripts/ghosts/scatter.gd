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
		var cell := _get_current_cell()
		var adj := _get_adjacent_cells(cell)
		print("Blinky cell: ", cell)
		print(adj)

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

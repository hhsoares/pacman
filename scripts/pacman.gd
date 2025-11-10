extends CharacterBody2D

class_name Pacman

var next_movement_direction = Vector2.ZERO
var movement_direction = Vector2.ZERO
var shape_query = PhysicsShapeQueryParameters2D.new()

@export var speed := 300

var can_move: bool = true

@onready var direction_pointer = $DirectionPointer
@onready var collision_shape_2d = $CollisionShape2D
@onready var _animated_sprite = $AnimatedSprite2D
@onready var pellets: TileMapLayer = $"../Pellets"
@onready var fruit_spawn_point: Node2D = $"../Fruit Spawn Point"

@export var cherries_scene: PackedScene
@export var strawberry_scene: PackedScene
@export var peach_scene: PackedScene
@export var apple_scene: PackedScene
@export var grapes_scene: PackedScene
@export var galaxian_scene: PackedScene
@export var bell_scene: PackedScene
@export var key_scene: PackedScene

var pellets_eaten: int = 0
var first_fruit_spawned: bool = false
var second_fruit_spawned: bool = false

@onready var pacman: CharacterBody2D = $"."
@onready var blinky: CharacterBody2D = $"../Blinky"
@onready var pinky: CharacterBody2D = $"../Pinky"
@onready var inky: CharacterBody2D = $"../Inky"
@onready var clyde: CharacterBody2D = $"../Clyde"

@onready var scoreUI: Label = $"../1UP"
@onready var highScoreUI: Label = $"../HighScore"
@onready var playerOneUI: Label = $"../PlayerOne"
@onready var readyUI: Label = $"../Ready"

@onready var startupSound: AudioStreamPlayer = $"../Startup Sound"

func _ready() -> void:
	for  ghost in [blinky, pinky, inky, clyde]:
		ghost.visible = false
	pacman.visible = false

	if not Globals.startup_played:
		can_move = false
		readyUI.visible = true
		startupSound.play()
		startupSound.finished.connect(_on_startup_finished)
		Globals.startup_played = true

	playerOneUI.visible = true
	await get_tree().create_timer(2.5).timeout
	playerOneUI.visible = false

	for  ghost in [blinky, pinky, inky, clyde]:
		ghost.visible = true
	pacman.visible = true

	shape_query.shape = collision_shape_2d.shape
	shape_query.collision_mask = 2
	print("Current level:", Globals.level)

	check_speed()
	print("Current speed:", speed)

	scoreUI.text = str(Globals.score).pad_zeros(6)
	highScoreUI.text = str(Globals.high_score).pad_zeros(6)

func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		_animated_sprite.play("start")
		return
	get_input()

	if movement_direction == Vector2.ZERO:
		movement_direction = next_movement_direction
	if can_move_in_direction(next_movement_direction, delta):
		movement_direction = next_movement_direction

	velocity = movement_direction * speed

	if movement_direction == Vector2.ZERO or not can_move_in_direction(movement_direction, delta):
		_animated_sprite.play("stop")
	else:
		_animated_sprite.play("moving")

	move_and_slide()
	check_pellet()

func get_input() -> void:
	if Input.is_action_pressed("ui_left"):
		next_movement_direction = Vector2.LEFT
		rotation_degrees = 0
	if Input.is_action_pressed("ui_right"):
		next_movement_direction = Vector2.RIGHT
		rotation_degrees = 180
	if Input.is_action_pressed("ui_down"):
		next_movement_direction = Vector2.DOWN
		rotation_degrees = 270
	if Input.is_action_pressed("ui_up"):
		next_movement_direction = Vector2.UP
		rotation_degrees = 90

func can_move_in_direction(dir: Vector2, delta: float) -> bool:
	shape_query.transform = global_transform.translated(dir * speed * delta * 2.0)
	var result := get_world_2d().direct_space_state.intersect_shape(shape_query)
	return result.size() == 0

func update_score(value: int) -> void:
	Globals.score += value
	if Globals.score > 999999:
		Globals.score = 999999
	scoreUI.text = str(Globals.score).pad_zeros(6)

	if Globals.score > Globals.high_score:
		Globals.high_score = Globals.score
	highScoreUI.text = str(Globals.high_score).pad_zeros(6)

func check_speed() -> void:
	if Globals.level < 2:
		speed *= 0.8
	elif Globals.level < 5 or Globals.level > 20:
		speed *= 0.9

func check_pellet() -> void:
	var cell: Vector2i = pellets.local_to_map(global_position)

	if pellets.get_cell_source_id(cell) == -1:
		return

	var data := pellets.get_cell_tile_data(cell)
	if data == null:
		return

	var pellet_type: String = data.get_custom_data("pellet_type")

	match pellet_type:
		"small":
			update_score(10)
		"big":
			update_score(50)

	pellets.erase_cell(cell)

	pellets_eaten += 1
	print("Pellets eaten:", pellets_eaten)
	_check_fruit_spawn()

	if pellets.get_used_cells().is_empty():
		print("All pellets collected — advancing to next level")
		Globals.level += 1
		get_tree().reload_current_scene()

func _check_fruit_spawn() -> void:
	if not first_fruit_spawned and pellets_eaten >= 70:
		print("Reached 70 pellets — spawning first fruit")
		_spawn_fruit()
		first_fruit_spawned = true
	elif not second_fruit_spawned and pellets_eaten >= 170:
		print("Reached 170 pellets — spawning second fruit")
		_spawn_fruit()
		second_fruit_spawned = true

func _spawn_fruit() -> void:
	var scene := _get_fruit_scene_for_level(Globals.level)

	var fruit := scene.instantiate()
	fruit.global_position = fruit_spawn_point.global_position
	get_tree().current_scene.add_child(fruit)
	print("Spawned fruit for level", Globals.level, "at", fruit.global_position)

func _get_fruit_scene_for_level(level: int) -> PackedScene:
	match level:
		1:
			print("Level 1 fruit: Cherries")
			return cherries_scene
		2:
			print("Level 2 fruit: Strawberry")
			return strawberry_scene
		3, 4:
			print("Level", level, "fruit: Peach")
			return peach_scene
		5, 6:
			print("Level", level, "fruit: Apple")
			return apple_scene
		7, 8:
			print("Level", level, "fruit: Grapes")
			return grapes_scene
		9, 10:
			print("Level", level, "fruit: Galaxian")
			return galaxian_scene
		11, 12:
			print("Level", level, "fruit: Bell")
			return bell_scene
		_:
			print("Level", level, "fruit: Key")
			return key_scene

func _on_startup_finished() -> void:
	can_move = true
	readyUI.visible = false

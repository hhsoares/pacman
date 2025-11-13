extends CharacterBody2D

class_name Pacman

var next_movement_direction = Vector2.ZERO
var movement_direction = Vector2.ZERO
var shape_query = PhysicsShapeQueryParameters2D.new()

@export var speed := 400 #change back to 300 later

var can_move: bool = true
@onready var is_dying: bool = false

@onready var direction_pointer = $DirectionPointer
@onready var collision_shape_2d = $CollisionShape2D
@onready var _animated_sprite = $AnimatedSprite2D
@onready var maze: TileMapLayer = $"../Maze"
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
var current_fruit: Node2D = null

@onready var pacman: CharacterBody2D = $"."
@onready var blinky: CharacterBody2D = $"../Blinky"
@onready var pinky: CharacterBody2D = $"../Pinky"
@onready var inky: CharacterBody2D = $"../Inky"
@onready var clyde: CharacterBody2D = $"../Clyde"

@onready var scoreUI: Label = $"../1UP"
@onready var highScoreUI: Label = $"../HighScore"
@onready var playerOneUI: Label = $"../PlayerOne"
@onready var readyUI: Label = $"../Ready"
@onready var gameOverUI: Label = $"../Game Over"

@onready var startupSound: AudioStreamPlayer = $"../Startup Sound"
@onready var fruitSound: AudioStreamPlayer = $"../Fruit Sound"
@onready var ghostSound: AudioStreamPlayer = $"../Ghost Sound"
@onready var deathSound: AudioStreamPlayer = $"../Death Sound"
@onready var eatSound: AudioStreamPlayer = $"../Eat Sound"

var _eat_sound_cooldown: float = 0.0
const EAT_SOUND_INTERVAL := 0.25

func _ready() -> void:
	print(Globals.respawned)
	Globals.ghosts_can_move = false
	can_move = false
	gameOverUI.visible = false

	for ghost in [blinky, pinky, inky, clyde]:
		ghost.visible = false
	if Globals.level == 1:
		pacman.visible = false

	if not Globals.startup_played:
		startupSound.play()
		startupSound.finished.connect(_on_startup_finished)
		Globals.startup_played = true

	if Globals.level == 1:
		playerOneUI.visible = true
	await get_tree().create_timer(2.5).timeout
	playerOneUI.visible = false

	for ghost in [blinky, pinky, inky, clyde]:
		ghost.visible = true
	pacman.visible = true

	if Globals.level > 1 or Globals.respawned == true:
		can_move = true
		Globals.ghosts_can_move = true
		readyUI.visible = false

	shape_query.shape = collision_shape_2d.shape
	shape_query.collision_mask = 2
	print("Current level:", Globals.level)

	check_speed()
	print("Current speed:", speed)

	scoreUI.text = str(Globals.score).pad_zeros(6)
	highScoreUI.text = str(Globals.high_score).pad_zeros(6)

func _physics_process(delta: float) -> void:
	_eat_sound_cooldown -= delta

	if is_dying:
		velocity = Vector2.ZERO
		return

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

#	if Globals.lives <= 0:
#		gameOverUI.visible = true
#	else:
#		gameOverUI.visible = false

	move_and_slide()
	_check_ghost_collision()
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
			_play_eat_sound()

			
		"big":
			update_score(50)
			_frighten_all(6.0)

	pellets.erase_cell(cell)

	pellets_eaten += 1
	print("Pellets eaten:", pellets_eaten)
	_check_fruit_spawn()

	if pellets.get_used_cells().is_empty():
		if is_instance_valid(current_fruit):
			current_fruit.queue_free()
		can_move = false
		_animated_sprite.play("start")
		await get_tree().create_timer(2.0).timeout
		for ghost in [blinky, pinky, inky, clyde]:
			ghost.visible = false
		await _blink_maze(4, 0.15)

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

	if is_instance_valid(current_fruit):
		current_fruit.queue_free()

	var fruit := scene.instantiate()
	fruit.global_position = fruit_spawn_point.global_position
	get_tree().current_scene.add_child(fruit)

	current_fruit = fruit

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
	Globals.ghosts_can_move = true
	readyUI.visible = false

func _blink_maze(times: int = 4, interval: float = 0.15) -> void:
	var mat := maze.material
	if mat and mat is ShaderMaterial:
		for i in range(times):
			mat.set_shader_parameter("flash", 1.0)
			await get_tree().create_timer(interval).timeout
			mat.set_shader_parameter("flash", 0.0)
			await get_tree().create_timer(interval).timeout

func _check_ghost_collision() -> void:
	if is_dying:
		return

	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider and collider.is_in_group("ghost"):
			_on_ghost_collision(collider)
			break

func _on_ghost_collision(ghost: Node) -> void:
	# if this ghost is already eaten, ignore collision completely
	if ghost.has_method("eaten") and bool(ghost.get("is_eaten")):
		return

	if _try_eat_ghost(ghost):
		return

	if is_dying:
		return

	is_dying = true
	
	print("Pacman hit ghost: ", ghost.name)
	velocity = Vector2.ZERO
	_animated_sprite.play("stop")
	deathSound.play()
	await get_tree().create_timer(1.5).timeout
	rotation_degrees = 0
	_animated_sprite.play("death")
	await _animated_sprite.animation_finished
	Globals.lives -= 1
	get_tree().reload_current_scene()
	Globals.respawned = true

func _frighten_all(duration: float) -> void:
	for g in [blinky, pinky, inky, clyde]:
		if is_instance_valid(g) and g.has_method("frighten"):
			g.frighten(duration)

func _try_eat_ghost(ghost: Node) -> bool:
	if not ghost.has_method("eaten"):
		return false

	var is_frightened: bool = bool(ghost.get("is_frightened"))
	var is_eaten_flag: bool = bool(ghost.get("is_eaten"))

	# optional: remove this print when you're done testing
	print("Ghost collision:", ghost.name,
		" frightened:", is_frightened,
		" eaten:", is_eaten_flag)

	if is_frightened and not is_eaten_flag:
		_eat_ghost(ghost)
		return true

	return false

func _eat_ghost(ghost: Node) -> void:
	ghostSound.play()
	update_score(200)
	ghost.call("eaten")

func _play_eat_sound() -> void:
	if _eat_sound_cooldown <= 0.0:
		eatSound.play()
		_eat_sound_cooldown = EAT_SOUND_INTERVAL

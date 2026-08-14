extends Node

@onready var level_container: Node = $LevelContainer
@onready var transition: CanvasLayer = $LevelTransition

var active_level: Node
var is_transitioning := false
var game_started := false
var intro_cinematic: Node = null
var final_cinematic: Node = null

func _ready() -> void:
	GameState.level_completed.connect(_on_level_completed)
	var menu := get_node_or_null("MainMenu")
	if menu != null:
		menu.start_requested.connect(start_game)
	else:
		start_game()

func start_game() -> void:
	if game_started:
		return
	game_started = true
	var menu := get_node_or_null("MainMenu")
	if menu != null:
		menu.queue_free()
	show_intro_cinematic()

func show_intro_cinematic() -> void:
	var intro_scene := load("res://scenes/cinematics/intro_cinematic.tscn") as PackedScene
	intro_cinematic = intro_scene.instantiate()
	add_child(intro_cinematic)
	intro_cinematic.finished.connect(_on_intro_finished)

func _on_intro_finished() -> void:
	if intro_cinematic != null:
		intro_cinematic.queue_free()
		intro_cinematic = null
	GameState.current_level_id = "world_1_level_1"
	GameState.level_begun.emit("world_1_level_1")
	load_level("world_1_level_1")

func show_final_cinematic() -> void:
	var cinematic_scene := load("res://scenes/cinematics/final_cinematic.tscn") as PackedScene
	final_cinematic = cinematic_scene.instantiate()
	add_child(final_cinematic)
	final_cinematic.finished.connect(_on_final_finished)

func _on_final_finished() -> void:
	if final_cinematic != null:
		final_cinematic.queue_free()
		final_cinematic = null
	load_level("final_screen")

func load_level(level_id: String) -> void:
	var scene_path := LevelProgression.get_scene_path(level_id)
	if scene_path.is_empty():
		return
	if active_level != null:
		active_level.queue_free()
	var packed_scene := load(scene_path) as PackedScene
	active_level = packed_scene.instantiate()
	level_container.add_child(active_level)

func _on_level_completed(level_id: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	var next_level_id := LevelProgression.get_next_level(level_id)
	if level_id == "world_4_boss":
		show_final_cinematic()
		await get_tree().create_timer(0.1).timeout
		if final_cinematic != null:
			final_cinematic.queue_free()
			final_cinematic = null
	await transition.play_completion(next_level_id)
	if not next_level_id.is_empty() and not LevelProgression.get_scene_path(next_level_id).is_empty():
		GameState.prepare_next_level()
		load_level(next_level_id)
		transition.fade_out()
	is_transitioning = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused

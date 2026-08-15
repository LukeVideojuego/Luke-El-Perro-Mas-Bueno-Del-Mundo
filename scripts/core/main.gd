extends Node

@onready var level_container: Node = $LevelContainer
@onready var transition: CanvasLayer = $LevelTransition
@onready var hud: CanvasLayer = $HUD

var active_level: Node
var is_transitioning := false
var game_started := false
var intro_cinematic: Node = null
var final_cinematic: Node = null
var world_map: Node = null

func _ready() -> void:
	hud.visible = false
	GameState.level_completed.connect(_on_level_completed)
	GameState.has_seen_intro = SaveManager.peek_has_seen_intro()
	GameState.highest_order_reached = SaveManager.peek_highest_order_reached()
	var menu := get_node_or_null("MainMenu")
	if menu != null:
		menu.new_game_requested.connect(start_game)
		menu.continue_requested.connect(_on_continue_requested)
		menu.password_requested.connect(_on_password_requested)
		menu.map_requested.connect(_on_map_requested)
	else:
		start_game()

## Punto de entrada de "COMENZAR JUEGO" (partida nueva desde cero).
## Se mantiene con este nombre porque la suite de tests automatizados
## del proyecto (tests/integration_*_test.gd) lo llama directamente.
func start_game() -> void:
	if game_started:
		return
	game_started = true
	GameState.reset_for_new_game()
	_free_menu()
	if GameState.has_seen_intro:
		GameState.current_level_id = "world_1_level_1"
		GameState.level_begun.emit("world_1_level_1")
		load_level("world_1_level_1")
	else:
		show_intro_cinematic()

func _on_continue_requested() -> void:
	if game_started:
		return
	game_started = true
	_free_menu()
	if not SaveManager.load_game():
		GameState.reset_for_new_game()
		show_intro_cinematic()
		return
	load_level(GameState.current_level_id)

func _on_password_requested(level_id: String) -> void:
	if game_started:
		return
	game_started = true
	GameState.reset_for_new_game()
	_free_menu()
	GameState.current_level_id = level_id
	GameState.level_begun.emit(level_id)
	load_level(level_id)

## Muestra el mapa del mundo desde el menú principal (no reemplaza al menú,
## solo se superpone; "VOLVER" lo cierra sin perder el menú de fondo).
func _on_map_requested() -> void:
	if world_map != null:
		return
	var map_scene := load("res://scenes/ui/world_map.tscn") as PackedScene
	world_map = map_scene.instantiate()
	add_child(world_map)
	world_map.level_selected.connect(_on_map_level_selected)
	world_map.closed.connect(_on_map_closed)

func _on_map_closed() -> void:
	if world_map != null:
		world_map.queue_free()
		world_map = null

func _on_map_level_selected(level_id: String) -> void:
	if game_started:
		return
	_on_map_closed()
	game_started = true
	GameState.reset_for_new_game()
	GameState.highest_order_reached = SaveManager.peek_highest_order_reached()
	_free_menu()
	GameState.current_level_id = level_id
	GameState.level_begun.emit(level_id)
	load_level(level_id)

func _free_menu() -> void:
	var menu := get_node_or_null("MainMenu")
	if menu != null:
		menu.queue_free()

func show_intro_cinematic() -> void:
	hud.visible = false
	var intro_scene := load("res://scenes/cinematics/intro_cinematic.tscn") as PackedScene
	intro_cinematic = intro_scene.instantiate()
	add_child(intro_cinematic)
	intro_cinematic.finished.connect(_on_intro_finished)

func _on_intro_finished() -> void:
	if intro_cinematic != null:
		intro_cinematic.queue_free()
		intro_cinematic = null
	GameState.has_seen_intro = true
	GameState.current_level_id = "world_1_level_1"
	SaveManager.save_game()
	GameState.level_begun.emit("world_1_level_1")
	load_level("world_1_level_1")

func show_final_cinematic() -> void:
	hud.visible = false
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
	hud.visible = true

func _on_level_completed(level_id: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	if level_id == "world_4_boss":
		# La cinemática final decide cuándo terminar (el jugador la mira o
		# se auto-completa); _on_final_finished() se encarga de cargar
		# final_screen cuando corresponda, no hay transición genérica acá.
		show_final_cinematic()
		is_transitioning = false
		return
	var next_level_id := LevelProgression.get_next_level(level_id)
	await transition.play_completion(next_level_id)
	if not next_level_id.is_empty() and not LevelProgression.get_scene_path(next_level_id).is_empty():
		GameState.prepare_next_level()
		load_level(next_level_id)
		transition.fade_out()
	is_transitioning = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused

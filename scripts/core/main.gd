extends Node

@onready var level_container: Node = $LevelContainer
@onready var transition: CanvasLayer = $LevelTransition
@onready var hud: CanvasLayer = $HUD

var active_level: Node
var is_transitioning := false
var game_started := false
var intro_cinematic: Node = null
var final_cinematic: Node = null
var world1_cheer_screen: Node = null
var world_map: Node = null

func _ready() -> void:
	hud.visible = false
	GameState.level_completed.connect(_on_level_completed)
	GameState.has_seen_intro = SaveManager.peek_has_seen_intro()
	GameState.has_seen_world1_cheer = SaveManager.peek_has_seen_world1_cheer()
	GameState.highest_order_reached = SaveManager.peek_highest_order_reached()
	var menu := get_node_or_null("MainMenu")
	if menu != null:
		menu.new_game_requested.connect(start_game)
		menu.continue_requested.connect(_on_continue_requested)
		menu.password_requested.connect(_on_password_requested)
		menu.map_requested.connect(_on_map_requested)
		AudioDirector.play_music("menu")
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
		await transition.fade_to_black()
		load_level("world_1_level_1")
		await transition.fade_from_black()
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
	await transition.fade_to_black()
	load_level(GameState.current_level_id)
	await transition.fade_from_black()

func _on_password_requested(level_id: String) -> void:
	if game_started:
		return
	game_started = true
	GameState.reset_for_new_game()
	_free_menu()
	GameState.current_level_id = level_id
	GameState.level_begun.emit(level_id)
	await transition.fade_to_black()
	load_level(level_id)
	await transition.fade_from_black()

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
	await transition.fade_to_black()
	load_level(level_id)
	await transition.fade_from_black()

func _free_menu() -> void:
	var menu := get_node_or_null("MainMenu")
	if menu != null:
		menu.queue_free()

func show_intro_cinematic() -> void:
	hud.visible = false
	AudioDirector.play_music("intro")
	await transition.fade_to_black()
	var intro_scene := load("res://scenes/cinematics/intro_cinematic.tscn") as PackedScene
	intro_cinematic = intro_scene.instantiate()
	add_child(intro_cinematic)
	intro_cinematic.finished.connect(_on_intro_finished)
	await transition.fade_from_black()

func _on_intro_finished() -> void:
	await transition.fade_to_black()
	if intro_cinematic != null:
		intro_cinematic.queue_free()
		intro_cinematic = null
	GameState.has_seen_intro = true
	GameState.current_level_id = "world_1_level_1"
	SaveManager.save_game()
	GameState.level_begun.emit("world_1_level_1")
	load_level("world_1_level_1")
	await transition.fade_from_black()

## Pantalla única (no se repite en partidas siguientes) con los 7 niños
## alentando a Luke, mostrada al completar el Mundo 1 antes de pasar al
## Mundo 2. Mismo criterio de "solo una vez" que la cinemática de inicio.
func show_world1_cheer_screen() -> void:
	hud.visible = false
	AudioDirector.play_music("final")
	await transition.fade_to_black()
	var scene := load("res://scenes/cinematics/world1_cheer_screen.tscn") as PackedScene
	world1_cheer_screen = scene.instantiate()
	add_child(world1_cheer_screen)
	world1_cheer_screen.finished.connect(_on_world1_cheer_finished)
	await transition.fade_from_black()

func _on_world1_cheer_finished() -> void:
	if world1_cheer_screen != null:
		world1_cheer_screen.queue_free()
		world1_cheer_screen = null
	GameState.has_seen_world1_cheer = true
	SaveManager.save_game()
	await _advance_after_level("world_1_boss")
	is_transitioning = false

func show_final_cinematic() -> void:
	hud.visible = false
	AudioDirector.play_music("final")
	await transition.fade_to_black()
	var cinematic_scene := load("res://scenes/cinematics/final_cinematic.tscn") as PackedScene
	final_cinematic = cinematic_scene.instantiate()
	add_child(final_cinematic)
	final_cinematic.finished.connect(_on_final_finished)
	await transition.fade_from_black()

func _on_final_finished() -> void:
	await transition.fade_to_black()
	if final_cinematic != null:
		final_cinematic.queue_free()
		final_cinematic = null
	load_level("final_screen")
	await transition.fade_from_black()

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
	_update_music_for_level(level_id)

## La música de cada mundo se elige por el mundo del nivel (LevelProgression),
## con pista propia y mas tenebrosa para las peleas de jefe, y 3 variantes
## para el Mundo 4 según el sub-ambiente (selva/mar/India). "final_screen"
## comparte la pista triunfal con las cinemáticas de cierre.
func _update_music_for_level(level_id: String) -> void:
	if level_id == "final_screen":
		AudioDirector.play_music("final")
		return
	if level_id.ends_with("_boss"):
		AudioDirector.play_music("boss")
		return
	match level_id:
		"world_4_level_1":
			AudioDirector.play_music("world4_selva")
			return
		"world_4_level_2":
			AudioDirector.play_music("world4_mar")
			return
		"world_4_level_3":
			AudioDirector.play_music("world4_india")
			return
	var world := LevelProgression.get_world(level_id)
	if world >= 1 and world <= 3:
		AudioDirector.play_music("world%d" % world)

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
	if level_id == "world_1_boss" and not GameState.has_seen_world1_cheer:
		show_world1_cheer_screen()
		return
	await _advance_after_level(level_id)
	is_transitioning = false

func _advance_after_level(level_id: String) -> void:
	var next_level_id := LevelProgression.get_next_level(level_id)
	await transition.play_completion(next_level_id)
	if not next_level_id.is_empty() and not LevelProgression.get_scene_path(next_level_id).is_empty():
		GameState.prepare_next_level()
		load_level(next_level_id)
		transition.fade_out()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
		AudioDirector.play_event(&"pause")

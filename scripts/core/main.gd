extends Node

@onready var level_container: Node = $LevelContainer
@onready var transition: CanvasLayer = $LevelTransition
@onready var hud: CanvasLayer = $HUD
@onready var pause_screen: CanvasLayer = $PauseScreen

var active_level: Node
var is_transitioning := false
var game_started := false
var intro_cinematic: Node = null
var final_cinematic: Node = null
var world1_cheer_screen: Node = null
var world_map: Node = null
var album_screen: Node = null
var game_over_screen: Node = null
var shop_screen: Node = null
## B1: bonus secreto de cavar, activo mientras Luke esta adentro.
var active_bonus: Node = null
var _bonus_return_position := Vector2.ZERO

func _ready() -> void:
	# Punto 1: TouchControls lo busca para saber si hay partida en curso.
	add_to_group("main_game")
	hud.visible = false
	pause_screen.resume_requested.connect(func() -> void: set_paused(false))
	pause_screen.exit_requested.connect(_on_pause_exit_requested)
	GameState.level_completed.connect(_on_level_completed)
	GameState.out_of_lives.connect(_on_out_of_lives)
	GameState.has_seen_intro = SaveManager.peek_has_seen_intro()
	GameState.has_seen_world1_cheer = SaveManager.peek_has_seen_world1_cheer()
	GameState.highest_order_reached = SaveManager.peek_highest_order_reached()
	var menu := get_node_or_null("MainMenu")
	if menu != null:
		menu.new_game_requested.connect(start_game)
		menu.continue_requested.connect(_on_continue_requested)
		menu.password_requested.connect(_on_password_requested)
		menu.map_requested.connect(_on_map_requested)
		menu.album_requested.connect(_on_album_requested)
		if TapToStart.needed():
			# Punto 1: en el navegador el audio arranca recien con el
			# primer toque; la musica del menu espera a ese toque.
			var tap := TapToStart.new()
			tap.name = "TapToStart"
			add_child(tap)
			tap.started.connect(func() -> void:
				AudioDirector.play_music("menu")
				_start_from_url_password())
		else:
			AudioDirector.play_music("menu")
	else:
		start_game()

## Punto de entrada de "COMENZAR JUEGO" (partida nueva desde cero).
## Se mantiene con este nombre porque la suite de tests automatizados
## del proyecto (tests/integration_*_test.gd) lo llama directamente (sin
## argumento, de ahi el default "normal" -- A4 solo agrega la dificultad
## elegida en el selector nuevo del menu, no cambia este contrato).
## "COMENZAR JUEGO" siempre muestra la cinemática de introducción: es una
## partida nueva explícita, no debe depender de si algún guardado previo
## (incluida una corrida de tests) ya marcó has_seen_intro en true.
func start_game(difficulty: String = "normal") -> void:
	if game_started:
		return
	game_started = true
	GameState.reset_for_new_game(difficulty)
	_free_menu()
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
	await show_shop_if_needed(GameState.current_level_id)
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
	await show_shop_if_needed(level_id)
	load_level(level_id)
	await transition.fade_from_black()

## Web: index.html?nivel=PERRO8 entra directo al nivel de esa contraseña
## (lo mismo que escribirla en CONTRASEÑA, sin el teclado). Sirve para probar
## un nivel en el celular y para las mediciones de tests/web_browser_test.mjs.
func _start_from_url_password() -> void:
	if not OS.has_feature("web"):
		return
	var code: Variant = JavaScriptBridge.eval("new URLSearchParams(location.search).get('nivel') || ''", true)
	var level_id := LevelProgression.get_level_id_from_password(str(code))
	if not level_id.is_empty():
		_on_password_requested(level_id)

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

## A7: mismo patron que el mapa del mundo -- se superpone al menu, "VOLVER"
## lo cierra sin perder el menu de fondo.
func _on_album_requested() -> void:
	if album_screen != null:
		return
	var album_scene := load("res://scenes/ui/album_screen.tscn") as PackedScene
	album_screen = album_scene.instantiate()
	add_child(album_screen)
	album_screen.closed.connect(_on_album_closed)

func _on_album_closed() -> void:
	if album_screen != null:
		album_screen.queue_free()
		album_screen = null

## B1: reparenta al Luke REAL (mismas estadisticas/cosmeticos, no una copia)
## adentro del nivel bonus. El nivel de origen se desactiva entero
## (process_mode=DISABLED, congela villanos/plataformas moviles/timers) y se
## oculta mientras tanto, para que no siga de fondo.
func _on_bonus_requested(bonus_scene_path: String, return_position: Vector2) -> void:
	if active_bonus != null or active_level == null:
		return
	var luke: Luke = active_level.get_node_or_null("Luke")
	if luke == null:
		return
	var bonus_scene := load(bonus_scene_path) as PackedScene
	if bonus_scene == null:
		return
	_bonus_return_position = return_position
	active_bonus = bonus_scene.instantiate()
	add_child(active_bonus)
	active_level.process_mode = Node.PROCESS_MODE_DISABLED
	active_level.visible = false
	active_level.remove_child(luke)
	# El nivel real de Luke (Camera2D propia, con limit_left/right/top/bottom
	# calculados para ESE nivel) no sirve adentro del bonus -- se apaga y la
	# camara propia del bonus (BonusLevel.camera) toma el control.
	var luke_camera: Camera2D = luke.get_node_or_null("Camera2D")
	if luke_camera != null:
		luke_camera.enabled = false
	active_bonus.add_child(luke)
	active_bonus.start(luke)
	active_bonus.finished.connect(_on_bonus_finished)

func _on_bonus_finished() -> void:
	if active_bonus == null or active_level == null:
		return
	var luke: Luke = active_bonus.get_node("Luke") as Luke
	active_bonus.remove_child(luke)
	active_level.add_child(luke)
	luke.global_position = _bonus_return_position
	luke.velocity = Vector2.ZERO
	luke.jumps_used = 0
	var luke_camera: Camera2D = luke.get_node_or_null("Camera2D")
	if luke_camera != null:
		luke_camera.enabled = true
		luke_camera.make_current()
	active_level.process_mode = Node.PROCESS_MODE_INHERIT
	active_level.visible = true
	active_bonus.queue_free()
	active_bonus = null

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
	await show_shop_if_needed(level_id)
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
	# E5: ya no hay "final_screen" despues de la cinematica (ahora se juega
	# el minijuego ANTES, ver _on_level_completed) -- esto es el final real
	# del juego, asi que se limpia el nivel/HUD y se muestra el cartel de
	# cierre encima de donde quedo la cinematica (nunca solo, sobre negro) y
	# despues se vuelve al menu en vez de dejar la pantalla trabada.
	if active_level != null:
		active_level.queue_free()
		active_level = null
	hud.visible = false
	await transition.play_completion("")
	await get_tree().create_timer(2.5).timeout
	get_tree().reload_current_scene()

func load_level(level_id: String) -> void:
	var scene_path := LevelProgression.get_scene_path(level_id)
	if scene_path.is_empty():
		return
	if active_level != null:
		active_level.queue_free()
	var packed_scene := load(scene_path) as PackedScene
	active_level = packed_scene.instantiate()
	level_container.add_child(active_level)
	if active_level is LevelBase:
		active_level.bonus_requested.connect(_on_bonus_requested)
	hud.visible = true
	GameState.clear_out_of_lives()
	if get_tree().paused:
		set_paused(false)
	_update_music_for_level(level_id)

## D1: cada uno de los 16 niveles jugables tiene su PROPIA pista (antes
## compartian una sola por mundo, mas una "boss" generica para los 4 jefes).
## Las de un mismo mundo son la misma familia de instrumentos/tonalidad
## (generadas juntas, ver D1 en el resumen); el jefe de cada mundo usa la
## version mas rapida y oscura de esa familia. "final_screen" sigue
## compartiendo la pista triunfal con las cinematicas de cierre.
func _update_music_for_level(level_id: String) -> void:
	if level_id == "final_screen":
		AudioDirector.play_music("final")
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
		"world_4_boss":
			AudioDirector.play_music("world4_boss")
			return
	var world := LevelProgression.get_world(level_id)
	var order := LevelProgression.get_order(level_id)
	if world < 1 or world > 4:
		return
	if order >= 4:
		AudioDirector.play_music("world%d_boss" % world)
	else:
		AudioDirector.play_music("world%d_level%d" % [world, order])

func _on_level_completed(level_id: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	if level_id == "world_1_boss" and not GameState.has_seen_world1_cheer:
		show_world1_cheer_screen()
		return
	# E5: orden correcto es minijuego de abrazos -> cinemática final (sus 2
	# paneles) -> fin. Antes la cinemática se mostraba ANTES de "final_screen"
	# (al vencer a world_4_boss) y, al completar el minijuego, caía en el
	# flujo genérico de _advance_after_level con next_level_id vacío, que
	# mostraba el cartel "¡JUEGO COMPLETADO!" y nunca llamaba a fade_out()
	# (solo pasa dentro del "if not next_level_id.is_empty()"), quedando
	# una pantalla negra trabada para siempre. world_4_boss ahora sigue el
	# flujo normal (su "next" en LevelProgression ya es "final_screen"), y
	# recién al completar "final_screen" se dispara la cinemática real.
	if level_id == "final_screen":
		show_final_cinematic()
		is_transitioning = false
		return
	await _advance_after_level(level_id)
	is_transitioning = false

func _advance_after_level(level_id: String) -> void:
	var next_level_id := LevelProgression.get_next_level(level_id)
	await transition.play_completion(next_level_id)
	if not next_level_id.is_empty() and not LevelProgression.get_scene_path(next_level_id).is_empty():
		GameState.prepare_next_level()
		await show_shop_if_needed(next_level_id)
		load_level(next_level_id)
		transition.fade_out()

## C3: la tienda aparece antes de cada nivel a partir del nivel 2 (orden
## global 2 a 16). Se dibuja en una capa por encima del fundido negro de la
## transicion, asi que el nivel siguiente queda tapado hasta que el jugador
## decide entrar. Siempre se puede saltear con "JUGAR EL NIVEL".
func should_show_shop(level_id: String) -> bool:
	return LevelProgression.get_global_order(level_id) >= 2

func show_shop_if_needed(level_id: String) -> void:
	if not should_show_shop(level_id) or shop_screen != null:
		return
	hud.visible = false
	AudioDirector.play_music("menu")
	var scene := load("res://scenes/ui/shop_screen.tscn") as PackedScene
	shop_screen = scene.instantiate()
	add_child(shop_screen)
	shop_screen.setup(level_id)
	await shop_screen.closed
	shop_screen.queue_free()
	shop_screen = null

## B4: ESC pausa y despausa DURANTE LA PARTIDA. Solo tiene efecto si hay un
## nivel cargado (en el menu, el mapa o las cinematicas no hace nada, para no
## dejar el juego pausado en una pantalla sin cartel de pausa que lo explique).
## Main ya corre con process_mode = ALWAYS, asi que sigue recibiendo el input
## con el arbol pausado y se puede volver a apretar ESC para reanudar.
## C1: al perder la ultima vida se sale del nivel a una pantalla negra con
## CONTINUAR (reinicia ESTE nivel con 3 vidas, gastando uno de los 3 continues
## de la partida) y GAME OVER (vuelve al menu principal). Si no quedan
## continues, CONTINUAR aparece deshabilitado.
func _on_out_of_lives(level_id: String) -> void:
	if game_over_screen != null:
		return
	set_paused(false)
	hud.visible = false
	AudioDirector.stop_music()
	var scene := load("res://scenes/ui/game_over_screen.tscn") as PackedScene
	game_over_screen = scene.instantiate()
	add_child(game_over_screen)
	game_over_screen.setup(GameState.continues_left)
	game_over_screen.continue_requested.connect(_on_continue_level.bind(level_id))
	game_over_screen.game_over_requested.connect(_on_return_to_main_menu)

func _on_continue_level(level_id: String) -> void:
	if not GameState.use_continue():
		return
	_free_game_over_screen()
	await transition.fade_to_black()
	load_level(level_id)
	await transition.fade_from_black()

func _on_return_to_main_menu() -> void:
	_free_game_over_screen()
	GameState.clear_out_of_lives()
	get_tree().paused = false
	AudioDirector.stop_music()
	get_tree().reload_current_scene()

func _free_game_over_screen() -> void:
	if game_over_screen != null:
		game_over_screen.queue_free()
		game_over_screen = null

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if active_level == null or not is_instance_valid(active_level):
		return
	set_paused(not get_tree().paused)

func set_paused(value: bool) -> void:
	get_tree().paused = value
	if pause_screen != null:
		if value:
			pause_screen.show_paused()
		else:
			pause_screen.hide_paused()
	AudioDirector.play_event(&"pause")

## F6: "SALIR AL MENU PRINCIPAL" desde la pausa. Mismo patron que
## _on_return_to_main_menu() (game over): recargar la escena deja todo en
## un estado limpio y conocido -- GameState (autoload) sobrevive la
## recarga, asi que el progreso guardado no se pierde, solo se sale del
## nivel actual sin guardarlo (igual que cerrar y volver a abrir el menu).
func _on_pause_exit_requested() -> void:
	pause_screen.hide_paused()
	get_tree().paused = false
	AudioDirector.stop_music()
	get_tree().reload_current_scene()

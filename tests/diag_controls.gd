extends Node2D

## B4 + B5: controles y latencia del golpe.
##
## B4: la tecla de ataque pasa de J a Ctrl y ESC pausa/reanuda durante la
##     partida.
## B5: el golpe tiene que salir en el mismo frame en que se aprieta la tecla.
##     Antes, con el huesito desbloqueado, cada toque simple esperaba los
##     0.28s de la ventana de doble tap (17 frames) antes de pegar.

const LUKE_SCENE := preload("res://scenes/player/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/thief.tscn")
const MAIN_SCENE := preload("res://scenes/main.tscn")

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	_check_input_map()
	await _check_attack_latency(false)
	await _check_attack_latency(true)
	await _check_double_tap()
	await _check_pause()
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _check_input_map() -> void:
	var attack_keys: Array[int] = []
	for event in InputMap.action_get_events("attack"):
		if event is InputEventKey:
			attack_keys.append(event.physical_keycode if event.physical_keycode != 0 else event.keycode)
	_check(attack_keys.has(KEY_CTRL), "B4: 'attack' esta mapeado a Ctrl (keycode %d) -> %s" % [KEY_CTRL, str(attack_keys)])
	_check(not attack_keys.has(KEY_J), "B4: 'attack' ya NO esta mapeado a J")
	var pause_keys: Array[int] = []
	for event in InputMap.action_get_events("pause"):
		if event is InputEventKey:
			pause_keys.append(event.physical_keycode if event.physical_keycode != 0 else event.keycode)
	_check(pause_keys.has(KEY_ESCAPE), "B4: 'pause' esta mapeado a ESC -> %s" % str(pause_keys))

func _build_arena() -> Node2D:
	var arena := Node2D.new()
	add_child(arena)
	var ground := StaticBody2D.new()
	ground.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(2000.0, 80.0)
	shape.shape = rect
	ground.add_child(shape)
	ground.position = Vector2(500.0, 940.0)
	arena.add_child(ground)
	return arena

## Cuenta frames desde que se aprieta "attack" hasta que el enemigo recibe el
## golpe. 0 = mismo frame.
func _check_attack_latency(bone_unlocked: bool) -> void:
	var previous := GameState.bone_throw_unlocked
	GameState.bone_throw_unlocked = bone_unlocked
	var arena := _build_arena()
	var luke: Luke = LUKE_SCENE.instantiate()
	luke.position = Vector2(500.0, 850.0)
	arena.add_child(luke)
	var enemy: EnemyBase = ENEMY_SCENE.instantiate()
	enemy.position = Vector2(560.0, 850.0)
	enemy.set_physics_process(false)
	arena.add_child(enemy)
	for i in range(10):
		await get_tree().physics_frame
	luke.facing_direction = 1
	var latency := -1
	Input.action_press("attack")
	for i in range(40):
		await get_tree().physics_frame
		if i == 0:
			Input.action_release("attack")
		if not is_instance_valid(enemy):
			latency = i
			break
	_check(latency >= 0 and latency <= 1,
		"B5: con huesito %s el golpe impacta a los %d frames (%.0f ms)" % [
			"DESBLOQUEADO" if bone_unlocked else "bloqueado", latency, latency * 1000.0 / 60.0])
	arena.queue_free()
	await get_tree().process_frame
	GameState.bone_throw_unlocked = previous

## El doble tap sigue lanzando el huesito.
func _check_double_tap() -> void:
	var previous := GameState.bone_throw_unlocked
	GameState.bone_throw_unlocked = true
	var arena := _build_arena()
	var luke: Luke = LUKE_SCENE.instantiate()
	luke.position = Vector2(500.0, 850.0)
	arena.add_child(luke)
	for i in range(10):
		await get_tree().physics_frame
	Input.action_press("attack")
	await get_tree().physics_frame
	Input.action_release("attack")
	await get_tree().physics_frame
	Input.action_press("attack")
	await get_tree().physics_frame
	Input.action_release("attack")
	for i in range(6):
		await get_tree().physics_frame
	var bones := 0
	for child in arena.get_children():
		if child is ThrownBone:
			bones += 1
	_check(bones >= 1, "B5: el doble tap sigue lanzando el huesito (%d huesitos)" % bones)
	arena.queue_free()
	await get_tree().process_frame
	GameState.bone_throw_unlocked = previous

## ESC pausa y vuelve a apretarse para reanudar, con cartel de PAUSA visible.
func _check_pause() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame
	main.start_game()
	# Los fundidos de transicion son tweens reales, asi que hay que darles
	# tiempo de verdad antes de dar por cargado el nivel.
	for i in range(90):
		await get_tree().process_frame
	# Saltea la cinematica de intro para llegar al nivel.
	if main.intro_cinematic != null:
		main._on_intro_finished()
	for i in range(150):
		await get_tree().process_frame
	var pause_screen: CanvasLayer = main.get_node("PauseScreen")
	_check(main.active_level != null, "B4: hay un nivel cargado para probar la pausa")
	_check(not get_tree().paused, "B4: el juego arranca sin pausa")
	main.set_paused(true)
	await get_tree().process_frame
	_check(get_tree().paused and pause_screen.visible, "B4: ESC pausa y muestra el cartel de PAUSA")
	main.set_paused(false)
	await get_tree().process_frame
	_check(not get_tree().paused and not pause_screen.visible, "B4: volver a apretar ESC reanuda y oculta el cartel")
	get_tree().paused = false
	main.queue_free()
	await get_tree().process_frame

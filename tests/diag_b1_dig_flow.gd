extends Node2D

## B1: flujo completo del pozo de cavar, con el Main real.
##  1. Pararse sobre el pozo y atacar 3 veces entra al bonus.
##  2. Adentro del bonus, caer (tocar FallBoundary) termina el bonus SIN
##     perder vida, y Luke vuelve EXACTO a donde cavo.
##  3. El pozo queda "usado" (el monticulo con el hueso desaparece, queda el
##     agujero) y ya no se puede volver a entrar con 3 golpes mas.
##  4. Eso se guarda con la partida.
##  5. Perder TODAS las vidas y volver con CONTINUAR reactiva el pozo
##     (unicamente ese camino, no un respawn normal).

const MAIN_SCENE := preload("res://scenes/main.tscn")

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _wait(frames: int) -> void:
	for i in range(frames):
		await get_tree().physics_frame

func _ready() -> void:
	await _run()
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _run() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	add_child(main)
	await _wait(5)
	main.start_game()
	await _wait(90)
	if main.intro_cinematic != null:
		main._on_intro_finished()
	await _wait(150)

	# Saltar directo a world_1_level_2 (tiene el pozo), sin pasar por la
	# tienda (no es lo que esta prueba quiere verificar).
	main.queue_free()
	await _wait(3)
	GameState.reset_for_new_game()
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await _wait(5)
	GameState.current_level_id = "world_1_level_2"
	main.load_level("world_1_level_2")
	await _wait(10)

	var level: Node = main.active_level
	_check(level != null, "arranca en world_1_level_2")
	var dig: DigSpot = level.get_node_or_null("DigSpot")
	_check(dig != null, "world_1_level_2 tiene el DigSpot")
	if dig == null:
		main.queue_free()
		return

	var luke: Luke = level.get_node("Luke")
	luke.global_position = dig.global_position
	luke.velocity = Vector2.ZERO
	await _wait(5)
	# La referencia real es donde Luke QUEDA PARADO (tras asentarse con la
	# gravedad), no el origen del propio nodo DigSpot -- son parecidos pero
	# no identicos, y dig_spot.gd reporta la posicion real de Luke, no la
	# suya propia.
	var dig_pos := luke.global_position

	# 3 golpes.
	for i in range(3):
		luke.attack_started.emit()
		await _wait(8)
	_check(main.active_bonus != null, "al 3er golpe se activa el bonus (main.active_bonus != null)")
	_check(not level.visible, "el nivel real se oculta mientras dura el bonus")
	_check(GameState.is_dig_spot_used("world_1_level_2"), "GameState ya marca el pozo como usado")

	if main.active_bonus != null:
		var bonus_luke: Luke = main.active_bonus.get_node("Luke")
		_check(bonus_luke == luke, "el Luke DENTRO del bonus es el mismo nodo (no una copia)")
		# Forzar una caida: teletransportar a Luke a la zona del FallBoundary.
		var fb: Area2D = main.active_bonus.get_node("FallBoundary")
		bonus_luke.global_position = fb.global_position
		# Medir la posicion en el MISMO frame en que el bonus termina (antes
		# de que la gravedad normal del juego, ya en marcha de nuevo, lo
		# asiente el resto del camino hacia el piso real -- eso es normal
		# despues de CUALQUIER teletransporte, no lo que esta prueba quiere
		# medir).
		var dist_at_return := -1.0
		for i in range(40):
			await get_tree().physics_frame
			if main.active_bonus == null:
				dist_at_return = luke.global_position.distance_to(dig_pos)
				break
		_check(main.active_bonus == null, "al caer, el bonus termina solo")
		_check(GameState.lives == 3, "caer en el bonus NO le costo ninguna vida (sigue en %d)" % GameState.lives)
		_check(level.visible, "el nivel real vuelve a estar visible")
		_check(dist_at_return >= 0.0 and dist_at_return < 5.0,
			"Luke vuelve EXACTO a donde cavo (dist=%.1f)" % dist_at_return)
		await _wait(10)

	# El pozo ya usado: 3 golpes mas NO vuelven a activar el bonus.
	for i in range(3):
		luke.attack_started.emit()
		await _wait(8)
	_check(main.active_bonus == null, "un pozo ya usado no se puede volver a activar con mas golpes")

	# Guardar/cargar: el pozo sigue usado.
	GameState.current_level_id = "world_1_level_2"
	SaveManager.save_game()
	var was_used := GameState.is_dig_spot_used("world_1_level_2")
	GameState.dig_spots_used.clear()
	SaveManager.load_game()
	_check(was_used and GameState.is_dig_spot_used("world_1_level_2"),
		"el pozo usado se guarda y se restaura al cargar la partida")

	# CONTINUAR (perder TODAS las vidas) reactiva el pozo de ESE nivel.
	GameState.continues_left = 3
	GameState.lives = 1
	GameState.current_level_id = "world_1_level_2"
	GameState.lose_life()
	var ok := GameState.use_continue()
	_check(ok, "use_continue() funciona (quedaban continues)")
	_check(not GameState.is_dig_spot_used("world_1_level_2"),
		"CONTINUAR reactiva el pozo del nivel donde se perdieron todas las vidas")

	main.queue_free()

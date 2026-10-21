extends Node2D

## E4: el minijuego final debia depender del medidor de amor al agotarse el
## reloj (antes completaba el nivel SIEMPRE, sin importar cuanta gente se
## hubiera abrazado). Verifica con fisica real (sin inputs forzados a mano,
## usando Input.action_press/release reales) los dos casos pedidos:
##  A) Luke quieto todo el tiempo -> debe terminar en "reintentar", nunca
##     debe emitirse GameState.level_completed.
##  B) Luke corre y abraza suficiente gente (>= umbral) antes de que se
##     acabe el tiempo -> debe completarse normalmente.

const LEVEL := preload("res://scenes/levels/final_screen.tscn")

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	await _scenario_stationary()
	await _scenario_hugging()
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _scenario_stationary() -> void:
	print("--- Escenario A: Luke quieto todo el minijuego ---")
	var level: HugMinigame = LEVEL.instantiate()
	add_child(level)
	var completed_emitted := [false]
	var on_completed := func(_id: String) -> void: completed_emitted[0] = true
	GameState.level_completed.connect(on_completed)
	print("total_people=", level.total_people, " umbral=", level._love_threshold(), " time_limit=", level.time_limit)
	Input.action_release("move_right")
	Input.action_release("move_left")
	Input.action_release("run")
	Input.action_release("jump")
	var frames := 0
	var max_frames: int = int(level.time_limit * 60.0) + 120
	while not level.minigame_over and frames < max_frames:
		await get_tree().physics_frame
		frames += 1
	_check(level.minigame_over, "A: el minijuego termina (no se queda esperando para siempre)")
	_check(level.hugged_count < level._love_threshold(),
		"A: quieto, los abrazos (%d) no llegan al umbral (%d)" % [level.hugged_count, level._love_threshold()])
	_check(not completed_emitted[0], "A: NO se emite GameState.level_completed (nivel no marcado completado)")
	_check(level.retry_hud != null and level.retry_hud.visible, "A: se muestra la pantalla de reintentar")
	GameState.level_completed.disconnect(on_completed)
	level.queue_free()
	await get_tree().process_frame

func _scenario_hugging() -> void:
	print("--- Escenario B: Luke corre y abraza suficiente gente ---")
	var level: HugMinigame = LEVEL.instantiate()
	add_child(level)
	var completed_emitted := [false]
	var on_completed := func(_id: String) -> void: completed_emitted[0] = true
	GameState.level_completed.connect(on_completed)
	var luke: Luke = level.luke
	var threshold: int = level._love_threshold()
	var frames := 0
	var max_frames: int = int(level.time_limit * 60.0) + 120
	Input.action_press("run")
	while not level.minigame_over and frames < max_frames:
		# Perseguir a la persona sin abrazar mas cercana (igual que un
		# jugador real: Luke se mueve hacia ella hasta tocarla).
		var target: HuggablePerson = null
		var best_dist := INF
		for person in level.people:
			if not is_instance_valid(person) or person.is_hugged:
				continue
			var d: float = person.global_position.distance_to(luke.global_position)
			if d < best_dist:
				best_dist = d
				target = person
		if target != null:
			if target.global_position.x > luke.global_position.x + 5.0:
				Input.action_release("move_left")
				Input.action_press("move_right")
			elif target.global_position.x < luke.global_position.x - 5.0:
				Input.action_release("move_right")
				Input.action_press("move_left")
			else:
				Input.action_release("move_right")
				Input.action_release("move_left")
		await get_tree().physics_frame
		frames += 1
		if level.hugged_count >= threshold and level.hugged_count >= 1 and frames % 30 == 0:
			pass
	Input.action_release("move_right")
	Input.action_release("move_left")
	Input.action_release("run")
	print("DEBUG B: frames=", frames, " minigame_over=", level.minigame_over,
		" is_level_complete=", GameState.is_level_complete,
		" completed_emitted=", completed_emitted[0], " time_left=", level.time_left)
	_check(level.hugged_count >= threshold,
		"B: se alcanzo el umbral persiguiendo gente (abrazados=%d, umbral=%d)" % [level.hugged_count, threshold])
	_check(level.minigame_over, "B: el minijuego termina")
	_check(completed_emitted[0], "B: SI se emite GameState.level_completed (nivel completado)")
	_check(level.retry_hud == null or not level.retry_hud.visible, "B: no se muestra la pantalla de reintentar")
	GameState.level_completed.disconnect(on_completed)
	level.queue_free()
	await get_tree().process_frame

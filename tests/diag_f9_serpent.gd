extends Node2D

## F9: verifica con fisica real que el jefe final (Serpiente) arranca
## parado en la plataforma mas alta de la arena (no se la puede golpear
## sin subir), que baja/persigue solo con su logica actual, y que la pelea
## sigue siendo ganable jugando de verdad (sin congelar al jefe, a
## diferencia de diag_e6_serpent_fight.gd que lo congela para medir danos
## exactos).

const LEVEL := preload("res://scenes/levels/world_4_boss.tscn")

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	await _check_start_position()
	await _check_winnable_melee()
	await _check_winnable_bone()
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _check_start_position() -> void:
	print("--- Posicion inicial ---")
	var level: Node = LEVEL.instantiate()
	add_child(level)
	await get_tree().physics_frame
	var boss: Node2D = level.get_node("SerpentBoss")
	var luke: Node2D = level.get_node("Luke")
	var platform_six: Node2D = level.get_node("PlatformSix")
	var start_dist_to_six: float = boss.global_position.distance_to(platform_six.global_position)
	_check(start_dist_to_six < 250.0, "la Serpiente arranca cerca de PlatformSix (la mas alta), distancia=%.0fpx" % start_dist_to_six)
	var luke_to_boss: float = luke.global_position.distance_to(boss.global_position)
	_check(luke_to_boss > 400.0, "Luke, en su spawn, esta lejos del jefe al arrancar (distancia=%.0fpx, su golpe llega a ~80px)" % luke_to_boss)

	# Dejar correr la pelea de verdad (sin congelar al jefe, sin que Luke se
	# mueva de su spawn) un rato largo: con su logica actual (carga
	# horizontal + salto continuo, sin logica de "ir hacia abajo" explicita)
	# tiene que terminar bajando de la plataforma alta en algun momento al
	# cargar fuera del borde y caer, no quedar pegada arriba para siempre.
	# Se mide el punto MAS BAJO alcanzado (Y mas grande), no la posicion
	# final, porque el salto continuo la hace rebotar: puede tocar abajo y
	# volver a subir.
	var max_y_seen: float = boss.global_position.y
	var start_y: float = boss.global_position.y
	for i in range(600):  # 10s reales
		await get_tree().physics_frame
		if is_instance_valid(boss):
			max_y_seen = maxf(max_y_seen, boss.global_position.y)
	var descended: float = max_y_seen - start_y
	_check(descended > 150.0, "la Serpiente baja de la plataforma alta por su cuenta en 10s reales, incluso con Luke quieto (bajo %.0fpx)" % descended)
	level.queue_free()
	await get_tree().process_frame

## Pelea de verdad (jefe sin congelar, con toda su IA activa: carga, salta,
## dispara) atacando solo cuerpo a cuerpo, persiguiendolo cuando haga
## falta. Confirma que la pelea sigue siendo ganable.
func _check_winnable_melee() -> void:
	print("--- Pelea real (sin congelar), solo cuerpo a cuerpo ---")
	var level: Node = LEVEL.instantiate()
	add_child(level)
	await get_tree().physics_frame
	var boss: Node2D = level.get_node("SerpentBoss")
	var luke: Luke = level.get_node("Luke")
	luke.has_invincibility = true
	var defeated := false
	var hits := 0
	for frame in range(3600):  # 60s reales como mucho
		if not is_instance_valid(boss) or boss.is_defeated:
			defeated = true
			break
		var dx: float = boss.global_position.x - luke.global_position.x
		var dy: float = boss.global_position.y - luke.global_position.y
		if absf(dx) > 15.0:
			if dx > 0:
				Input.action_release("move_left")
				Input.action_press("move_right")
			else:
				Input.action_release("move_right")
				Input.action_press("move_left")
			Input.action_press("run")
		else:
			Input.action_release("move_right")
			Input.action_release("move_left")
		if dy < -30.0 and luke.is_on_floor():
			Input.action_press("jump")
		else:
			Input.action_release("jump")
		if absf(dx) < 90.0 and not luke.is_attacking:
			Input.action_press("attack")
			hits += 1
		else:
			Input.action_release("attack")
		await get_tree().physics_frame
	Input.action_release("move_right")
	Input.action_release("move_left")
	Input.action_release("jump")
	Input.action_release("attack")
	_check(defeated, "la pelea real (cuerpo a cuerpo, persiguiendo al jefe) se puede ganar (intentos de golpe=%d)" % hits)
	level.queue_free()
	await get_tree().process_frame

func _check_winnable_bone() -> void:
	print("--- Pelea real (sin congelar), solo huesito a distancia ---")
	var level: Node = LEVEL.instantiate()
	add_child(level)
	await get_tree().physics_frame
	var boss: Node2D = level.get_node("SerpentBoss")
	var luke: Luke = level.get_node("Luke")
	luke.has_invincibility = true
	var defeated := false
	var hits := 0
	for frame in range(3600):
		if not is_instance_valid(boss) or boss.is_defeated:
			defeated = true
			break
		var dx: float = boss.global_position.x - luke.global_position.x
		var dy: float = boss.global_position.y - luke.global_position.y
		if absf(dx) > 15.0:
			if dx > 0:
				Input.action_release("move_left")
				Input.action_press("move_right")
			else:
				Input.action_release("move_right")
				Input.action_press("move_left")
			Input.action_press("run")
		else:
			Input.action_release("move_right")
			Input.action_release("move_left")
		if dy < -30.0 and luke.is_on_floor():
			Input.action_press("jump")
		else:
			Input.action_release("jump")
		if absf(dx) < 500.0 and not luke.is_throwing and frame % 20 == 0:
			hits += 1
			Input.action_press("attack")
			await get_tree().physics_frame
			Input.action_release("attack")
			continue
		await get_tree().physics_frame
	Input.action_release("move_right")
	Input.action_release("move_left")
	Input.action_release("jump")
	_check(defeated, "la pelea real (huesito a distancia, persiguiendo al jefe) se puede ganar (intentos de tiro=%d)" % hits)
	level.queue_free()
	await get_tree().process_frame

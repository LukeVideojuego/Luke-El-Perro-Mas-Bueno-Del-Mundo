extends Node2D

## E6: simulacion REAL de pelea completa contra la Serpiente (world_4_boss)
## para:
##  1) Medir cuantos golpes hacen falta para matarla, por separado con
##     cuerpo a cuerpo y con huesito (requisito: minimo 10 con cualquiera).
##  2) Medir lo mismo combinando ladrido de onda (5 cargas) + huesito, y
##     confirmar que la regla de "minimo 10 golpes solo con huesito" sigue
##     valiendo (no se puede evitar porque el daño de los 3 ataques es el
##     mismo, 1 de vida por golpe -- ver boss_hurtbox.gd).
##  3) Confirmar que las 3 cajas de vida extra y la caja del ladrido de
##     onda son alcanzables de verdad saltando por las plataformas reales
##     del nivel (no solo "existen en el .tscn").

const LEVEL_SCENE := preload("res://scenes/levels/world_4_boss.tscn")
const LUKE_SCENE := preload("res://scenes/player/player.tscn")

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	await _fight_melee_only()
	await _fight_bone_only()
	await _fight_bark_plus_bone()
	await _check_reachability()
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _spawn_level() -> Node:
	var level: Node = LEVEL_SCENE.instantiate()
	add_child(level)
	return level

func _boss_of(level: Node) -> BossBase:
	return level.get_node("SerpentBoss") as BossBase

func _luke_of(level: Node) -> Luke:
	return level.get_node("Luke") as Luke

## Deja quieto al jefe (no salta/no dispara) para que la medicion de golpes
## sea determinista, y para cuerpo a cuerpo posiciona a Luke pegado a su
## hurtbox real (mismo criterio que diag_boss_hurtbox.gd).
func _freeze_boss(boss: BossBase) -> void:
	boss.set_physics_process(false)
	boss.velocity = Vector2.ZERO

## Centro real de la hurtbox (misma tecnica que diag_boss_hurtbox.gd): la
## posicion del jefe en el nivel no tiene por que coincidir con el centro
## de su silueta/hurtbox, asi que apuntar con boss.global_position.y a
## secas puede terminar pegandole al aire.
func _hurtbox_center_y(boss: Node2D) -> float:
	var hurtbox: Area2D = boss.get_node_or_null("HurtBox")
	if hurtbox == null:
		return boss.global_position.y
	for child in hurtbox.get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			return child.global_position.y
	return boss.global_position.y

func _fight_melee_only() -> void:
	print("--- Pelea solo cuerpo a cuerpo ---")
	var level := _spawn_level()
	var boss := _boss_of(level)
	var luke := _luke_of(level)
	await get_tree().physics_frame
	_freeze_boss(boss)
	var max_health: int = boss.max_health
	luke.gravity = 0.0
	luke.position = Vector2(boss.global_position.x - 58.0 - 20.0, boss.global_position.y)
	luke.facing_direction = 1
	# Parado pegado al jefe, su DamageArea le pega a Luke (contacto) y sin
	# esto el primer golpe de la Serpiente ya dispara receive_damage() ->
	# defeated -> level_base._on_luke_defeated() -> respawn en el checkpoint
	# (lo saca de la pelea sin que importe lo que midamos nosotros). Es un
	# problema de ESTE arnes de prueba (en el juego real el jugador esquiva
	# o se re-acerca), no del balance del jefe -- se neutraliza con
	# invencibilidad para poder medir solo los golpes de Luke.
	luke.has_invincibility = true
	var hits := 0
	var defeated := false
	for attempt in range(40):
		if not is_instance_valid(boss) or boss.is_defeated:
			defeated = true
			break
		Input.action_press("attack")
		await get_tree().physics_frame
		Input.action_release("attack")
		hits += 1
		for i in range(14):
			await get_tree().physics_frame
			if not is_instance_valid(boss) or boss.is_defeated:
				break
	defeated = not is_instance_valid(boss) or boss.is_defeated
	print("MELEE: golpes necesarios para derrotarla = ", hits, " (vida maxima=", max_health, ")")
	_check(defeated, "melee: el jefe termina derrotado")
	_check(hits >= 10, "melee: hacen falta al menos 10 golpes (midio %d)" % hits)
	level.queue_free()
	await get_tree().process_frame

func _fight_bone_only() -> void:
	print("--- Pelea solo huesito ---")
	var level := _spawn_level()
	var boss := _boss_of(level)
	await get_tree().physics_frame
	_freeze_boss(boss)
	const BONE_SCENE := preload("res://scenes/objects/thrown_bone.tscn")
	var hits := 0
	var target_y: float = boss.global_position.y
	var target_x: float = boss.global_position.x
	for attempt in range(40):
		if not is_instance_valid(boss) or boss.is_defeated:
			break
		var bone := BONE_SCENE.instantiate()
		level.add_child(bone)
		bone.launch(Vector2(target_x - 320.0, target_y), 1.0, null)
		hits += 1
		for i in range(60):
			await get_tree().physics_frame
			if not is_instance_valid(bone):
				break
	var defeated := not is_instance_valid(boss) or boss.is_defeated
	print("HUESITO: golpes necesarios para derrotarla = ", hits)
	_check(defeated, "huesito: el jefe termina derrotado")
	_check(hits >= 10, "huesito: hacen falta al menos 10 golpes (midio %d)" % hits)
	level.queue_free()
	await get_tree().process_frame

## E6 (corrección pedida): el ladrido pega el TRIPLE que el huesito (3 de
## vida en vez de 1), para que valga la pena gastar una de las 5 cargas
## limitadas. Esta pelea mide: (a) el total de golpes usando las 5 cargas
## y despues huesito -- tiene que ser MENOS que los 15 de huesito solo,
## y (b) que el jefe NO caiga antes de la 5ta carga de ladrido (si
## cayera en la 4ta, el ladrido se habria vuelto demasiado fuerte).
func _fight_bark_plus_bone() -> void:
	print("--- Pelea combinada: ladrido de onda (5 cargas) + huesito ---")
	var level := _spawn_level()
	var boss := _boss_of(level)
	await get_tree().physics_frame
	_freeze_boss(boss)
	GameState.bark_ammo = 5
	const BONE_SCENE := preload("res://scenes/objects/thrown_bone.tscn")
	const BARK_SCENE := preload("res://scenes/objects/bark_wave.tscn")
	var hits := 0
	var bark_used := 0
	var defeated_before_5th_bark := false
	var target_y: float = boss.global_position.y
	var target_x: float = boss.global_position.x
	for attempt in range(40):
		if not is_instance_valid(boss) or boss.is_defeated:
			break
		var use_bark: bool = GameState.consume_bark()
		var projectile: Node2D = BARK_SCENE.instantiate() if use_bark else BONE_SCENE.instantiate()
		if use_bark:
			bark_used += 1
		level.add_child(projectile)
		projectile.launch(Vector2(target_x - 320.0, target_y), 1.0, null)
		hits += 1
		for i in range(60):
			await get_tree().physics_frame
			if not is_instance_valid(boss) or boss.is_defeated:
				break
			if use_bark and not is_instance_valid(projectile):
				break
		if use_bark and bark_used < 5 and (not is_instance_valid(boss) or boss.is_defeated):
			defeated_before_5th_bark = true
	var defeated := not is_instance_valid(boss) or boss.is_defeated
	print("COMBINADO: golpes totales = ", hits, " (", bark_used, " con ladrido, ", hits - bark_used, " con huesito)")
	_check(defeated, "combinado: el jefe termina derrotado")
	_check(bark_used == 5, "combinado: se gastaron las 5 cargas de ladrido (uso %d)" % bark_used)
	_check(hits < 15, "combinado: el total (%d golpes) es MENOR que pelear solo con huesito (15), confirmando que el ladrido pega mas fuerte" % hits)
	_check(not defeated_before_5th_bark, "el ladrido NO mata al jefe en menos de 5 usos (no murio antes de la carga numero 5)")
	level.queue_free()
	GameState.bark_ammo = 0
	await get_tree().process_frame

## Verifica que las 3 cajas de vida extra y la caja del ladrido sean
## alcanzables saltando de plataforma en plataforma de verdad. Misma tecnica
## que tests/diag_secret_life.gd (C2): cada TRAMO del camino se prueba en
## una arena aislada propia (solo esas 2 plataformas + piso de seguridad
## bien abajo), probando varios planes de input (caminar/correr, cuanto
## sostener la direccion, con o sin doble salto) hasta que alguno aterrice
## del otro lado -- mas confiable que mandar a Luke a caminar solo por el
## nivel entero de una, que se traba con el jefe/paredes en el camino.
const LUKE_GROUND_OFFSET := 50.0
const MOVEMENT_PROPS := [
	"walk_speed", "run_speed", "ground_acceleration", "ground_deceleration",
	"air_acceleration", "gravity", "jump_velocity", "double_jump_velocity",
	"max_fall_speed",
]
const PLANS := [
	{"run": false, "hold": 999, "dbl": false},
	{"run": true, "hold": 999, "dbl": false},
	{"run": false, "hold": 999, "dbl": true},
	{"run": true, "hold": 999, "dbl": true},
	{"run": true, "hold": 34, "dbl": true},
	{"run": false, "hold": 44, "dbl": true},
	{"run": true, "hold": 24, "dbl": true},
	{"run": false, "hold": 30, "dbl": true},
	{"run": true, "hold": 46, "dbl": true},
	{"run": false, "hold": 60, "dbl": true},
	{"run": true, "hold": 16, "dbl": true},
]

func _check_reachability() -> void:
	print("--- Alcanzabilidad de las cajas escondidas ---")
	var level := _spawn_level()
	await get_tree().physics_frame
	var luke_props := {}
	var level_luke: Node = level.get_node("Luke")
	for prop in MOVEMENT_PROPS:
		luke_props[prop] = level_luke.get(prop)

	# Nodo -> info de plataforma (centro+medio ancho/alto de su
	# CollisionShape2D rectangular), para las 6 plataformas de la arena y
	# para cada caja (tratada como una "plataforma" muy angosta a su propia
	# altura, el objetivo real es llegar a esa posicion, no pararse encima).
	var plat := {}
	for name in ["PlatformOne", "PlatformTwo", "PlatformThree", "PlatformFour", "PlatformFive", "PlatformSix", "StepStoneR1", "StepStoneR2", "StepStoneR3"]:
		plat[name] = _plat_info(level.get_node(name))
	var ground_shape: CollisionShape2D = level.get_node("Ground/CollisionShape2D")
	var ground_info := {
		"name": "Ground",
		"x": level.get_node("Ground").global_position.x + ground_shape.position.x,
		"y": level.get_node("Ground").global_position.y + ground_shape.position.y,
		"half_w": ground_shape.shape.size.x / 2.0,
		"half_h": ground_shape.shape.size.y / 2.0,
	}
	# Que caja esta "encima" de que plataforma (alcanzar la plataforma de
	# apoyo es lo que hace falta; las cajas se rompen de un golpe parado en
	# esa plataforma, igual que _check_break en diag_secret_life.gd -- no
	# hace falta "aterrizar" sobre la caja en si).
	var box_platform := {
		"SecretLifeBox": "PlatformSix",
		"SecretLifeBox2": "PlatformFour",
		"SecretLifeBox3": "PlatformFive",
		"BarkBox": "PlatformThree",
	}

	# Caminos reales de plataforma en plataforma, de piso a la plataforma de
	# apoyo de cada caja (hay mas de una ruta posible para algunas; alcanza
	# con que UNA funcione, como en el juego real).
	var paths := [
		["Ground", "StepStoneR1", "StepStoneR2", "StepStoneR3", "PlatformThree", "PlatformFour"],
		["Ground", "StepStoneR1", "StepStoneR2", "StepStoneR3", "PlatformThree", "PlatformFive"],
		["Ground", "StepStoneR1", "StepStoneR2", "StepStoneR3", "PlatformThree"],
		["Ground", "StepStoneR1", "StepStoneR2", "StepStoneR3", "PlatformThree", "PlatformFour", "PlatformSix"],
	]
	var box_names := ["SecretLifeBox2", "SecretLifeBox3", "BarkBox", "SecretLifeBox"]

	# CRITICO: liberar el nivel real ANTES de simular los saltos. _can_reach
	# arma su propia arena aislada con solo las 2 plataformas del tramo,
	# pero si el nivel real (con PlatformOne/Two etc. todavia fisicamente
	# presentes) sigue vivo en el arbol mientras tanto, Luke puede chocar
	# con esas plataformas REALES durante el salto simulado (confirmado:
	# el tramo StepStoneR3->PlatformThree aterrizaba sobre la PlatformTwo
	# real en vez de seguir de largo, porque el nivel todavia no se habia
	# liberado).
	level.queue_free()
	await get_tree().process_frame

	for i in range(paths.size()):
		var path: Array = paths[i]
		var box_name: String = box_names[i]
		var all_ok := true
		var how_summary := ""
		for j in range(path.size() - 1):
			var b: Dictionary = plat[path[j + 1]]
			# El piso es un StaticBody2D de 2000px, no una plataforma chica
			# pegada a la siguiente: un jugador real camina por el piso
			# hasta pararse DEBAJO del salto, no arranca desde el borde
			# fisico del nivel entero. Si el tramo sale del piso, se usa un
			# punto de partida angosto centrado bajo el destino (mismo piso,
			# misma altura), no el ground_info completo.
			var a: Dictionary = ground_info
			if path[j] == "Ground":
				# OJO: arrancar justo DEBAJO del centro del destino (x
				# identico) hace que el salto sea derecho hacia arriba y
				# Luke se golpea la cabeza contra el fondo de la plataforma
				# en vez de pasar al costado y aterrizar encima (confirmado
				# con un trace frame a frame: la velocidad vertical se
				# frena en seco a mitad de subida). Arrancando 150px al
				# costado, el salto es en diagonal y pasa el borde como
				# haria un jugador real.
				a = {"name": "Ground", "x": b.x - 150.0, "y": ground_info.y, "half_w": 40.0, "half_h": ground_info.half_h}
			else:
				a = plat[path[j]]
			var result := await _can_reach(a, b, luke_props)
			if not result.ok:
				all_ok = false
			how_summary += "%s->%s:%s  " % [path[j], path[j + 1], "OK" if result.ok else "FALLO"]
		_check(all_ok, "camino de plataformas hasta %s (plataforma %s): %s" % [
			box_name, box_platform[box_name], how_summary])

	for box_name in box_names:
		await _check_box_break(box_name)

func _plat_info(node: Node2D) -> Dictionary:
	var shape: CollisionShape2D = node.get_node("CollisionShape2D")
	return {
		"name": node.name,
		"x": node.global_position.x + shape.position.x,
		"y": node.global_position.y + shape.position.y,
		"half_w": shape.shape.size.x / 2.0,
		"half_h": shape.shape.size.y / 2.0,
	}

var _debug_reach := false

func _can_reach(a: Dictionary, b: Dictionary, props: Dictionary) -> Dictionary:
	var toward_right: bool = b.x >= a.x
	for plan_idx in range(PLANS.size()):
		var plan = PLANS[plan_idx]
		var arena := Node2D.new()
		add_child(arena)
		_make_platform(arena, a.x, a.y, a.half_w, a.half_h)
		_make_platform(arena, b.x, b.y, b.half_w, b.half_h)
		_make_platform(arena, (a.x + b.x) / 2.0, maxf(a.y, b.y) + 800.0, 6000.0, 40.0)
		var luke: Luke = LUKE_SCENE.instantiate()
		for prop in MOVEMENT_PROPS:
			luke.set(prop, props[prop])
		var edge: float = a.half_w - 12.0
		luke.position = Vector2(a.x + (edge if toward_right else -edge), a.y - a.half_h - LUKE_GROUND_OFFSET)
		arena.add_child(luke)
		luke.velocity = Vector2.ZERO
		var dir_action := "move_right" if toward_right else "move_left"
		var target_surface: float = b.y - b.half_h - LUKE_GROUND_OFFSET
		var landed := false
		var left_a := false
		for frame in range(1, 220):
			if frame <= 3 + int(plan.hold):
				Input.action_press(dir_action)
				if plan.run:
					Input.action_press("run")
			else:
				Input.action_release(dir_action)
				Input.action_release("run")
			if frame == 3:
				Input.action_press("jump")
			if frame == 4:
				Input.action_release("jump")
			if plan.dbl and frame == 26:
				Input.action_press("jump")
			if plan.dbl and frame == 27:
				Input.action_release("jump")
			await get_tree().physics_frame
			if frame > 5 and not luke.is_on_floor():
				left_a = true
			# frame>6 no alcanza de margen: recien saltando, is_on_floor()
			# puede "parpadear" true un frame (snap residual del motor) y
			# el chequeo de aterrizaje disparaba falso casi en el instante
			# de despegar (confirmado con un trace: "aterrizaba" a los 6-7
			# frames, a mitad de camino del primer salto, no de verdad
			# sobre el destino). Un salto real tarda bastante mas en volver
			# a tocar algo solido.
			if left_a and luke.is_on_floor() and frame > 15:
				landed = absf(luke.global_position.x - b.x) <= b.half_w + 4.0 \
					and absf(luke.global_position.y - target_surface) <= 6.0
				break
			# El margen de "se cayo, no va a llegar" tiene que ser mayor que
			# el salto vertical mas grande que se vaya a pedir ac en este
			# archivo (el de Ground a StepStoneA/B es de unos 240px) -- con
			# el margen original de 160px (pensado para las escaleras C2,
			# de rungs de ~130px) se abandonaba el intento ni bien Luke
			# despegaba, antes de que tuviera tiempo de subir.
			if left_a and luke.global_position.y > target_surface + 500.0:
				break
		Input.action_release(dir_action)
		Input.action_release("run")
		Input.action_release("jump")
		if _debug_reach:
			print("    plan=", plan_idx, " plan_data=", plan, " landed=", landed,
				" luke_final=", luke.global_position, " target_surface=", target_surface)
		arena.queue_free()
		await get_tree().process_frame
		if landed:
			return {"ok": true, "how": "%s%s" % [
				"correr" if plan.run else "caminar",
				" + doble salto" if plan.dbl else ""]}
	return {"ok": false, "how": "ningun plan de input funciono"}

func _make_platform(parent: Node2D, x: float, y: float, half_w: float, half_h: float) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(half_w * 2.0, half_h * 2.0)
	shape.shape = rect
	body.add_child(shape)
	body.position = Vector2(x, y)
	parent.add_child(body)

## Parado junto a la caja (misma tecnica que diag_secret_life.gd), un golpe
## la rompe y aparece lo que tiene adentro.
func _check_box_break(box_name: String) -> void:
	var level := _spawn_level()
	var boss := _boss_of(level)
	await get_tree().physics_frame
	_freeze_boss(boss)
	var box: Node2D = level.get_node_or_null(box_name)
	var luke := _luke_of(level)
	if box == null or luke == null:
		_check(false, "%s: existe para poder romperla" % box_name)
		level.queue_free()
		await get_tree().process_frame
		return
	luke.gravity = 0.0
	luke.has_invincibility = true
	luke.global_position = box.global_position - Vector2(90.0, 0.0)
	luke.velocity = Vector2.ZERO
	luke.facing_direction = 1
	await get_tree().physics_frame
	Input.action_press("attack")
	await get_tree().physics_frame
	Input.action_release("attack")
	for i in range(12):
		await get_tree().physics_frame
	var broken := not is_instance_valid(box)
	var is_life_box: bool = box_name.begins_with("SecretLifeBox")
	var spawned := 0
	for child in level.get_children():
		if is_life_box and child is ExtraLife:
			spawned += 1
		elif not is_life_box and child is BarkPickup:
			spawned += 1
	_check(broken and spawned == 1, "%s: el golpe la rompe y aparece lo que tiene adentro (rota=%s, items=%d)" % [
		box_name, broken, spawned])
	level.queue_free()
	await get_tree().process_frame

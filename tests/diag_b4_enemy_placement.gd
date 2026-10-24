extends Node2D

## B4: verifica que los 3 enemigos nuevos (SkaterThief, Scammer, ShieldGuard)
## esten bien colocados en los niveles reales: que caigan sobre piso solido
## (no en un pozo), que no queden trabados/parpadeando (velocidad y
## posicion se estabilizan, no quedan oscilando sin sentido), y de paso
## chequea las mecanicas propias: el escudo bloquea de frente y permite
## pisarlo por arriba, y la moneda falsa no suma monedas.

var fails := 0
var checks := 0

func _check(label: String, ok: bool) -> void:
	checks += 1
	if ok:
		print("OK: ", label)
	else:
		fails += 1
		print("FALLO: ", label)

func _wait(n: int) -> void:
	for i in range(n):
		await get_tree().physics_frame

func _ready() -> void:
	await _check_level_placements()
	await _test_shield_block_and_stomp()
	await _test_fake_coin_no_currency()
	print("RESULTADO: ", fails, " fallos de ", checks)
	get_tree().quit()

## Carga cada nivel real, espera a que los enemigos nuevos se asienten con
## la fisica real, y confirma que estan parados en el suelo (no cayendo
## indefinidamente por un pozo) y que la posicion se estabiliza (no quedan
## temblando/trabados contra un obstaculo).
func _check_level_placements() -> void:
	var targets := [
		{"level": "res://scenes/levels/world_1_level_2.tscn", "names": ["SkaterThiefOne", "SkaterThiefTwo"]},
		{"level": "res://scenes/levels/world_1_level_3.tscn", "names": ["SkaterThiefOne", "SkaterThiefTwo"]},
		{"level": "res://scenes/levels/world_2_level_2.tscn", "names": ["ScammerOne", "ScammerTwo"]},
		{"level": "res://scenes/levels/world_2_level_3.tscn", "names": ["ScammerOne", "ScammerTwo"]},
		{"level": "res://scenes/levels/world_3_level_2.tscn", "names": ["ShieldGuardOne", "ShieldGuardTwo"]},
		{"level": "res://scenes/levels/world_3_level_3.tscn", "names": ["ShieldGuardOne", "ShieldGuardTwo"]},
	]
	for t in targets:
		var level: Node2D = load(t.level).instantiate()
		add_child(level)
		await _wait(5)
		for n in t.names:
			var enemy = level.get_node_or_null(n)
			if enemy == null:
				_check("%s / %s existe en el nivel" % [t.level, n], false)
				continue
			# Dejar asentar unos segundos de fisica real.
			await _wait(90)
			var on_floor: bool = enemy.is_on_floor()
			_check("%s / %s esta parado en piso solido" % [t.level, n], on_floor)
			var pos_a: Vector2 = enemy.global_position
			await _wait(30)
			var pos_b: Vector2 = enemy.global_position
			# "Trabado/parpadeando" = oscila violentamente en Y (cayendo y
			# rebotando) en vez de moverse suave en X (patrulla normal) o
			# quedarse quieto en Y sobre el piso.
			var y_jitter: float = absf(pos_b.y - pos_a.y)
			_check("%s / %s no tiembla/cae en Y (jitter=%.1f)" % [t.level, n, y_jitter], y_jitter < 5.0)
		level.queue_free()
		await _wait(3)

func _test_shield_block_and_stomp() -> void:
	const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
	const GUARD_SCENE := preload("res://scenes/enemies/shield_guard.tscn")
	var root := Node2D.new()
	add_child(root)
	var luke: Node2D = PLAYER_SCENE.instantiate()
	luke.name = "Luke"
	root.add_child(luke)
	var guard = GUARD_SCENE.instantiate()
	root.add_child(guard)
	await _wait(2)
	# Vida alta para este test: solo nos interesa si CADA golpe individual
	# pega o no, no si el guardia muere a mitad de la secuencia de pruebas.
	guard.max_health = 10
	guard.health = 10
	guard.global_position = Vector2(1000, 0)
	luke.global_position = Vector2(1000, 0)
	await _wait(1)
	# Congelar al guardia (sin esto, su propia patrulla GROUND_PATROL lo
	# mueve un poco cada frame y corre el lado "de frente" justo mientras
	# el test arma el escenario, dando falsos positivos/negativos).
	guard.set_physics_process(false)
	guard.velocity = Vector2.ZERO

	# El escudo apunta hacia donde mira (flip_h). Forzamos que mire hacia
	# +x (derecha): un ataque desde la derecha (frente) debe bloquearse.
	guard.sprite.flip_h = true
	luke.global_position = guard.global_position + Vector2(60, 0)
	var hp_before: int = guard.health
	guard.receive_attack(luke, 1)
	_check("Ataque de frente (lado del escudo) no hace daño", guard.health == hp_before)

	# El mismo ataque desde la izquierda (atras del escudo) SI debe pegar.
	var fake_attacker := Node2D.new()
	fake_attacker.global_position = guard.global_position + Vector2(-60, 0)
	root.add_child(fake_attacker)
	guard.receive_attack(fake_attacker, 1)
	_check("Ataque por detras del escudo SI hace daño", guard.health == hp_before - 1)

	# Saltarle encima ignora el escudo: forzamos a Luke a "caer" sobre el
	# TopHurtbox con velocidad hacia abajo.
	var hp_before_stomp: int = guard.health
	luke.global_position = guard.global_position + Vector2(0, -90)
	luke.velocity.y = 500.0
	guard._on_top_hurtbox_body_entered(luke)
	await _wait(2)
	_check("Saltarle encima hace daño (ignora el escudo)", guard.health == hp_before_stomp - 1)

	root.queue_free()
	await _wait(2)

func _test_fake_coin_no_currency() -> void:
	const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
	const PROJECTILE_SCENE := preload("res://scenes/objects/fake_coin_projectile.tscn")
	var root := Node2D.new()
	add_child(root)
	var luke: Node2D = PLAYER_SCENE.instantiate()
	luke.name = "Luke"
	luke.global_position = Vector2(0, 0)
	root.add_child(luke)
	await _wait(2)
	var coins_before: int = GameState.coins
	var proj = PROJECTILE_SCENE.instantiate()
	root.add_child(proj)
	proj.launch(Vector2(-30, 0), 1.0, null)
	await _wait(10)
	_check("La moneda falsa NO suma monedas al tocar a Luke", GameState.coins == coins_before)
	root.queue_free()
	await _wait(2)

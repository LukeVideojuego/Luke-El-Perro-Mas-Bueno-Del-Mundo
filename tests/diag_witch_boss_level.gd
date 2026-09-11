extends Node2D

## Punto 11 del bloque de correcciones: el nivel de "La Bruja del Olvido"
## (world_2_boss.tscn) fue reportado completamente roto (sin monedas, sin
## cajas rompibles, sin daño en ninguna dirección). Prueba las 4 cosas
## reportadas sobre instancias reales del nivel (una por prueba, para que no
## se interfieran entre sí: p. ej. si la bruja golpea a Luke durante la
## prueba de ataque cuerpo a cuerpo, dispara un respawn a spawn_point que
## invalida esa y la siguiente prueba). Ticks reales de física.

const LEVEL := preload("res://scenes/levels/world_2_boss.tscn")

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

var level: Node
var luke: Luke
var boss: Node
var frame := 0
var phase := 0
var coins_before := 0
var boss_health_before := 0
var got_damaged := false

func _fresh_level() -> void:
	if level != null:
		level.queue_free()
	level = LEVEL.instantiate()
	add_child(level)
	luke = level.get_node("Luke")
	boss = level.get_node("WitchBoss")

func _ready() -> void:
	_fresh_level()
	var coin := level.get_node("CoinA")
	coins_before = GameState.coins
	luke.global_position = coin.global_position
	frame = 0
	phase = 1

func _physics_process(_delta: float) -> void:
	frame += 1
	match phase:
		1:
			if frame >= 5:
				var coin_gone := not is_instance_valid(level.get_node_or_null("CoinA"))
				_check(coin_gone, "CoinA se recolecta al tocarla")
				_check(GameState.coins > coins_before, "GameState.coins aumenta al recolectar (antes=%d ahora=%d)" % [coins_before, GameState.coins])
				_start_box_test()
		2:
			if frame == 3:
				Input.action_press("attack")
			if frame == 6:
				Input.action_release("attack")
			if frame >= 20:
				var box_gone := not is_instance_valid(level.get_node_or_null("BoxA"))
				_check(box_gone, "BoxA se rompe con el ataque de Luke")
				_start_boss_attack_test()
		3:
			if frame == 3:
				Input.action_press("attack")
			if frame == 6:
				Input.action_release("attack")
			if frame >= 20:
				# Si el golpe la dejó en 0 de vida, boss.queue_free() ya la
				# liberó (varios ticks de daño durante la misma animación de
				# ataque) — eso es un PASS todavía más contundente.
				if not is_instance_valid(boss):
					_check(true, "el ataque de Luke daña a la Bruja (la derrotó de un swing)")
				else:
					_check(boss.health < boss_health_before, "el ataque de Luke daña a la Bruja (vida antes=%d ahora=%d)" % [boss_health_before, boss.health])
				_start_boss_contact_test()
		4:
			if frame >= 40:
				_check(got_damaged, "el contacto de la Bruja daña a Luke")
				print("RESULTADO: ", fail_count, " fallos")
				get_tree().quit()

func _start_box_test() -> void:
	_fresh_level()
	var box := level.get_node("BoxA")
	# Congelamos a la bruja para que esta prueba (ataque de Luke a la caja)
	# no se vea interferida por su IA de patrulla/carga.
	boss.set_physics_process(false)
	luke.global_position = box.global_position - Vector2(50, 0)
	luke.velocity = Vector2.ZERO
	frame = 0
	phase = 2

func _start_boss_attack_test() -> void:
	_fresh_level()
	# Congelamos a la bruja: esta prueba es específicamente "el ataque de
	# Luke la daña a ELLA", aislada de que ella también ataque de vuelta.
	boss.set_physics_process(false)
	boss_health_before = boss.health
	luke.global_position = boss.global_position - Vector2(70, 0)
	luke.velocity = Vector2.ZERO
	frame = 0
	phase = 3

func _start_boss_contact_test() -> void:
	_fresh_level()
	got_damaged = false
	luke.damaged.connect(func(): got_damaged = true)
	# Encima del jefe (con su IA activa), para que su DamageArea o su poder
	# la alcancen de verdad.
	luke.global_position = boss.global_position
	luke.velocity = Vector2.ZERO
	frame = 0
	phase = 4

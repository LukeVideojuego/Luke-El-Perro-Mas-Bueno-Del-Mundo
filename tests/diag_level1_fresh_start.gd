extends Node2D

## Punto 4: en una partida NUEVA (menú -> COMENZAR JUEGO -> intro -> Nivel 1),
## sin morir nunca, se reportó que ni las monedas, ni el ataque de Luke, ni
## el daño de los enemigos funcionan en el Nivel 1 -- y que "se arregla
## solo" después de la primera muerte/respawn. Reproduce la cadena REAL
## completa (a diferencia de smoke_test.gd, que instancia el nivel
## directamente sin pasar por main.gd) y prueba las 3 interacciones ANTES
## de que Luke muera ninguna vez.

const MAIN_SCENE := preload("res://scenes/main.tscn")

var main: Node
var frame := 0
var phase := 0
var wait_start := 0
var fail_count := 0
const WATCHDOG := 900

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _phase(to: int) -> void:
	phase = to
	wait_start = frame
	print("PHASE->", to, " at frame ", frame)

func _current_level() -> Node:
	var container := main.get_node("LevelContainer")
	return container.get_child(container.get_child_count() - 1)

func _waited() -> bool:
	return frame - wait_start > WATCHDOG

var luke: Luke
var thief: Node
var coin: Node
var box: Node
var luke_lives_start := 0
var thief_health_start := 0

func _ready() -> void:
	main = MAIN_SCENE.instantiate()
	add_child(main)

func _physics_process(_delta: float) -> void:
	frame += 1
	match phase:
		0:
			if frame == 10:
				main.start_game()
				_phase(10)
		10:
			if main.intro_cinematic != null and frame - wait_start > 15:
				main.intro_cinematic.get_node("Panel1/Panel1Button").pressed.emit()
				_phase(11)
			elif _waited():
				_check(false, "llega la cinematica")
				get_tree().quit(1)
		11:
			if frame - wait_start > 20:
				main.intro_cinematic.get_node("Panel2/Panel2Button").pressed.emit()
				_phase(12)
		12:
			if frame - wait_start > 20:
				main.intro_cinematic.get_node("Panel3/Panel3Button").pressed.emit()
				_phase(20)
		20:
			# Esperar a que world_1_level_1 este realmente activo y estable.
			if GameState.current_level_id == "world_1_level_1" and not main.is_transitioning:
				var level := _current_level()
				luke = level.get_node("Luke")
				thief = level.get_node("ThiefOne")
				coin = level.get_node("CoinA")
				box = level.get_node("BreakableBoxA")
				luke_lives_start = GameState.lives
				thief_health_start = thief.health
				print("Nivel 1 activo. lives=", luke_lives_start, " thief_health=", thief_health_start)
				_phase(21)
			elif _waited():
				_check(false, "world_1_level_1 se activa")
				get_tree().quit(1)
		21:
			# 1) Moneda: teletransportar a Luke sobre CoinA.
			if is_instance_valid(coin):
				luke.global_position = coin.global_position
			if frame - wait_start > 10:
				_check(not is_instance_valid(coin) or coin.is_collected, "la moneda se recolecta en la PRIMERA vida (sin haber muerto nunca)")
				_phase(22)
		22:
			# 2) Ataque de Luke contra el ladron: lo ubicamos al lado y atacamos.
			# Congelamos al ladron (como en el diagnostico de la Bruja) para
			# aislar "el ataque de Luke lo daña" de "su contacto respawnea a
			# Luke antes de que el ataque llegue a conectar".
			if frame == wait_start + 1:
				thief.set_physics_process(false)
				thief.get_node("DamageArea").set_deferred("monitoring", false)
				luke.global_position = thief.global_position - Vector2(60, 0)
				luke.velocity = Vector2.ZERO
			if frame == wait_start + 4:
				Input.action_press("attack")
			if frame == wait_start + 7:
				Input.action_release("attack")
			if frame - wait_start > 25:
				var thief_damaged: bool = (not is_instance_valid(thief)) or thief.health < thief_health_start
				_check(thief_damaged, "el ataque de Luke daña al ladron en la PRIMERA vida (vida antes=%d)" % thief_health_start)
				_phase(23)
		23:
			# 3) Contacto del enemigo contra Luke: usamos ThiefTwo (fresco, sin
			# tocar por las fases anteriores) para no depender de si ThiefOne
			# sobrevivio al ataque de la fase 22.
			if frame == wait_start + 1:
				var thief2 := _current_level().get_node("ThiefTwo")
				luke.global_position = thief2.global_position
				luke.velocity = Vector2.ZERO
				luke.damaged.connect(_on_luke_damaged, CONNECT_ONE_SHOT)
			if frame - wait_start > 40:
				_check(_luke_was_damaged, "el contacto del enemigo daña a Luke en la PRIMERA vida (sin morir antes)")
				_finish()

var _luke_was_damaged := false
func _on_luke_damaged() -> void:
	_luke_was_damaged = true

func _finish() -> void:
	_check(GameState.lives == luke_lives_start or GameState.lives == luke_lives_start - 1, "Luke nunca murio durante la prueba (lives=%d, arranco en %d)" % [GameState.lives, luke_lives_start])
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

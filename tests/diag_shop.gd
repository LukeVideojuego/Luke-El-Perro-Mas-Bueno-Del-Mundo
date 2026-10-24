extends Node2D

## C3: tienda de monedas.
##
## Verifica el circuito completo: cuando aparece, que se pueda comprar y que
## descuente, que no deje comprar sin plata, que lo comprado se guarde en el
## save, que los consumibles se apliquen al empezar el nivel, que los
## cosmeticos se dibujen sobre Luke en TODAS sus animaciones, y que el poder
## de ataque nuevo gaste municion y vuelva al huesito cuando se acaba.

const LUKE_SCENE := preload("res://scenes/player/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/thief.tscn")
const MAIN_SCENE := preload("res://scenes/main.tscn")
const LEVEL_SCENE := preload("res://scenes/levels/world_1_level_2.tscn")

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	_check_when_shown()
	_check_buying()
	_check_persistence()
	await _check_level_start_effects()
	await _check_bark()
	await _check_cosmetics_render()
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _check_when_shown() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	add_child(main)
	_check(not main.should_show_shop("world_1_level_1"), "la tienda NO aparece antes del nivel 1")
	var all_later := true
	for world in range(1, 5):
		for n in range(1, 4):
			var id := "world_%d_level_%d" % [world, n]
			if id == "world_1_level_1":
				continue
			all_later = all_later and main.should_show_shop(id)
		all_later = all_later and main.should_show_shop("world_%d_boss" % world)
	_check(all_later, "la tienda aparece antes de los otros 15 niveles")
	main.queue_free()

func _check_buying() -> void:
	GameState.reset_for_new_game()
	GameState.coins = 60
	_check(not GameState.buy_item("suit_cape"), "no se puede comprar el traje (90) con 60 monedas")
	_check(GameState.coins == 60, "un intento fallido no descuenta monedas")
	_check(GameState.buy_item("hat_beanie"), "se compra el gorro de lana (20)")
	_check(GameState.coins == 40, "quedan 40 monedas (tenia 60, gasto 20)")
	_check(GameState.owned_items.has("hat_beanie"), "el gorro queda en el inventario")
	_check(GameState.equipped_hat == "hat_beanie", "el gorro recien comprado queda puesto")
	_check(not GameState.buy_item("hat_beanie"), "no se puede volver a comprar un cosmetico que ya se tiene")
	GameState.toggle_equipped("hat_beanie")
	_check(GameState.equipped_hat == "", "se puede sacar el gorro")
	GameState.toggle_equipped("hat_beanie")
	_check(GameState.equipped_hat == "hat_beanie", "y se puede volver a poner gratis")
	_check(GameState.buy_item("bark"), "se compra municion de ladridos (25)")
	_check(GameState.bark_ammo == 5, "suma 5 cargas (tiene %d)" % GameState.bark_ammo)

func _check_persistence() -> void:
	GameState.current_level_id = "world_1_level_2"
	SaveManager.save_game()
	var hat := GameState.equipped_hat
	var ammo := GameState.bark_ammo
	var coins := GameState.coins
	GameState.owned_items = []
	GameState.equipped_hat = ""
	GameState.bark_ammo = 0
	GameState.coins = 0
	SaveManager.load_game()
	_check(GameState.owned_items.has("hat_beanie") and GameState.equipped_hat == hat
		and GameState.bark_ammo == ammo and GameState.coins == coins,
		"lo comprado sobrevive al guardado (gorro=%s, ladridos=%d, monedas=%d)" % [
			GameState.equipped_hat, GameState.bark_ammo, GameState.coins])

func _check_level_start_effects() -> void:
	GameState.reset_for_new_game()
	GameState.coins = 200
	GameState.buy_item("star")
	GameState.buy_item("heart")
	GameState.buy_item("aura")
	GameState.buy_item("boots")
	var lives_before := GameState.lives
	var level: Node = LEVEL_SCENE.instantiate()
	add_child(level)
	for i in range(6):
		await get_tree().physics_frame
	var luke: Luke = level.get_node("Luke")
	_check(luke.has_invincibility, "la estrella arranca el nivel con invencibilidad")
	_check(luke.has_speed_boost, "el hongo veloz arranca el nivel con velocidad")
	_check(luke.has_protective_aura, "el aura protectora arranca puesta")
	_check(GameState.lives == lives_before + 1, "el corazon de repuesto suma una vida (%d -> %d)" % [lives_before, GameState.lives])
	_check(not GameState.pending_star and not GameState.pending_boots
		and not GameState.pending_aura and GameState.pending_hearts == 0,
		"los consumibles se gastan (no se repiten en el nivel siguiente)")
	level.queue_free()
	await get_tree().process_frame

func _check_bark() -> void:
	GameState.reset_for_new_game()
	GameState.bone_throw_unlocked = true
	GameState.bark_ammo = 1
	var arena := Node2D.new()
	add_child(arena)
	var ground := StaticBody2D.new()
	ground.collision_layer = 1
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(3000.0, 80.0)
	cs.shape = rect
	ground.add_child(cs)
	ground.position = Vector2(500.0, 940.0)
	arena.add_child(ground)
	var luke: Luke = LUKE_SCENE.instantiate()
	luke.position = Vector2(200.0, 850.0)
	arena.add_child(luke)
	var enemies: Array[EnemyBase] = []
	for i in range(2):
		var e: EnemyBase = ENEMY_SCENE.instantiate()
		e.position = Vector2(500.0 + i * 260.0, 850.0)
		e.set_physics_process(false)
		arena.add_child(e)
		enemies.append(e)
	for i in range(8):
		await get_tree().physics_frame
	luke.facing_direction = 1
	await _double_tap()
	await _wait_physics(6)
	var waves := 0
	for child in arena.get_children():
		if child is BarkWave:
			waves += 1
	_check(waves == 1, "con municion, el doble toque lanza el ladrido de onda expansiva")
	_check(GameState.bark_ammo == 0, "el disparo gasta una carga")
	await _wait_physics(55)
	var alive := 0
	for e in enemies:
		if is_instance_valid(e):
			alive += 1
	_check(alive == 0, "la onda atraviesa y derrota a los 2 enemigos de la fila (quedan %d)" % alive)
	# Sin municion vuelve el huesito
	luke.facing_direction = 1
	await _double_tap()
	await _wait_physics(6)
	var bones := 0
	for child in arena.get_children():
		if child is ThrownBone:
			bones += 1
	_check(bones == 1, "sin municion, el doble toque vuelve a lanzar el huesito")
	arena.queue_free()
	await get_tree().process_frame

func _double_tap() -> void:
	Input.action_press("attack")
	await get_tree().physics_frame
	Input.action_release("attack")
	await get_tree().physics_frame
	Input.action_press("attack")
	await get_tree().physics_frame
	Input.action_release("attack")

func _wait_physics(n: int) -> void:
	for i in range(n):
		await get_tree().physics_frame

func _check_cosmetics_render() -> void:
	GameState.reset_for_new_game()
	GameState.coins = 300
	GameState.buy_item("hat_crown")
	GameState.buy_item("suit_cape")
	var luke: Luke = LUKE_SCENE.instantiate()
	luke.gravity = 0.0
	add_child(luke)
	await get_tree().physics_frame
	var positions := {}
	var all_visible := true
	for anim in ["idle", "walk", "jump", "attack"]:
		luke.animated_sprite.animation = anim
		luke._update_cosmetics()
		all_visible = all_visible and luke.hat_sprite.visible and luke.cape_sprite.visible
		positions[anim] = luke.hat_sprite.position
	_check(all_visible, "el sombrero y la capa se dibujan en las 4 animaciones")
	_check(positions["jump"] != positions["idle"] and positions["attack"] != positions["idle"],
		"el sombrero acompana la cabeza en cada pose (idle=%s jump=%s attack=%s)" % [
			positions["idle"], positions["jump"], positions["attack"]])
	# B2: la capa es de nuevo 2 sprites fijos (reposo/salto, cape_sprite.gd)
	# en vez de la tira simulada con fisica de la ronda anterior. Prueba el
	# CapeSprite directamente (sin piso real, Luke nunca esta on_floor, asi
	# que se apaga su _physics_process para que no pise el estado con su
	# propio _update_cosmetics() de cada frame mientras se maneja a mano):
	# arranca en reposo, y set_deployed(true) hace un fade cruzado hacia
	# la pose de salto (no un corte seco: durante la transicion ambas
	# texturas coexisten con opacidad intermedia).
	luke.set_physics_process(false)
	luke.cape_sprite.set_deployed(false)
	for i in range(15):
		await get_tree().physics_frame
	_check(luke.cape_sprite.rest_sprite.modulate.a > 0.9 and luke.cape_sprite.jump_sprite.modulate.a < 0.1,
		"la capa vuelve a la pose de reposo")
	luke.cape_sprite.set_deployed(true)
	for i in range(3):
		await get_tree().physics_frame
	var mid_rest: float = luke.cape_sprite.rest_sprite.modulate.a
	var mid_jump: float = luke.cape_sprite.jump_sprite.modulate.a
	_check(mid_rest < 0.9 and mid_jump > 0.1 and mid_jump < 0.9,
		"la transicion a la pose de salto es un fade cruzado, no un corte seco (reposo=%.2f salto=%.2f)" % [mid_rest, mid_jump])
	for i in range(15):
		await get_tree().physics_frame
	_check(luke.cape_sprite.jump_sprite.modulate.a > 0.9 and luke.cape_sprite.rest_sprite.modulate.a < 0.1,
		"la capa termina de desplegarse en la pose de salto")
	luke.queue_free()
	await get_tree().process_frame

extends Node2D

## F4: "GUARDAR PARTIDA" desde la tienda. Simula el ciclo completo pedido
## (guardar en la tienda -> "cerrar y volver a abrir el juego" -> cargar)
## sin poder cerrar el proceso de verdad: resetea GameState a cero (lo mas
## parecido a un arranque nuevo del juego que se puede simular) y despues
## llama a SaveManager.load_game(), igual que hace main._on_continue_
## requested() al apretar "CARGAR PARTIDA" en el menu. Confirma que vuelve
## exactamente al nivel guardado con todo lo guardado (monedas, vidas,
## continues, compras, sombrero equipado), y que Luke aparece en el
## SpawnPoint real de ese nivel (no en el origen del mundo).

const SHOP_SCENE := preload("res://scenes/ui/shop_screen.tscn")
const MAIN_SCENE := preload("res://scenes/main.tscn")

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	await _run()
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _run() -> void:
	# 1) Armar un estado de partida "en curso" cualquiera y abrir la tienda
	#    como si el jugador estuviera por entrar a world_2_level_1.
	GameState.reset_for_new_game()
	GameState.coins = 85
	GameState.lives = 2
	GameState.continues_left = 1
	GameState.buy_item("hat_beanie")
	var coins_after_buy: int = GameState.coins
	var shop := SHOP_SCENE.instantiate()
	add_child(shop)
	shop.setup("world_2_level_1")
	await get_tree().process_frame

	# 2) Apretar GUARDAR PARTIDA de verdad (el boton, no la funcion interna).
	var save_button: Button = shop.get_node("Panel/Footer/SaveButton")
	save_button.pressed.emit()
	await get_tree().process_frame
	_check(shop.get_node("Panel/Footer/StatusLabel").text == "Partida guardada",
		"la tienda muestra la confirmacion 'Partida guardada'")
	_check(SaveManager.has_save(), "el archivo de guardado existe en disco despues de apretar el boton")
	shop.queue_free()
	await get_tree().process_frame

	# 3) "Cerrar y volver a abrir el juego": lo mas parecido simulable es
	#    resetear GameState del todo (un reset_for_new_game() deja todo en
	#    los valores de arranque, como si el autoload se acabara de crear).
	GameState.reset_for_new_game()
	_check(GameState.coins == 0, "GameState quedo en cero tras el reset (confirma que lo que sigue viene del archivo, no de memoria)")

	# 4) Cargar: mismo llamado que hace "CARGAR PARTIDA" en el menu.
	var loaded := SaveManager.load_game()
	_check(loaded, "SaveManager.load_game() encuentra y carga el archivo")
	_check(GameState.current_level_id == "world_2_level_1", "vuelve al nivel correcto (world_2_level_1), no al que estaba antes de entrar a la tienda")
	_check(GameState.coins == coins_after_buy, "las monedas vuelven exactas (%d)" % coins_after_buy)
	_check(GameState.lives == 2, "las vidas vuelven exactas (2)")
	_check(GameState.continues_left == 1, "los continues vuelven exactos (1)")
	_check(GameState.owned_items.has("hat_beanie"), "las compras (gorro) se mantienen")
	_check(GameState.equipped_hat == "hat_beanie", "el sombrero equipado se mantiene")

	# 5) Cargar el nivel de verdad (igual que main._on_continue_requested)
	#    y confirmar que Luke aparece en SU SpawnPoint real, no en (0,0).
	var level: Node = load(LevelProgression.get_scene_path(GameState.current_level_id)).instantiate()
	add_child(level)
	await get_tree().physics_frame
	var luke: Node2D = level.get_node("Luke")
	var spawn: Node2D = level.get_node("SpawnPoint")
	_check(luke.global_position.distance_to(spawn.global_position) < 5.0,
		"Luke aparece en el SpawnPoint real del nivel (no en el origen del mundo): luke=%s spawn=%s" % [
			luke.global_position, spawn.global_position])
	level.queue_free()
	await get_tree().process_frame

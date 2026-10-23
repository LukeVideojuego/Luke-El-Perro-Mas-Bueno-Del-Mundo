extends Node2D

## A7: coleccionables (huellas doradas + album).
##
## Confirma:
##  1. Los 12 niveles regulares tienen exactamente 3 GoldenPaw cada uno (36
##     en total), con level_id/paw_index correctos y sin indices repetidos.
##  2. Tocar una huella real (fisica real, Luke de verdad) la registra en
##     GameState y no reaparece si se recarga el nivel.
##  3. Juntar las 3 de un nivel paga 10 monedas, UNA sola vez.
##  4. Juntar las 36 desbloquea el collar dorado y lo equipa solo.
##  5. Todo sobrevive un ciclo guardar -> resetear -> cargar.

const LEVELS := [
	"world_1_level_1", "world_1_level_2", "world_1_level_3",
	"world_2_level_1", "world_2_level_2", "world_2_level_3",
	"world_3_level_1", "world_3_level_2", "world_3_level_3",
	"world_4_level_1", "world_4_level_2", "world_4_level_3",
]

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	_check_placement()
	await _check_real_pickup()
	_check_level_reward()
	_check_full_unlock()
	_check_save_load()
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _check_placement() -> void:
	var total := 0
	for level_id in LEVELS:
		var level: Node = load("res://scenes/levels/%s.tscn" % level_id).instantiate()
		add_child(level)
		var paws: Array = []
		for child in level.get_children():
			if child is GoldenPaw:
				paws.append(child)
		_check(paws.size() == 3, "%s: tiene exactamente 3 huellas (tiene %d)" % [level_id, paws.size()])
		var indices := {}
		for p in paws:
			_check(p.level_id == level_id, "%s: la huella tiene level_id correcto" % level_id)
			indices[p.paw_index] = true
		_check(indices.size() == paws.size(), "%s: los indices de huella no se repiten" % level_id)
		total += paws.size()
		level.queue_free()
	_check(total == 36, "hay 36 huellas en total entre los 12 niveles (hay %d)" % total)

func _check_real_pickup() -> void:
	GameState.reset_for_new_game()
	var level: Node = load("res://scenes/levels/world_1_level_1.tscn").instantiate()
	add_child(level)
	await get_tree().physics_frame
	var paw: GoldenPaw = level.get_node_or_null("GoldenPaw1")
	_check(paw != null, "world_1_level_1 tiene GoldenPaw1")
	if paw == null:
		level.queue_free()
		return
	var luke: Luke = level.get_node("Luke")
	luke.global_position = paw.global_position
	for i in range(10):
		await get_tree().physics_frame
	_check(GameState.has_paw("world_1_level_1", 0), "tocar la huella real la registra en GameState")
	_check(not is_instance_valid(paw), "la huella se destruye al tocarla")
	level.queue_free()
	await get_tree().process_frame

	# Recargar el nivel: la misma huella NO debe reaparecer.
	var level2: Node = load("res://scenes/levels/world_1_level_1.tscn").instantiate()
	add_child(level2)
	await get_tree().physics_frame
	var paw_again: Node = level2.get_node_or_null("GoldenPaw1")
	_check(paw_again == null or not paw_again.visible,
		"al recargar el nivel, la huella ya encontrada no reaparece")
	level2.queue_free()
	await get_tree().process_frame

func _check_level_reward() -> void:
	GameState.reset_for_new_game()
	var coins_before := GameState.coins
	GameState.collect_paw("world_2_level_1", 0)
	GameState.collect_paw("world_2_level_1", 1)
	_check(GameState.coins == coins_before, "con 2 de 3 huellas todavia no se pagan monedas")
	GameState.collect_paw("world_2_level_1", 2)
	_check(GameState.coins == coins_before + GameState.PAW_LEVEL_REWARD_COINS,
		"al juntar las 3 de un nivel se pagan %d monedas (tiene %d, antes %d)" % [GameState.PAW_LEVEL_REWARD_COINS, GameState.coins, coins_before])
	var coins_after_reward := GameState.coins
	GameState.collect_paw("world_2_level_1", 2)  # repetir no debe volver a pagar
	_check(GameState.coins == coins_after_reward, "tocar de nuevo una huella ya contada no vuelve a pagar")

func _check_full_unlock() -> void:
	GameState.reset_for_new_game()
	_check(not GameState.collar_equipped, "arranca sin el collar puesto")
	var count := 0
	for level_id in GameState.PAW_LEVELS:
		for i in range(GameState.PAWS_PER_LEVEL):
			GameState.collect_paw(level_id, i)
			count += 1
			if count < GameState.total_paws_possible():
				_check(not GameState.golden_collar_unlocked,
					"con %d/%d huellas el collar TODAVIA no esta desbloqueado" % [count, GameState.total_paws_possible()])
	_check(GameState.golden_collar_unlocked, "con las 36 huellas el collar queda desbloqueado")
	_check(GameState.collar_equipped, "el collar se pone solo al desbloquearse")
	_check(GameState.owned_items.has("collar_dorado"), "el collar dorado queda en el inventario")

func _check_save_load() -> void:
	GameState.reset_for_new_game()
	GameState.current_level_id = "world_1_level_1"
	GameState.collect_paw("world_1_level_1", 0)
	GameState.collect_paw("world_1_level_1", 1)
	SaveManager.save_game()
	GameState.reset_for_new_game()
	_check(not GameState.has_paw("world_1_level_1", 0), "el reset de control borra el progreso en memoria")
	var loaded := SaveManager.load_game()
	_check(loaded, "SaveManager.load_game() encuentra el archivo")
	_check(GameState.has_paw("world_1_level_1", 0) and GameState.has_paw("world_1_level_1", 1),
		"cargar la partida restaura las huellas ya encontradas")
	_check(GameState.paws_found_in_level("world_1_level_1") == 2,
		"el conteo por nivel tras cargar es el correcto (%d)" % GameState.paws_found_in_level("world_1_level_1"))

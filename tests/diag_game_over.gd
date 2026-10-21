extends Node2D

## C1: pantalla de "Te has quedado sin vidas" con CONTINUAR / GAME OVER.
##
## Antes, al perder la ultima vida, el nivel se reiniciaba solo con 3 vidas
## sin avisar nada. Ahora se sale del nivel a una pantalla negra con el arte
## de game over, cuantos continues quedan, y dos opciones: CONTINUAR
## (reinicia ESTE nivel con 3 vidas y gasta un continue) o GAME OVER (vuelve
## al menu principal). Solo hay 3 continues por partida.
##
## El test corre el Main de verdad, carga un nivel de verdad y mata a Luke
## llamando a su senal `defeated` (el mismo camino que un pincho o un villano).

const MAIN_SCENE := preload("res://scenes/main.tscn")

var fail_count := 0
var main: Node

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame
	main.start_game()
	await _wait(90)
	if main.intro_cinematic != null:
		main._on_intro_finished()
	await _wait(150)
	_check(main.active_level != null, "arranca con un nivel cargado")
	_check(GameState.continues_left == 3, "partida nueva arranca con 3 continues (tiene %d)" % GameState.continues_left)

	# --- primera muerte total ---
	await _drain_lives()
	await _wait(10)
	var screen: Node = main.game_over_screen
	_check(screen != null, "al perder la ultima vida aparece la pantalla de game over")
	_check(main.active_level == null or not main.hud.visible, "el HUD del nivel se oculta")
	if screen != null:
		_check(screen.continues_label.text.contains("3"),
			"muestra cuantos continues quedan: \"%s\"" % screen.continues_label.text)
		_check(not screen.continue_button.disabled, "CONTINUAR esta habilitado con continues disponibles")
		var level_before: String = GameState.current_level_id
		screen.continue_requested.emit()
		await _wait(120)
		_check(GameState.continues_left == 2, "CONTINUAR gasta un continue (quedan %d)" % GameState.continues_left)
		_check(GameState.lives == 3, "CONTINUAR reinicia con 3 vidas (tiene %d)" % GameState.lives)
		_check(GameState.current_level_id == level_before,
			"CONTINUAR vuelve al MISMO nivel (%s)" % GameState.current_level_id)
		_check(main.active_level != null and main.game_over_screen == null, "el nivel vuelve a estar cargado")

	# --- gastar los 2 continues restantes ---
	for i in range(2):
		await _drain_lives()
		await _wait(10)
		if main.game_over_screen != null and not main.game_over_screen.continue_button.disabled:
			main.game_over_screen.continue_requested.emit()
			await _wait(120)
	_check(GameState.continues_left == 0, "despues de 3 CONTINUAR no quedan continues (quedan %d)" % GameState.continues_left)

	# --- sin continues: solo queda GAME OVER ---
	await _drain_lives()
	await _wait(10)
	var last: Node = main.game_over_screen
	_check(last != null, "sin continues igual aparece la pantalla de game over")
	if last != null:
		_check(last.continue_button.disabled, "sin continues, CONTINUAR queda deshabilitado")
		_check(last.continues_label.text.to_lower().contains("no te quedan"),
			"avisa que no quedan continues: \"%s\"" % last.continues_label.text)

	# --- persistencia ---
	GameState.continues_left = 1
	SaveManager.save_game()
	GameState.continues_left = 99
	var loaded := SaveManager.load_game()
	_check(loaded and GameState.continues_left == 1,
		"los continues se guardan y se recuperan del save (%d)" % GameState.continues_left)

	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

## Mata a Luke tantas veces como vidas le queden.
func _drain_lives() -> void:
	for i in range(5):
		if main.game_over_screen != null:
			return
		var level: Node = main.active_level
		if level == null:
			return
		var luke: Luke = level.get_node_or_null("Luke")
		if luke == null:
			return
		luke.defeated.emit()
		await _wait(8)

func _wait(frames: int) -> void:
	for i in range(frames):
		await get_tree().process_frame

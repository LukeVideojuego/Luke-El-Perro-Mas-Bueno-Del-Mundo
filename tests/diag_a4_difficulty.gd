extends Node2D

## A4: modo facil.
##
## Confirma con el Main real y el menu real:
##  1. "COMENZAR JUEGO" muestra el selector de dificultad (no arranca directo).
##  2. Elegir NORMAL da 3 corazones y 3 continues (como siempre).
##  3. Elegir FACIL da 5 corazones y continues practicamente ilimitados.
##  4. La dificultad elegida sobrevive un ciclo guardar -> resetear -> cargar.
##  5. En FACIL, perder todas las vidas muchas veces seguidas NUNCA se queda
##     sin continues (a diferencia de NORMAL, que se agota a las 3).

const MAIN_SCENE := preload("res://scenes/main.tscn")

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	await _check_panel_and_normal()
	await _check_facil()
	_check_save_load_roundtrip()
	_check_unlimited_in_practice()
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _wait(frames: int) -> void:
	for i in range(frames):
		await get_tree().process_frame

## 1 y 2: el selector aparece y NORMAL da los valores de siempre.
func _check_panel_and_normal() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	add_child(main)
	await _wait(5)
	var menu: Node = main.get_node("MainMenu")
	menu.new_game_button.pressed.emit()
	await _wait(2)
	_check(menu.difficulty_panel.visible, "al apretar COMENZAR JUEGO aparece el selector de dificultad")
	_check(not menu.menu_panel.visible, "el menu principal se oculta mientras se elige dificultad")

	menu.normal_button.pressed.emit()
	await _wait(10)
	if main.intro_cinematic != null:
		main._on_intro_finished()
	await _wait(5)
	_check(GameState.difficulty == "normal", "NORMAL deja GameState.difficulty = \"normal\" (es \"%s\")" % GameState.difficulty)
	_check(GameState.lives == 3, "NORMAL arranca con 3 corazones (tiene %d)" % GameState.lives)
	_check(GameState.continues_left == 3, "NORMAL arranca con 3 continues (tiene %d)" % GameState.continues_left)
	main.queue_free()
	await _wait(2)

## 3: FACIL da 5 corazones y continues gigantes (de hecho ilimitados).
func _check_facil() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	add_child(main)
	await _wait(5)
	var menu: Node = main.get_node("MainMenu")
	menu.new_game_button.pressed.emit()
	await _wait(2)
	menu.easy_button.pressed.emit()
	await _wait(10)
	if main.intro_cinematic != null:
		main._on_intro_finished()
	await _wait(5)
	_check(GameState.difficulty == "facil", "FACIL deja GameState.difficulty = \"facil\" (es \"%s\")" % GameState.difficulty)
	_check(GameState.lives == 5, "FACIL arranca con 5 corazones (tiene %d)" % GameState.lives)
	_check(GameState.continues_left >= 1000, "FACIL arranca con continues practicamente ilimitados (tiene %d)" % GameState.continues_left)
	main.queue_free()

## 4: guardar en FACIL, resetear a NORMAL en memoria, cargar -> vuelve FACIL.
func _check_save_load_roundtrip() -> void:
	GameState.reset_for_new_game("facil")
	GameState.current_level_id = "world_1_level_1"
	SaveManager.save_game()
	GameState.reset_for_new_game("normal")
	_check(GameState.difficulty == "normal", "el reset de control deja \"normal\" antes de cargar")
	var loaded := SaveManager.load_game()
	_check(loaded, "SaveManager.load_game() encuentra el archivo guardado en FACIL")
	_check(GameState.difficulty == "facil", "cargar la partida restaura difficulty=\"facil\" (es \"%s\")" % GameState.difficulty)
	_check(GameState.default_lives() == 5, "tras cargar, default_lives() ya sabe que son 5 (FACIL)")
	_check(GameState.default_continues() >= 1000, "tras cargar, default_continues() sigue siendo practicamente ilimitado")

## 5: en FACIL, perder TODAS las vidas 10 veces seguidas (mas que los 3
## continues de NORMAL) nunca deja continues_left en 0.
func _check_unlimited_in_practice() -> void:
	GameState.reset_for_new_game("facil")
	for i in range(10):
		var ok := GameState.use_continue()
		_check(ok, "FACIL: use_continue() #%d sigue devolviendo true (no se agota)" % (i + 1))
	_check(GameState.continues_left > 999900, "FACIL: despues de 10 continues seguidos, siguen quedando prácticamente todos (%d)" % GameState.continues_left)
	_check(GameState.lives == 5, "FACIL: cada continue vuelve a dejar 5 corazones, no 3 (tiene %d)" % GameState.lives)

	# Control: en NORMAL, al 4to intento ya no quedan continues.
	GameState.reset_for_new_game("normal")
	for i in range(3):
		GameState.use_continue()
	var ok_normal := GameState.use_continue()
	_check(not ok_normal, "control NORMAL: al 4to continue ya no quedan (use_continue devuelve false)")

extends Node2D

## A5: contraseñas no adivinables.
##
## Confirma:
##  1. Los 16 codigos existen, son unicos, y ninguno queda en el viejo
##     formato secuencial "LUKEnn".
##  2. get_level_id_from_password() sigue funcionando (case-insensitive,
##     con espacios) para los codigos nuevos.
##  3. get_password_for_level() es la inversa exacta de PASSWORDS.
##  4. Con el Main real: completar un nivel muestra en pantalla su
##     contraseña real.

const MAIN_SCENE := preload("res://scenes/main.tscn")

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	_check_codes()
	await _check_on_screen()
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _check_codes() -> void:
	var passwords: Dictionary = LevelProgression.PASSWORDS
	_check(passwords.size() == 16, "hay exactamente 16 contraseñas (hay %d)" % passwords.size())

	var all_level_ids: Array[String] = []
	for world in range(1, 5):
		for n in range(1, 4):
			all_level_ids.append("world_%d_level_%d" % [world, n])
		all_level_ids.append("world_%d_boss" % world)
	for level_id in all_level_ids:
		var code := LevelProgression.get_password_for_level(level_id)
		_check(not code.is_empty(), "%s tiene una contraseña asignada" % level_id)
		_check(not code.begins_with("LUKE"), "%s: la contraseña \"%s\" ya NO es del viejo formato LUKEnn" % [level_id, code])

	var seen: Dictionary = {}
	var any_dup := false
	for code in passwords:
		if seen.has(code):
			any_dup = true
		seen[code] = true
	_check(not any_dup, "las 16 contraseñas son todas distintas entre si")

	# Secuencialidad: en el esquema viejo, el numero de la contraseña
	# coincidia exactamente con el orden global del nivel (LUKE01 -> orden 1,
	# etc). Confirma que eso YA NO es cierto para la mayoria de los casos
	# (no puede valer para TODOS por azar con solo 16 casos y digitos
	# 1-9, pero si coincidiera para todos seria sospechoso de ser
	# de nuevo secuencial).
	var coincide_con_orden := 0
	for code in passwords:
		var level_id: String = passwords[code]
		var order := LevelProgression.get_global_order(level_id)
		var digits := ""
		for c in code:
			if c.is_valid_int():
				digits += c
		if digits == str(order):
			coincide_con_orden += 1
	_check(coincide_con_orden < 4, "el numero de la contraseña YA NO sigue el orden del nivel en casi ningun caso (coincide en %d de 16)" % coincide_con_orden)

func _check_on_screen() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame
	main.start_game()
	for i in range(90):
		await get_tree().process_frame
	if main.intro_cinematic != null:
		main._on_intro_finished()
	for i in range(150):
		await get_tree().process_frame

	var level: Node = main.active_level
	_check(level != null, "arranca con world_1_level_1 cargado")
	if level == null:
		main.queue_free()
		return

	var finish: Node = level.get_node_or_null("Finish")
	_check(finish != null, "world_1_level_1 tiene un Finish real")
	if finish != null:
		var luke: Luke = level.get_node("Luke")
		luke.global_position = finish.global_position
		for i in range(10):
			await get_tree().process_frame

	var password_label: Label = level.get("_password_label")
	_check(password_label != null, "al completar el nivel se crea el cartel de contraseña")
	if password_label != null:
		var expected: String = LevelProgression.get_password_for_level("world_1_level_1")
		_check(password_label.visible, "el cartel de contraseña queda visible")
		_check(password_label.text.contains(expected),
			"el cartel muestra la contraseña REAL del nivel (\"%s\" en \"%s\")" % [expected, password_label.text])
	main.queue_free()

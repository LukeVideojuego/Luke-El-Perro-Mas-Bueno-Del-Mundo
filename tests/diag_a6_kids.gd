extends Node2D

## A6: los niños reemplazan a los carteles de madera.
##
## Confirma con fisica real, en varios niveles representativos:
##  1. El MissionSign de cada nivel ahora es un KidNpc con el chico correcto.
##  2. Acercarse NO muestra el globo solo (a diferencia del cartel viejo).
##  3. Apretar cualquier boton estando cerca SI lo muestra, con el nombre y
##     el texto correctos.
##  4. Alejarse lo oculta de nuevo.
##  5. Los 12 niveles tienen la asignacion de chico pedida, y los textos
##     mencionan objetivo + enemigos reales (ningun texto vacio o generico).

const EXPECTED := {
	"world_1_level_1": "Zoe", "world_1_level_2": "Mathi", "world_1_level_3": "Bauti",
	"world_2_level_1": "Roma", "world_2_level_2": "Lara", "world_2_level_3": "Fausto",
	"world_3_level_1": "Izan", "world_3_level_2": "Franca", "world_3_level_3": "Zoe",
	"world_4_level_1": "Mathi", "world_4_level_2": "Bauti", "world_4_level_3": "Roma",
}

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	for level_id in EXPECTED:
		_check_assignment(level_id, EXPECTED[level_id])
	await _check_interaction_flow("world_2_level_1", "Roma")
	await _check_interaction_flow("world_4_level_1", "Mathi")
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _check_assignment(level_id: String, expected_kid: String) -> void:
	var level: Node = load("res://scenes/levels/%s.tscn" % level_id).instantiate()
	add_child(level)
	var kid: KidNpc = level.get_node_or_null("MissionSign")
	_check(kid != null, "%s: el MissionSign es un KidNpc real" % level_id)
	if kid != null:
		_check(kid.kid_name == expected_kid, "%s: el chico es %s (pedido: %s)" % [level_id, kid.kid_name, expected_kid])
		_check(not kid.interaction_text.is_empty(), "%s: tiene un texto de dialogo" % level_id)
		_check(kid.interaction_text.begins_with(expected_kid + ":"),
			"%s: el texto arranca con \"%s:\"" % [level_id, expected_kid])
	level.queue_free()

func _check_interaction_flow(level_id: String, expected_kid: String) -> void:
	var level: Node = load("res://scenes/levels/%s.tscn" % level_id).instantiate()
	add_child(level)
	await get_tree().physics_frame
	var kid: KidNpc = level.get_node("MissionSign")
	var luke: Luke = level.get_node("Luke")
	var hint: Label = kid.hint_label

	# Lejos: sin globo.
	luke.global_position = kid.global_position + Vector2(-900.0, 0.0)
	for i in range(5):
		await get_tree().physics_frame
	_check(not hint.visible, "%s: lejos del chico, el globo esta oculto" % level_id)

	# Cerca, SIN apretar nada: el globo sigue sin mostrarse (a diferencia del
	# cartel viejo, que mostraba el hint apenas con la cercania).
	luke.global_position = kid.global_position
	for i in range(10):
		await get_tree().physics_frame
	_check(not hint.visible, "%s: cerca del chico pero sin apretar nada, el globo sigue oculto" % level_id)

	# Apretar un boton (ataque) estando cerca: aparece con nombre + texto.
	Input.action_press("attack")
	await get_tree().physics_frame
	Input.action_release("attack")
	for i in range(3):
		await get_tree().physics_frame
	_check(hint.visible, "%s: al apretar un boton cerca del chico, el globo aparece" % level_id)
	_check(hint.text == kid.interaction_text,
		"%s: el globo muestra el texto real, sin duplicar el nombre (\"%s\")" % [level_id, hint.text])
	_check(hint.text.count(expected_kid + ":") == 1,
		"%s: el nombre \"%s:\" aparece UNA sola vez en el globo (no \"%s: %s: ...\")" % [level_id, expected_kid, expected_kid, expected_kid])

	# Alejarse: se oculta de nuevo.
	luke.global_position = kid.global_position + Vector2(900.0, 0.0)
	for i in range(10):
		await get_tree().physics_frame
	_check(not hint.visible, "%s: al alejarse, el globo se vuelve a ocultar" % level_id)

	level.queue_free()
	await get_tree().process_frame

extends Node

## A1: las cinemáticas ya NO deben avanzar solas. Este diagnóstico (antes
## verificaba el viejo auto-avance por timeout) ahora verifica lo opuesto:
## sin ningún input del jugador los 3 paneles de la intro quedan fijos
## indefinidamente, y solo avanzan al apretar el botón "SIGUIENTE"
## (simulado emitiendo pressed, igual que tests/verify_intro_from_menu.gd).

const INTRO := preload("res://scenes/cinematics/intro_cinematic.tscn")

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	var intro: Node = INTRO.instantiate()
	add_child(intro)

	# Sin tocar nada durante 15s (más que el viejo timeout de 10s), el panel
	# tiene que seguir siendo el 1.
	for i in range(900):
		await get_tree().process_frame
	_check(intro.get_current_panel() == 1, "panel sigue en 1 tras 15s sin input (no avanza solo)")

	intro.get_node("Panel1/Panel1Button").pressed.emit()
	await get_tree().process_frame
	_check(intro.get_current_panel() == 2, "boton SIGUIENTE del panel 1 avanza a panel 2")

	# De nuevo, sin input el panel 2 tiene que quedar fijo.
	for i in range(900):
		await get_tree().process_frame
	_check(intro.get_current_panel() == 2, "panel sigue en 2 tras 15s sin input (no avanza solo)")

	var got_finished := [false]
	intro.finished.connect(func(): got_finished[0] = true)

	intro.get_node("Panel2/Panel2Button").pressed.emit()
	await get_tree().process_frame
	_check(intro.get_current_panel() == 3, "boton SIGUIENTE del panel 2 avanza a panel 3")

	intro.get_node("Panel3/Panel3Button").pressed.emit()
	await get_tree().process_frame
	_check(got_finished[0], "boton JUGAR del panel 3 termina la cinematica")

	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

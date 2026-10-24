extends Node

## A1: la cinematica final tampoco debe avanzar sola.

const FINAL := preload("res://scenes/cinematics/final_cinematic.tscn")

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	var final_c: Node = FINAL.instantiate()
	add_child(final_c)

	for i in range(900):
		await get_tree().process_frame
	_check(final_c.get_current_panel() == 1, "panel sigue en 1 tras 15s sin input")

	final_c.get_node("Panel1/Panel1Button").pressed.emit()
	await get_tree().process_frame
	_check(final_c.get_current_panel() == 2, "boton SIGUIENTE avanza a panel 2")

	for i in range(900):
		await get_tree().process_frame
	_check(final_c.get_current_panel() == 2, "panel sigue en 2 tras 15s sin input")

	var got_finished := [false]
	final_c.finished.connect(func(): got_finished[0] = true)
	final_c.get_node("Panel2/Panel2Button").pressed.emit()
	await get_tree().process_frame
	_check(got_finished[0], "boton CONTINUAR termina la cinematica final")

	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

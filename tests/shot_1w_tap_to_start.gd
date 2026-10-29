extends Node

## Punto 1 (web): captura real de "TOCA PARA EMPEZAR" (forzada en la compu
## con -- --tap-to-start) y prueba de que un clic la cierra sin apretar
## ningun boton del menu de abajo. Correr SIN --headless:
##   godot --path . res://tests/shot_1w_tap_to_start.tscn -- --tap-to-start <ancho> <alto>

const MAIN_SCENE := preload("res://scenes/main.tscn")

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	get_window().size = Vector2i(int(args[1]), int(args[2]))
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	await _frames(40)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../shot1w_tap_%sx%s.png" % [args[1], args[2]])
	var ok := main.get_node_or_null("TapToStart") != null
	# Clic justo encima de COMENZAR JUEGO: tiene que cerrar la pantalla y
	# NADA mas (el menu sigue en su panel principal).
	var center := get_viewport().get_visible_rect().size * 0.5
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = get_tree().root.get_final_transform() * (center + Vector2(0, -60))
		Input.parse_input_event(ev)
		await _frames(3)
	await _frames(10)
	ok = ok and main.get_node_or_null("TapToStart") == null
	ok = ok and main.get_node("MainMenu/MenuPanel").visible and not main.game_started
	ok = ok and AudioDirector._current_music == "menu"
	print("TAP TO START ", "OK" if ok else "FALLO")
	get_tree().quit(0 if ok else 1)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

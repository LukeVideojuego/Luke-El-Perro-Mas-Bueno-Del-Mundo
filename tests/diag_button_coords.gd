extends Node

## Punto 3: imprime el centro (en pixeles de ventana) de los botones que la
## prueba en el navegador tiene que tocar, para un tamaño de ventana dado.

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	get_window().size = Vector2i(int(args[0]), int(args[1]))
	await get_tree().process_frame
	await get_tree().process_frame
	TouchControls.touch_mode = args.has("touch")
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	for i in 10:
		await get_tree().process_frame
	var menu: Node = main.get_node("MainMenu")
	menu.difficulty_panel.visible = true
	for i in 3:
		await get_tree().process_frame
	_p("nuevo", menu.new_game_button)
	_p("cargar", menu.continue_button)
	_p("normal", menu.normal_button)
	var intro: Node = load("res://scenes/cinematics/intro_cinematic.tscn").instantiate()
	add_child(intro)
	for i in 3:
		await get_tree().process_frame
	_p("siguiente", intro.get_node("Panel1/Panel1Button"))
	get_tree().quit()

func _p(label: String, c: Control) -> void:
	var center := get_tree().root.get_final_transform() * c.get_global_rect().get_center()
	print("COORD ", label, " ", int(center.x), " ", int(center.y))

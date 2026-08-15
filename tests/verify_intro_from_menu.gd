extends Node2D

const MAIN_SCENE := preload("res://scenes/main.tscn")
var main: Node
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	main = MAIN_SCENE.instantiate()
	add_child(main)

func _save(label: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://../shot_%s.png" % label)
	print("SAVED shot_", label)

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 10:
		await RenderingServer.frame_post_draw
		_save("menu_before_click")
	if frame == 15:
		# Simula al usuario haciendo click real en "COMENZAR JUEGO" del menú.
		var menu = main.get_node_or_null("MainMenu")
		if menu == null:
			print("ERROR: MainMenu no encontrado (game_started ya en true?)")
		else:
			menu.new_game_button.pressed.emit()
	if frame == 30:
		await RenderingServer.frame_post_draw
		_save("real_intro_panel1")
		print("has_seen_intro=", GameState.has_seen_intro, " intro_cinematic=", main.intro_cinematic)
	if frame == 35:
		if main.intro_cinematic == null:
			print("ERROR: intro_cinematic es null en frame 35, la intro no se mostró")
		else:
			var p1btn = main.intro_cinematic.get_node("Panel1/Panel1Button")
			p1btn.pressed.emit()
	if frame == 45:
		await RenderingServer.frame_post_draw
		_save("real_intro_panel2")
	if frame == 50:
		var p2btn = main.intro_cinematic.get_node("Panel2/Panel2Button")
		p2btn.pressed.emit()
	if frame == 60:
		await RenderingServer.frame_post_draw
		_save("real_intro_panel3")
	if frame == 65:
		get_tree().quit()

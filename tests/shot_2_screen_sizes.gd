extends Node

## Punto 2: capturas reales del juego a distintos tamaños de pantalla.
## Uso (SIN --headless):
##   godot --path . res://tests/shot_2_screen_sizes.tscn -- <ancho> <alto> <nombre> [touch]
## Saca menu, tienda, nivel, jefe, bonus, cinematica, album y Game Over, y
## de paso revisa que ninguna captura tenga zonas grises del motor (el color
## de fondo por defecto, 0.3/0.3/0.3) ni bordes vacios.

const MAIN_SCENE := preload("res://scenes/main.tscn")

var main: Node
var tag := ""
var failures := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	var size := Vector2i(int(args[0]), int(args[1]))
	tag = args[2]
	TouchControls.touch_mode = args.has("touch")
	RenderingServer.set_default_clear_color(Color(0.3, 0.3, 0.3))
	get_window().size = size
	await _frames(10)
	print("VENTANA ", get_window().size, " area visible ", get_viewport().get_visible_rect().size)
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await _frames(40)
	await _shot("menu")

	main._on_album_requested()
	await _frames(20)
	await _shot("album")
	main._on_album_closed()

	main._free_menu()
	main.game_started = true
	GameState.reset_for_new_game()
	main.show_shop_if_needed("world_1_level_3")
	await _frames(30)
	await _shot("tienda")
	main.shop_screen.get_node("Panel/Footer/SkipButton").pressed.emit()
	await _frames(5)

	main.load_level("world_1_level_1")
	await _frames(90)
	await _shot("nivel")

	main.load_level("world_2_boss")
	await _frames(90)
	await _shot("jefe")

	main.load_level("world_1_level_2")
	await _frames(30)
	var dig: Node = null
	for n in main.active_level.get_children():
		if n is DigSpot:
			dig = n
	main._on_bonus_requested(dig.bonus_scene_path, dig.global_position)
	await _frames(90)
	await _shot("bonus")
	main.active_bonus.queue_free()
	main.active_bonus = null

	main.show_intro_cinematic()
	await _frames(80)
	await _shot("cinematica")
	main.intro_cinematic.queue_free()
	main.intro_cinematic = null
	await _frames(5)

	main._on_out_of_lives("world_1_level_1")
	await _frames(30)
	await _shot("gameover")
	main._free_game_over_screen()

	if args.has("touch"):
		get_window().size = Vector2i(size.y, size.x)
		await _frames(30)
		await _shot("vertical")
		_check(ScreenFit._rotate_notice.visible and get_tree().paused, "en vertical aparece el aviso y el juego se congela")
		get_window().size = size
		await _frames(30)
		_check(not ScreenFit._rotate_notice.visible and not get_tree().paused, "al volver a horizontal se va el aviso y sigue el juego")
	print("CAPTURAS TERMINADAS ", tag, " fallos=", failures)
	get_tree().quit(failures)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: ", label)
	else:
		failures += 1
		printerr("FAIL: ", label)

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://../shot2_%s_%s.png" % [tag, name])
	print("GUARDADA shot2_", tag, "_", name, " ", img.get_size())
	_check(_gray_ratio(img) < 0.05, "%s/%s sin zonas grises (%.1f%%)" % [tag, name, _gray_ratio(img) * 100.0])

## Peor franja de borde (8px de ancho, en cada uno de los 4 lados): que
## fraccion de sus pixeles es exactamente el gris de fondo del motor. Una zona
## sin dibujar siempre toca algun borde de la pantalla.
func _gray_ratio(img: Image) -> float:
	var w := img.get_width()
	var h := img.get_height()
	var strips := [Rect2i(0, 0, 8, h), Rect2i(w - 8, 0, 8, h), Rect2i(0, 0, w, 8), Rect2i(0, h - 8, w, 8)]
	var worst := 0.0
	for r in strips:
		var gray := 0
		var total := 0
		for y in range(r.position.y, r.end.y, 2):
			for x in range(r.position.x, r.end.x, 2):
				var c := img.get_pixel(x, y)
				total += 1
				if absf(c.r - 0.3) < 0.01 and absf(c.g - 0.3) < 0.01 and absf(c.b - 0.3) < 0.01:
					gray += 1
		worst = maxf(worst, float(gray) / float(total))
	return worst

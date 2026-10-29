extends Node

## Punto 2: capturas reales (SIN --headless) de la partida con la camara
## acercada para celular/tablet, y chequeos medidos:
##  - Luke se ve al menos 60px (CSS) de alto en un celular apaisado
##  - en el jefe, el jefe entra COMPLETO en pantalla (lejos y cerca de Luke)
##  - nada de zonas grises (la camara nunca sale del fondo)
## Uso:
##   godot --path . res://tests/shot_2w_zoom.tscn -- <ancho> <alto> <nombre> [touch]

const MAIN_SCENE := preload("res://scenes/main.tscn")

var main: Node
var tag := ""
var failures := 0
var size := Vector2i.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	size = Vector2i(int(args[0]), int(args[1]))
	tag = args[2]
	TouchControls.touch_mode = args.has("touch")
	RenderingServer.set_default_clear_color(Color(0.3, 0.3, 0.3))
	get_window().size = size
	await _frames(10)
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await _frames(20)
	main._free_menu()
	main.game_started = true
	GameState.reset_for_new_game()
	print("alto de mundo visible: ", ScreenFit.gameplay_view_height())

	main.load_level("world_1_level_1")
	await _frames(90)
	await _shot("nivel_inicio")
	_check_luke_size()
	var luke: Luke = main.active_level.get_node("Luke")
	luke.global_position = Vector2(2400, 850)
	await _frames(90)
	await _shot("nivel_medio")

	for boss_level in ["world_2_boss", "world_4_boss"]:
		main.load_level(boss_level)
		luke = main.active_level.get_node("Luke")
		luke.can_receive_damage = false
		await _frames(60)
		await _check_boss_inside(boss_level + " lejos")
		await _shot(boss_level + "_lejos")
		var boss := ScreenFit._find_boss(luke.get_node("Camera2D"), luke)
		if boss != null:
			luke.global_position = Vector2(maxf(boss.global_position.x - 330.0, 150.0), 850.0)
		await _frames(30)
		await _check_boss_inside(boss_level + " cerca")
		await _shot(boss_level + "_cerca")

	main.load_level("world_1_level_2")
	await _frames(30)
	var dig: Node = null
	for n in main.active_level.get_children():
		if n is DigSpot:
			dig = n
	main._on_bonus_requested(dig.bonus_scene_path, dig.global_position)
	await _frames(90)
	await _shot("bonus")
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

## Rectangulo visible de la camara actual, en coordenadas del mundo.
func _view_rect() -> Rect2:
	var xf := get_viewport().get_canvas_transform()
	return xf.affine_inverse() * get_viewport().get_visible_rect()

func _check_luke_size() -> void:
	var luke: Luke = main.active_level.get_node("Luke")
	var view := _view_rect()
	var px := 110.0 / view.size.y * float(size.y)
	print("Luke en pantalla: ~%.0f px de alto (mundo visible %s)" % [px, view.size])
	if TouchControls.touch_mode and size.y <= 400:
		_check(px >= 60.0, "%s: Luke se ve grande (%.0f px >= 60)" % [tag, px])

## Durante 90 cuadros (el jefe se mueve, salta, la camara lo sigue): el
## jefe tiene que estar COMPLETO en pantalla, junto con Luke. Solo se
## perdona si Luke y el jefe estan tan separados en altura que ni con la
## camara lo mas lejos posible entrarian los dos, o si el jefe todavia esta
## entrando desde arriba del fondo (la serpiente al empezar).
func _check_boss_inside(label: String) -> void:
	var luke: Luke = main.active_level.get_node("Luke")
	var cam: Camera2D = luke.get_node("Camera2D")
	var limits := Rect2(cam.limit_left, cam.limit_top, cam.limit_right - cam.limit_left, cam.limit_bottom - cam.limit_top)
	var max_view_h := get_viewport().get_visible_rect().size.y / maxf(
			get_viewport().get_visible_rect().size.x / limits.size.x,
			get_viewport().get_visible_rect().size.y / limits.size.y)
	var ok := 0
	var excused := 0
	var total := 0
	for i in 90:
		await get_tree().process_frame
		var boss := ScreenFit._find_boss(cam, luke)
		if boss == null:
			continue
		total += 1
		# Sin contar la franja de arriba donde esta el HUD.
		var view := _view_rect()
		var hud := ScreenFit.HUD_BAND / get_viewport().get_canvas_transform().get_scale().y
		view = Rect2(view.position + Vector2(0, hud), view.size - Vector2(0, hud))
		var r := ScreenFit._boss_rect(boss).intersection(limits)
		var both := r.merge(Rect2(luke.global_position + Vector2(-60, -110), Vector2(120, 130)))
		if view.grow(4.0).encloses(r) and view.has_point(luke.global_position):
			ok += 1
		elif r.position.y <= limits.position.y + 1.0:
			# Todavia entrando desde arriba del fondo (la serpiente al
			# empezar): esa parte no existe en pantalla para ninguna camara.
			excused += 1
		elif both.size.y > max_view_h - ScreenFit.HUD_BAND / (get_viewport().get_visible_rect().size.y / max_view_h) - 20.0:
			excused += 1
		elif i % 15 == 0:
			print("  fuera: jefe ", r, " vista ", view, " luke ", luke.global_position)
	_check(total > 0 and ok + excused >= int(total * 0.9),
			"%s %s: jefe completo en pantalla junto a Luke en %d/%d cuadros (+%d imposibles por altura)" % [tag, label, ok, total, excused])

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://../shot2w_%s_%s.png" % [tag, name])
	print("GUARDADA shot2w_", tag, "_", name)
	var gray := _gray_ratio(img)
	_check(gray < 0.05, "%s/%s sin zonas grises (%.1f%%)" % [tag, name, gray * 100.0])

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

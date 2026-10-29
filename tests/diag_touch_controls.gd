extends Node

## Punto 1: prueba de los controles tactiles con toques REALES (eventos
## InputEventScreenTouch inyectados en la ventana, el mismo camino que un
## dedo en el celular), no llamando funciones a mano:
##  - menu: tocar CONTRASEÑA, escribir HUESO3 con el teclado en pantalla y
##    tocar IR AL NIVEL -> carga world_1_level_2
##  - flecha derecha mueve; mantenida > 0.5s corre; saltar a la vez (2 dedos)
##  - doble toque en ATACAR lanza el huesito
##  - cualquier boton abre el globo del chico cercano
##  - ATACAR x3 parado en el pozo entra al bonus
##  - PAUSA pausa y oculta los botones
## Saca capturas en el camino. Correr SIN --headless.

const MAIN_SCENE := preload("res://scenes/main.tscn")

var main: Node
var failures := 0
var shot_prefix := "shot1_touch"
var shot_taken_shop := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_window().size = Vector2i(1280, 720)
	TouchControls.touch_mode = true
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await _frames(60)
	await _run()
	print("TOUCH TEST TERMINADO, fallos=", failures)
	get_tree().quit(failures)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and OS.get_cmdline_user_args().has("--dbg"):
		print("DBG ev idx=", event.index, " pressed=", event.pressed, " pos=", event.position, " frame=", Engine.get_physics_frames())

func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: ", label)
	else:
		failures += 1
		printerr("FAIL: ", label)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _to_window(canvas_pos: Vector2) -> Vector2:
	return get_tree().root.get_final_transform() * canvas_pos

func _touch(index: int, canvas_pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = index
	ev.position = _to_window(canvas_pos)
	ev.pressed = pressed
	Input.parse_input_event(ev)

func _tap(canvas_pos: Vector2, index: int = 0) -> void:
	_touch(index, canvas_pos, true)
	await _frames(2)
	_touch(index, canvas_pos, false)
	await _frames(2)

func _center_of_control(c: Control) -> Vector2:
	return c.get_global_rect().get_center()

func _center_of_button(b: TouchScreenButton) -> Vector2:
	return b.global_position + b.texture_normal.get_size() * 0.5

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../%s_%s.png" % [shot_prefix, name])
	print("GUARDADA ", shot_prefix, "_", name)

func _btn(name: String) -> TouchScreenButton:
	return TouchControls.get_node(name) as TouchScreenButton

func _level() -> Node:
	return main.active_level

func _luke() -> Luke:
	return main.active_level.get_node("Luke") as Luke

func _run() -> void:
	# --- MENU + CONTRASEÑA con el teclado en pantalla ---
	var menu: Node = main.get_node("MainMenu")
	_check(not _btn("JumpButton").visible, "en el menu no se ven los botones de juego")
	await _tap(_center_of_control(menu.password_button))
	await _frames(3)
	var kb: Control = menu.get_node_or_null("PasswordPanel/TouchKeyboard")
	_check(menu.password_panel.visible and kb != null, "tocar CONTRASEÑA abre el panel con teclado en pantalla")
	await _shot("password_keyboard")
	for ch in "HUESX":
		await _tap(_center_of_control(_find_key(kb, ch)))
	await _tap(_center_of_control(_find_key(kb, "<")))
	for ch in "O3":
		await _tap(_center_of_control(_find_key(kb, ch)))
	_check(menu.password_input.text == "HUESO3", "teclado en pantalla escribe HUESO3 (con BORRAR) -> '%s'" % menu.password_input.text)
	await _tap(_center_of_control(menu.password_submit))
	for i in 400:
		await _frames(1)
		if main.active_level != null and main.shop_screen == null and not main.get_node("LevelTransition/Overlay").visible:
			break
		var shop: Node = main.shop_screen
		if shop != null:
			# La tienda tambien se maneja con toque: "JUGAR EL NIVEL".
			await _frames(20)
			if not shot_taken_shop:
				shot_taken_shop = true
				await _shot("shop")
			if is_instance_valid(shop):
				await _tap(_center_of_control(shop.get_node("Panel/Footer/SkipButton")))
			await _frames(10)
	_check(GameState.current_level_id == "world_1_level_2" and main.active_level != null, "IR AL NIVEL (toque) carga world_1_level_2")
	await _frames(30)
	_check(_btn("JumpButton").visible and _btn("LeftButton").visible and _btn("PauseButton").visible, "en la partida aparecen los botones tactiles")
	await _shot("gameplay")

	# --- MOVER / CORRER / SALTAR a la vez ---
	var luke := _luke()
	# Arranca en una zona plana y libre, ya apoyado en el piso.
	luke.global_position = Vector2(1250, luke.global_position.y - 40)
	for i in 120:
		await _frames(1)
		if luke.is_on_floor():
			break
	await _frames(10)
	var right := _center_of_button(_btn("RightButton"))
	var jump := _center_of_button(_btn("JumpButton"))
	_touch(0, right, true)
	await _frames(15)
	_check(luke.velocity.x > 50.0 and not Input.is_action_pressed("run"), "flecha derecha camina (vx=%.0f)" % luke.velocity.x)
	await _frames(30)
	await _frames(15)
	_check(Input.is_action_pressed("run") and luke.velocity.x > luke.walk_speed + 20.0, "mantener la flecha > 0.5s corre (vx=%.0f)" % luke.velocity.x)
	await _shot("running")
	_touch(1, jump, true)
	await _frames(2)
	_check(luke.velocity.y < -100.0 and Input.is_action_pressed("run"), "segundo dedo en SALTAR salta mientras sigue corriendo (vy=%.0f)" % luke.velocity.y)
	_touch(1, jump, false)
	await _frames(2)
	_touch(0, right, false)
	await _frames(3)
	_check(not Input.is_action_pressed("run") and not Input.is_action_pressed("move_right"), "al soltar se deja de correr")
	await _frames(60)

	# --- DOBLE TOQUE EN ATACAR = huesito ---
	GameState.bone_throw_unlocked = true
	var attack := _center_of_button(_btn("AttackButton"))
	var before := _count_bones()
	await _tap(attack)
	await _frames(2)
	await _tap(attack)
	await _frames(2)
	_check(_count_bones() > before, "doble toque en ATACAR lanza el huesito")
	await _frames(40)

	# --- GLOBO DEL CHICO ---
	var kid: Node2D = null
	for n in _level().get_children():
		if n is KidNpc:
			kid = n
	luke.global_position = kid.global_position + Vector2(-60, -30)
	luke.velocity = Vector2.ZERO
	for i in 120:
		await _frames(1)
		if kid.nearby_player != null:
			break
		luke.global_position = kid.global_position + Vector2(-60, -30)
	await _tap(_center_of_button(_btn("LeftButton")))
	await _frames(3)
	_check(kid.hint_label.visible, "tocar un boton junto al chico abre su globo")
	await _frames(20)

	# --- PAUSA ---
	await _tap(_center_of_button(_btn("PauseButton")))
	await _frames(3)
	_check(get_tree().paused and not _btn("JumpButton").visible, "PAUSA pausa el juego y oculta los botones")
	await _shot("pause")
	var pause_screen: Node = main.get_node("PauseScreen")
	await _tap(_center_of_control(pause_screen.resume_button))
	await _frames(3)
	_check(not get_tree().paused, "REANUDAR (toque) despausa")

	# --- CAVAR EN EL POZO DEL BONUS con ATACAR ---
	var dig: Node2D = _level().find_child("DigSpot*", true, false)
	if dig == null:
		for n in _level().get_children():
			if n is DigSpot:
				dig = n
	_check(dig != null, "world_1_level_2 tiene pozo de bonus")
	if dig != null:
		luke.global_position = dig.global_position + Vector2(0, -60)
		luke.velocity = Vector2.ZERO
		await _frames(40)
		for i in 3:
			await _tap(attack)
			await _frames(25)
		await _frames(10)
		_check(main.active_bonus != null, "ATACAR x3 en el pozo entra al bonus")
		await _frames(30)
		_check(_btn("JumpButton").visible, "en el bonus siguen los botones tactiles")
		await _shot("bonus")

func _count_bones() -> int:
	var n := 0
	for c in _level().get_children():
		if c.scene_file_path.ends_with("thrown_bone.tscn") or c.scene_file_path.ends_with("bark_wave.tscn"):
			n += 1
	return n

func _find_key(kb: Control, key: String) -> Button:
	for row in kb.get_children():
		for b in row.get_children():
			if (b as Button).text == key or (key == "<" and b.text == "BORRAR"):
				return b
	return null

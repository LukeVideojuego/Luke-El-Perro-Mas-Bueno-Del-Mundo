extends Node2D

## E3: capturas reales de la capa en las 4 fases pedidas (quieto, corriendo,
## subiendo, cayendo), usando fisica real de Luke (no poses forzadas).
const LUKE_SCENE := preload("res://scenes/player/player.tscn")

var luke: Luke
var cam: Camera2D
var frame := 0
var phase_frame := 0
var phase := 0
const PHASES := ["quieto", "corriendo", "subiendo", "cayendo"]

func _ready() -> void:
	get_window().size = Vector2i(900, 700)
	GameState.reset_for_new_game()
	GameState.coins = 300
	GameState.buy_item("suit_cape")

	var bg := ColorRect.new()
	bg.size = Vector2(2200, 3200)
	bg.position = Vector2(-200, -2300)
	bg.color = Color(0.35, 0.45, 0.58)
	bg.z_index = -20
	add_child(bg)

	var ground := StaticBody2D.new()
	ground.collision_layer = 1
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(3000.0, 80.0)
	cs.shape = rect
	ground.add_child(cs)
	ground.position = Vector2(500.0, 700.0)
	add_child(ground)

	luke = LUKE_SCENE.instantiate()
	luke.position = Vector2(400.0, 600.0)
	add_child(luke)

	cam = Camera2D.new()
	cam.position = Vector2(440, 580)
	cam.zoom = Vector2(2.0, 2.0)
	add_child(cam)
	cam.make_current()

func _physics_process(_delta: float) -> void:
	if phase >= PHASES.size():
		return
	frame += 1
	cam.position = luke.global_position + Vector2(40, -80)
	phase_frame += 1
	var name_now: String = PHASES[phase]
	match name_now:
		"quieto":
			Input.action_release("move_right")
			Input.action_release("jump")
			if phase_frame == 50:
				_save_and_advance()
		"corriendo":
			Input.action_press("move_right")
			Input.action_press("run")
			Input.action_release("jump")
			if phase_frame == 40:
				_save_and_advance()
		"subiendo":
			Input.action_release("move_right")
			# Dejar que la capa termine de asentarse (cuelgue recta) despues
			# de "corriendo" ANTES de saltar -- si se salta apenas termina de
			# correr, la cadena todavia esta oscilando hacia atras por la
			# inercia de la corrida y el salto la agarra a mitad de swing,
			# dando una forma rara que no es realmente "por el salto".
			if phase_frame == 25:
				Input.action_press("jump")
			elif phase_frame == 26:
				Input.action_release("jump")
			# Capturar mientras todavia esta claramente subiendo.
			if phase_frame == 36 and luke.velocity.y < -200.0:
				_save_and_advance()
			elif phase_frame > 55:
				_save_and_advance()
		"cayendo":
			Input.action_release("move_right")
			Input.action_release("jump")
			# Continuacion natural del mismo salto de "subiendo" (ya paso el
			# pico y esta bajando) -- se captura poco despues de que empieza
			# a caer, cuando la cadena todavia esta oscilando por el cambio
			# subir->bajar (eso es la "ondulacion" pedida), antes de que
			# llegue a aterrizar.
			if phase_frame >= 26 and luke.velocity.y > 400.0:
				_save_and_advance()
			elif phase_frame > 33:
				_save_and_advance()

func _save_and_advance() -> void:
	await RenderingServer.frame_post_draw
	var path := "res://../shotE3_%s.png" % PHASES[phase]
	get_viewport().get_texture().get_image().save_png(path)
	var anchor: Vector2 = luke.cape_ribbon._points[0]
	var tip: Vector2 = luke.cape_ribbon._points[luke.cape_ribbon._points.size() - 1]
	print("GUARDADA ", path, "  vel=", luke.velocity,
		"  anchor=", anchor, " tip=", tip, " tip-anchor=", tip - anchor)
	phase += 1
	phase_frame = 0
	if phase >= PHASES.size():
		get_tree().quit()

extends CanvasLayer

## Punto 1: controles en pantalla para celular/tablet. Solo aparecen en
## dispositivos tactiles (en una compu con teclado no se ven) y solo durante
## la partida (no en menus, tienda, cinematicas, pausa ni Game Over: esas
## pantallas ya son botones normales, que el toque aprieta igual que el
## mouse gracias a emulate_mouse_from_touch).
##
## Cada boton es un TouchScreenButton con su "action" del InputMap, asi que
## para el juego es exactamente lo mismo que apretar la tecla: el doble toque
## en ATACAR lanza el huesito/ladrido, cualquier boton abre el globo de los
## chicos, ATACAR cava en el pozo del bonus, etc. TouchScreenButton sigue cada
## dedo por separado, asi que se pueden apretar dos a la vez (correr + saltar).
##
## Correr: mantener apretada una flecha mas de RUN_HOLD_TIME activa "run"
## hasta soltarla (la flecha se tiñe de naranja para que se note).

const RUN_HOLD_TIME := 0.5
const MARGIN := 40.0
const IDLE_ALPHA := 0.7
## Si Luke (u otra cosa importante) queda detras de un boton, ese boton se
## vuelve casi transparente para no taparlo.
const BEHIND_ALPHA := 0.25
const RUN_TINT := Color(1.0, 0.7, 0.35)

var touch_mode := false

var _left: TouchScreenButton
var _right: TouchScreenButton
var _jump: TouchScreenButton
var _attack: TouchScreenButton
var _pause: TouchScreenButton
var _hold_time := 0.0
var _running := false

func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	touch_mode = DisplayServer.is_touchscreen_available() \
			or OS.get_cmdline_user_args().has("--touch")
	_left = _make_button("left", "move_left", 240.0)
	_right = _make_button("right", "move_right", 240.0)
	_jump = _make_button("jump", "jump", 300.0)
	_attack = _make_button("attack", "attack", 250.0)
	_pause = _make_button("pause", "pause", 140.0)
	# Deslizar el dedo de una flecha a la otra cambia de direccion sin
	# tener que levantarlo.
	_left.passby_press = true
	_right.passby_press = true
	get_viewport().size_changed.connect(_layout)
	_layout()
	_set_shown(false)

func _make_button(tex_name: String, action: String, diameter: float) -> TouchScreenButton:
	var b := TouchScreenButton.new()
	b.name = tex_name.capitalize() + "Button"
	b.texture_normal = load("res://assets/ui/touch/%s.png" % tex_name)
	b.texture_pressed = load("res://assets/ui/touch/%s_pressed.png" % tex_name)
	var shape := CircleShape2D.new()
	# Zona de toque un poco mas grande que el dibujo: dedos de niño.
	shape.radius = diameter * 0.56
	b.shape = shape
	b.shape_centered = true
	b.action = action
	b.modulate.a = IDLE_ALPHA
	add_child(b)
	return b

## Posiciones ancladas a las esquinas del area visible real (que con el
## escalado "expand" puede ser mas ancha o mas alta que 1920x1080).
func _layout() -> void:
	var s := get_viewport().get_visible_rect().size
	_place(_left, Vector2(MARGIN, s.y - MARGIN - 240.0))
	_place(_right, Vector2(MARGIN + 240.0 + 40.0, s.y - MARGIN - 240.0))
	_place(_jump, Vector2(s.x - MARGIN - 300.0, s.y - MARGIN - 300.0 - 40.0))
	_place(_attack, Vector2(s.x - MARGIN - 300.0 - 40.0 - 250.0, s.y - MARGIN - 250.0))
	_place(_pause, Vector2(s.x - MARGIN - 140.0, MARGIN))

func _place(b: TouchScreenButton, top_left: Vector2) -> void:
	b.position = top_left

func _input(event: InputEvent) -> void:
	# Un navegador de compu a veces no avisa que hay pantalla tactil hasta
	# el primer toque real.
	if not touch_mode and event is InputEventScreenTouch:
		touch_mode = true

func _process(delta: float) -> void:
	var shown := touch_mode and _gameplay_active()
	if shown != _left.visible:
		_set_shown(shown)
	if not shown:
		return
	if _left.is_pressed() or _right.is_pressed():
		_hold_time += delta
		if not _running and _hold_time >= RUN_HOLD_TIME:
			_running = true
			Input.action_press("run")
	else:
		_hold_time = 0.0
		_stop_running()
	var luke_pos: Variant = _luke_canvas_position()
	for b in [_left, _right, _jump, _attack, _pause]:
		var tint: Color = RUN_TINT if _running and (b == _left or b == _right) else Color.WHITE
		tint.a = BEHIND_ALPHA if luke_pos != null and _covers(b, luke_pos) else IDLE_ALPHA
		b.modulate = tint

## Posicion de Luke en pantalla (coordenadas del canvas, con la camara ya
## aplicada), o null si no hay Luke.
func _luke_canvas_position() -> Variant:
	var main := get_tree().get_first_node_in_group("main_game")
	var holder: Node = main.get("active_bonus") if main.get("active_bonus") != null else main.get("active_level")
	if holder == null or not is_instance_valid(holder):
		return null
	var luke := holder.get_node_or_null("Luke") as Node2D
	if luke == null:
		return null
	return luke.get_global_transform_with_canvas().origin + Vector2(0, -40)

## Luke mide ~110px de alto: se toma un margen alrededor del circulo.
func _covers(b: TouchScreenButton, pos: Vector2) -> bool:
	var size := b.texture_normal.get_size()
	var center := b.position + size * 0.5
	return center.distance_to(pos) < size.x * 0.5 + 70.0

func _stop_running() -> void:
	if _running:
		_running = false
		Input.action_release("run")

func _set_shown(value: bool) -> void:
	for b in [_left, _right, _jump, _attack, _pause]:
		b.visible = value
	if not value:
		_hold_time = 0.0
		_stop_running()
		for action in ["move_left", "move_right", "jump", "attack", "pause"]:
			if Input.is_action_pressed(action):
				Input.action_release(action)

## Partida en curso: hay un nivel cargado y nada encima tapandolo.
func _gameplay_active() -> bool:
	if get_tree().paused:
		return false
	var main := get_tree().get_first_node_in_group("main_game")
	if main == null:
		return false
	var level: Variant = main.get("active_level")
	if level == null or not is_instance_valid(level):
		return false
	for overlay in ["shop_screen", "game_over_screen", "intro_cinematic",
			"final_cinematic", "world1_cheer_screen"]:
		var node: Variant = main.get(overlay)
		if node != null and is_instance_valid(node):
			return false
	return true

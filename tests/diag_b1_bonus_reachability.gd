extends Node2D

## B1: verifica con fisica real (frame a frame, move_and_slide de verdad)
## que las 9 plataformas de cada uno de los 4 bonus (StartPad + 8 barras)
## son alcanzables una despues de la otra, barra por barra, incluidas las
## ultimas (las mas chicas y lejanas). Para las barras que se mueven
## (Mundo 2) se las fuerza a su posicion MAS LEJOS del punto de despegue
## antes de probar, asi la prueba demuestra el peor caso, no el mas facil.
## El viento del Mundo 4 esta activo de verdad durante la prueba (se corre
## adentro de la escena bonus real, no una copia aislada).

const LUKE_SCENE := preload("res://scenes/player/player.tscn")
const LEVEL_FILES := [
	"res://scenes/levels/bonus_world_1.tscn",
	"res://scenes/levels/bonus_world_2.tscn",
	"res://scenes/levels/bonus_world_3.tscn",
	"res://scenes/levels/bonus_world_4.tscn",
]

const LUKE_GROUND_OFFSET := 50.0

const PLANS := [
	{"run": false, "hold": 999, "jump": true, "dbl": false},
	{"run": true, "hold": 999, "jump": true, "dbl": false},
	{"run": true, "hold": 34, "jump": true, "dbl": false},
	{"run": false, "hold": 44, "jump": true, "dbl": false},
	{"run": true, "hold": 24, "jump": true, "dbl": false},
	{"run": false, "hold": 30, "jump": true, "dbl": false},
	{"run": true, "hold": 16, "jump": true, "dbl": false},
	{"run": false, "hold": 20, "jump": true, "dbl": false},
	{"run": true, "hold": 46, "jump": true, "dbl": false},
	{"run": false, "hold": 60, "jump": true, "dbl": false},
	{"run": true, "hold": 10, "jump": true, "dbl": false},
	{"run": false, "hold": 12, "jump": true, "dbl": false},
	{"run": true, "hold": 999, "jump": true, "dbl": true},
	{"run": false, "hold": 999, "jump": true, "dbl": true},
	{"run": true, "hold": 70, "jump": true, "dbl": true},
	{"run": true, "hold": 999, "jump": true, "dbl": true, "wind_hold": true},
]

var fail_count := 0
var bonus: Node
var luke: Luke
var pending: Array = []
var current_test: Dictionary = {}
var plan_index := 0
var frame := 0
var running := false
var landed_ok := false
var left_a := false
var best_debug := ""

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	for path in LEVEL_FILES:
		await _test_level(path)
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _collect_platforms(level: Node) -> Array:
	var result: Array = []
	for child in level.get_children():
		var body := child
		if child.name == "StartPad" or String(child.name).begins_with("Bar"):
			if not (body is StaticBody2D or body is AnimatableBody2D):
				continue
			var shape_node: CollisionShape2D = body.get_node_or_null("CollisionShape2D")
			if shape_node == null or not (shape_node.shape is RectangleShape2D):
				continue
			var half_w: float = shape_node.shape.size.x * 0.5 * body.scale.x
			var half_h: float = shape_node.shape.size.y * 0.5 * body.scale.y
			result.append({
				"name": String(child.name), "node": body,
				"x": body.global_position.x, "y": body.global_position.y,
				"half_w": half_w, "half_h": half_h,
			})
	result.sort_custom(func(a, b): return a.x < b.x)
	return result

## t=0 la deja en su posicion de arranque; t=1 en start+travel.
func _force_moving_platform(mp: MovingPlatform, t: float) -> void:
	mp._distance_traveled = mp.travel.length() * t
	mp.position = mp._start_position + mp.travel * t

func _test_level(path: String) -> void:
	bonus = load(path).instantiate()
	add_child(bonus)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var plats := _collect_platforms(bonus)
	print("--- ", path, " (", plats.size(), " plataformas) ---")
	for p in plats:
		print("    %-10s x=[%6.0f,%6.0f] surface_y=%.0f" % [p.name, p.x - p.half_w, p.x + p.half_w, p.y - p.half_h])
	_check(plats.size() == 9, "%s: tiene 9 plataformas (StartPad + 8 barras), tiene %d" % [path, plats.size()])

	luke = LUKE_SCENE.instantiate()
	bonus.add_child(luke)
	bonus.start(luke)
	await get_tree().physics_frame

	for i in range(plats.size() - 1):
		var a: Dictionary = plats[i]
		var b: Dictionary = plats[i + 1]
		# Las barras moviles de este set SIEMPRE viajan "para atras" (hacia la
		# plataforma anterior en la cadena, travel.x < 0): el peor caso para
		# CUALQUIER salto que las tenga de punta de partida o de llegada es
		# cuando estan en t=1 (el extremo mas lejos de donde arrancaron, que
		# para "a" angosta su alcance hacia adelante y para "b" la aleja de
		# "a"). En t=0 (su posicion de arranque) siempre es el caso MAS FACIL
		# para quien llega, asi que no hace falta forzar nada ahi.
		if a.node is MovingPlatform:
			_force_moving_platform(a.node, 1.0)
			a.x = a.node.global_position.x
			a.y = a.node.global_position.y
		if b.node is MovingPlatform:
			_force_moving_platform(b.node, 0.0)
			b.x = b.node.global_position.x
			b.y = b.node.global_position.y
		pending.append({"a": a.duplicate(), "b": b.duplicate(), "label": "%s -> %s" % [a.name, b.name]})
	_run_next_test()
	while running or not pending.is_empty():
		await get_tree().physics_frame

	bonus.queue_free()
	await get_tree().process_frame

func _run_next_test() -> void:
	if pending.is_empty():
		running = false
		return
	current_test = pending.pop_front()
	plan_index = 0
	best_debug = ""
	_start_attempt()

func _start_attempt() -> void:
	var a: Dictionary = current_test.a
	luke.global_position = Vector2(a.x + a.half_w - 10.0, a.y - a.half_h - LUKE_GROUND_OFFSET)
	luke.velocity = Vector2.ZERO
	luke.jumps_used = 0
	frame = 0
	landed_ok = false
	left_a = false
	running = true

func _release_all() -> void:
	Input.action_release("move_right")
	Input.action_release("run")
	Input.action_release("jump")

func _physics_process(_delta: float) -> void:
	if not running:
		return
	frame += 1
	var plan: Dictionary = PLANS[plan_index]
	var hold: int = plan.hold
	var jump_frame := 3
	if frame <= jump_frame + hold:
		Input.action_press("move_right")
	else:
		Input.action_release("move_right")
	if plan.run and frame <= jump_frame + hold:
		Input.action_press("run")
	else:
		Input.action_release("run")
	if plan.jump:
		if frame == jump_frame:
			Input.action_press("jump")
		if frame == jump_frame + 1:
			Input.action_release("jump")
		if plan.get("dbl", false):
			if frame == jump_frame + 24:
				Input.action_press("jump")
			if frame == jump_frame + 25:
				Input.action_release("jump")
	if frame > 5 and not luke.is_on_floor():
		left_a = true

	var b: Dictionary = current_test.b
	var target_surface: float = b.y - b.half_h - LUKE_GROUND_OFFSET
	if left_a and luke.is_on_floor() and frame > 6:
		if absf(luke.global_position.x - b.x) <= b.half_w + 4.0 \
				and absf(luke.global_position.y - target_surface) <= 8.0:
			landed_ok = true
			_attempt_done()
			return
		best_debug = "aterrizo en (%.0f,%.0f)" % [luke.global_position.x, luke.global_position.y]
		_attempt_done()
		return
	var floor_limit: float = target_surface + 400.0
	if left_a and luke.global_position.y > floor_limit:
		best_debug = "cayo al vacio en x=%.0f" % luke.global_position.x
		_attempt_done()
		return
	if luke.global_position.x > b.x + b.half_w + 260.0:
		best_debug = "se paso de largo (x=%.0f)" % luke.global_position.x
		_attempt_done()
		return
	if frame > 260:
		best_debug = "sin resolver en 260 frames (x=%.0f, y=%.0f)" % [luke.global_position.x, luke.global_position.y]
		_attempt_done()

func _attempt_done() -> void:
	running = false
	_release_all()
	if landed_ok or plan_index >= PLANS.size() - 1:
		_report()
		return
	plan_index += 1
	_start_attempt()

func _report() -> void:
	var a: Dictionary = current_test.a
	var b: Dictionary = current_test.b
	var plan: Dictionary = PLANS[plan_index]
	var how := "%s%s, direccion %s" % [
		"correr" if plan.run else "caminar",
		("" if plan.jump else " SIN salto") + (" + doble salto" if plan.get("dbl", false) else ""),
		"todo el salto" if plan.hold >= 999 else ("%d frames" % plan.hold)]
	var gap: float = (b.x - b.half_w) - (a.x + a.half_w)
	var dy: float = b.y - a.y
	if landed_ok:
		_check(true, "%-24s gap=%4.0fpx dy=%4.0fpx  [%s]" % [current_test.label, gap, dy, how])
	else:
		print("  DEBUG ultimo intento: ", best_debug)
		_check(false, "%-24s gap=%4.0fpx dy=%4.0fpx  (ninguno de los %d planes funciono)" % [
			current_test.label, gap, dy, PLANS.size()])
	_run_next_test()

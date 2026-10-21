extends Node2D

## A1: verifica con fisica real (frame a frame, move_and_slide de verdad) que
## la ruta de punta a punta del nivel acuatico (Mundo 4 Nivel 2) es 100%
## completable: cada isla tiene que ser alcanzable desde la anterior, y la
## meta tiene que ser alcanzable desde la ultima isla antes de ella.
##
## Diferencias con tests/diag_world2_reachability.gd:
##  1. Luke en este nivel tiene fisica propia (gravedad 950, salto -760, etc.
##     por overrides de instancia), asi que la simulacion los copia del Luke
##     real del nivel en vez de usar los del player.tscn base.
##  2. Con esa fisica flotante el salto llega a 310px de alto y mas de 500px
##     de largo: correr manteniendo la direccion apretada se pasa de largo de
##     una isla de 80px. Un jugador real suelta la direccion en el aire para
##     frenar (Luke desacelera tambien en el aire), asi que en vez de 3
##     estrategias fijas se prueba una grilla de planes de input realistas
##     (caminar/correr x cuantos frames se mantiene la direccion x salto
##     simple/doble) y el tramo cuenta como alcanzable si ALGUNO aterriza.

const LEVEL_PATH := "res://scenes/levels/world_4_level_2.tscn"
const LUKE_SCENE := preload("res://scenes/player/player.tscn")
## CollisionShape2D de Luke: position.y=8, size.y=84 (mitad=42) -> el borde
## inferior de su colision queda a origin.y + 50 respecto a su propio origen.
const LUKE_GROUND_OFFSET := 50.0
const MOVEMENT_PROPS := [
	"walk_speed", "run_speed", "ground_acceleration", "ground_deceleration",
	"air_acceleration", "gravity", "jump_velocity", "double_jump_velocity",
	"max_fall_speed",
]

## run = correr o caminar; hold = cuantos frames se mantiene apretada la
## direccion despues de despegar (999 = todo el salto); jump = false camina
## hasta caerse del borde (sirve para bajadas y plataformas solapadas).
const PLANS := [
	{"run": false, "hold": 999, "jump": true, "dbl": false},
	{"run": true, "hold": 999, "jump": true, "dbl": false},
	{"run": false, "hold": 999, "jump": false, "dbl": false},
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
]

var fail_count := 0
var luke_props := {}
var arena: Node2D
var luke: Luke
var frame := 0
var running := false
var pending: Array = []
var current_test: Dictionary = {}
var plan_index := 0
var landed_ok := false
var left_a := false
var best_debug := ""

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

## Toda la geometria sobre la que Luke puede pararse, de izquierda a derecha.
## Se excluyen las paredes invisibles de los bordes y el fondo marino (que es
## la zona letal, no parte de la ruta).
func _collect_platforms(level: Node) -> Array:
	var result: Array = []
	for child in level.get_children():
		if not (child is StaticBody2D):
			continue
		# Las cajas rompibles y la escalera secreta de la vida extra (C2) son
		# un bonus OPCIONAL fuera de la ruta principal forzada (su propia
		# alcanzabilidad la verifica tests/diag_secret_life.gd por separado);
		# si se las deja entrar aca, se cuelan en medio de la cadena de islas
		# principal y generan un salto que no es el que el jugador tiene que
		# hacer para terminar el nivel.
		if child.name.ends_with("Boundary") or child.name == "SeaFloor" or child is BreakableBox 				or child.name.begins_with("Secret"):
			continue
		var shape_node: CollisionShape2D = child.get_node_or_null("CollisionShape2D")
		if shape_node == null or not (shape_node.shape is RectangleShape2D):
			continue
		result.append({
			"name": child.name,
			"x": child.global_position.x + shape_node.position.x,
			"y": child.global_position.y + shape_node.position.y,
			"half_w": shape_node.shape.size.x / 2.0,
			"half_h": shape_node.shape.size.y / 2.0,
		})
	result.sort_custom(func(a, b): return a.x < b.x)
	return result

func _make_platform(parent: Node2D, x: float, y: float, half_w: float, half_h: float) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(half_w * 2.0, half_h * 2.0)
	shape.shape = rect
	body.add_child(shape)
	body.position = Vector2(x, y)
	parent.add_child(body)

func _ready() -> void:
	var level: Node = load(LEVEL_PATH).instantiate()
	add_child(level)
	var level_luke: Node = level.get_node_or_null("Luke")
	for prop in MOVEMENT_PROPS:
		luke_props[prop] = level_luke.get(prop)
	print("Fisica de Luke en este nivel: ", luke_props)
	var plats := _collect_platforms(level)
	print("--- ", LEVEL_PATH, " (", plats.size(), " plataformas) ---")
	for p in plats:
		print("    %-14s x=[%5.0f,%5.0f]  superficie_y=%.0f" % [p.name, p.x - p.half_w, p.x + p.half_w, p.y - p.half_h])
	for i in range(plats.size() - 1):
		var a: Dictionary = plats[i]
		var b: Dictionary = plats[i + 1]
		pending.append({
			"a": a, "b": b,
			"gap": (b.x - b.half_w) - (a.x + a.half_w),
			"label": "%s -> %s" % [a.name, b.name],
		})
	# Ultimo tramo: desde la isla inmediatamente anterior a la meta, llegar a
	# tocar su area (no hace falta aterrizar, alcanza con entrar).
	var finish: Node = level.get_node_or_null("Finish")
	if finish != null and plats.size() > 0:
		var fshape: CollisionShape2D = finish.get_node_or_null("CollisionShape2D")
		var fx: float = finish.global_position.x
		var fy: float = finish.global_position.y
		var before: Dictionary = plats[0]
		for p in plats:
			if p.x <= fx:
				before = p
		pending.append({
			"a": before,
			"b": {"name": "Finish", "x": fx, "y": fy,
				"half_w": fshape.shape.size.x / 2.0, "half_h": fshape.shape.size.y / 2.0},
			"gap": (fx - fshape.shape.size.x / 2.0) - (before.x + before.half_w),
			"label": "%s -> META" % before.name, "is_finish": true,
		})
	level.queue_free()
	_run_next_test()

func _run_next_test() -> void:
	if pending.is_empty():
		print("RESULTADO: ", fail_count, " fallos")
		get_tree().quit()
		return
	current_test = pending.pop_front()
	plan_index = 0
	best_debug = ""
	_start_attempt()

func _start_attempt() -> void:
	if arena != null:
		arena.queue_free()
		arena = null
	arena = Node2D.new()
	add_child(arena)
	var a: Dictionary = current_test.a
	var b: Dictionary = current_test.b
	_make_platform(arena, a.x, a.y, a.half_w, a.half_h)
	if not current_test.get("is_finish", false):
		_make_platform(arena, b.x, b.y, b.half_w, b.half_h)
	# piso de emergencia bien abajo para no caer al vacio infinito
	_make_platform(arena, (a.x + b.x) / 2.0, maxf(a.y, b.y) + 700.0, 5000.0, 40.0)
	luke = LUKE_SCENE.instantiate()
	for prop in MOVEMENT_PROPS:
		luke.set(prop, luke_props[prop])
	luke.position = Vector2(a.x + a.half_w - 10.0, a.y - a.half_h - LUKE_GROUND_OFFSET)
	arena.add_child(luke)
	luke.velocity = Vector2.ZERO
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
		if plan.dbl:
			if frame == jump_frame + 24:
				Input.action_press("jump")
			if frame == jump_frame + 25:
				Input.action_release("jump")
	if frame > 5 and not luke.is_on_floor():
		left_a = true

	var b: Dictionary = current_test.b
	var target_surface: float = b.y - b.half_h - LUKE_GROUND_OFFSET
	if current_test.get("is_finish", false):
		if absf(luke.global_position.x - b.x) <= b.half_w + 26.0 \
				and absf(luke.global_position.y - b.y) <= b.half_h + 42.0:
			landed_ok = true
			_attempt_done()
			return
	elif left_a and luke.is_on_floor() and frame > 6:
		if absf(luke.global_position.x - b.x) <= b.half_w + 4.0 \
				and absf(luke.global_position.y - target_surface) <= 6.0:
			landed_ok = true
			_attempt_done()
			return
		best_debug = "aterrizo en (%.0f,%.0f)" % [luke.global_position.x, luke.global_position.y]
		_attempt_done()
		return
	# cortes tempranos: ya cayo por debajo del objetivo o se paso de largo.
	# Para la meta (un area en el aire) el piso de referencia es su borde
	# inferior, no una superficie de aterrizaje.
	var floor_limit: float = target_surface + 90.0
	if current_test.get("is_finish", false):
		floor_limit = b.y + b.half_h + 160.0
	if left_a and luke.global_position.y > floor_limit:
		best_debug = "cayo al vacio en x=%.0f" % luke.global_position.x
		_attempt_done()
		return
	if luke.global_position.x > b.x + b.half_w + 220.0:
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
		("" if plan.jump else " SIN salto") + (" + doble salto" if plan.dbl else ""),
		"todo el salto" if plan.hold >= 999 else ("%d frames" % plan.hold)]
	if landed_ok:
		_check(true, "%-30s gap=%4.0fpx dy=%4.0fpx  [%s]" % [current_test.label, current_test.gap, b.y - a.y, how])
	else:
		print("  DEBUG ultimo intento: ", best_debug)
		_check(false, "%-30s gap=%4.0fpx dy=%4.0fpx  (ninguno de los %d planes de input funciono)" % [
			current_test.label, current_test.gap, b.y - a.y, PLANS.size()])
	_run_next_test()

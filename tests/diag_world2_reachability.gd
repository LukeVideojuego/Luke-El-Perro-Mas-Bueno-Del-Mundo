extends Node2D

## Punto 3 (tercera ronda): revisa el camino aereo COMPLETO de los 3 niveles
## de Corazones de Oro (Mundo 2) midiendo, con salto real simulado (fisica
## real, no formula), si Luke puede llegar de cada plataforma a la
## siguiente. Si algun tramo consecutivo no es saltable, se reporta como
## FAIL con la distancia exacta y las plataformas involucradas.

const LEVELS := [
	"res://scenes/levels/world_2_level_1.tscn",
	"res://scenes/levels/world_2_level_2.tscn",
	"res://scenes/levels/world_2_level_3.tscn",
]
const LUKE_SCENE := preload("res://scenes/player/player.tscn")
## CollisionShape2D de Luke: position.y=8, size.y=84 (mitad=42) -> el borde
## inferior de su colision queda a origin.y + 50 respecto a su propio origen.
const LUKE_GROUND_OFFSET := 50.0

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _collect_platforms(level: Node) -> Array:
	var result: Array = []
	for child in level.get_children():
		if child is StaticBody2D and child.name.begins_with("Platform"):
			var shape_node: CollisionShape2D = child.get_node_or_null("CollisionShape2D")
			if shape_node == null or shape_node.shape == null:
				continue
			result.append({
				"name": child.name,
				"x": child.global_position.x,
				"y": child.global_position.y,
				"half_w": shape_node.shape.size.x / 2.0,
				"half_h": shape_node.shape.size.y / 2.0,
			})
	result.sort_custom(func(a, b): return a.x < b.x)
	return result

# --- simulacion real de salto entre dos plataformas ---
var arena: Node2D
var luke: Luke
var frame := 0
var phase := 0
var pending: Array = []
var current_test: Dictionary = {}
## 0 = correr + salto simple, 1 = correr + doble salto, 2 = caminar sin saltar
## (para descartar falsos positivos en huecos chicos/solapados donde correr
## de mas hace que se pase de largo el aterrizaje).
var strategy := 0
var landed_ok := false
var left_a := false
var debug_trace := false

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
	for path in LEVELS:
		var level: Node = load(path).instantiate()
		add_child(level)
		var plats := _collect_platforms(level)
		print("--- ", path, " (", plats.size(), " plataformas) ---")
		for i in range(plats.size() - 1):
			var a: Dictionary = plats[i]
			var b: Dictionary = plats[i + 1]
			var gap: float = (b.x - b.half_w) - (a.x + a.half_w)
			pending.append({"level_path": path, "a": a, "b": b, "gap": gap})
		level.queue_free()
	_run_next_test()

func _run_next_test() -> void:
	if pending.is_empty():
		print("RESULTADO: ", fail_count, " fallos")
		get_tree().quit()
		return
	current_test = pending.pop_front()
	strategy = 0
	_start_jump_arena()

func _start_jump_arena() -> void:
	if arena != null:
		arena.queue_free()
	arena = Node2D.new()
	add_child(arena)
	var a: Dictionary = current_test.a
	var b: Dictionary = current_test.b
	_make_platform(arena, a.x, a.y, a.half_w, a.half_h)
	_make_platform(arena, b.x, b.y, b.half_w, b.half_h)
	# piso de emergencia bien abajo para no caer al vacio infinito
	_make_platform(arena, (a.x + b.x) / 2.0, maxf(a.y, b.y) + 900.0, 4000.0, 40.0)
	luke = LUKE_SCENE.instantiate()
	# Empieza parado justo en el borde derecho de la plataforma A.
	luke.position = Vector2(a.x + a.half_w - 10.0, a.y - a.half_h - LUKE_GROUND_OFFSET)
	arena.add_child(luke)
	luke.velocity = Vector2.ZERO
	frame = 0
	landed_ok = false
	left_a = false
	debug_trace = strategy == 2 and current_test.gap < 0.0
	phase = 1

func _physics_process(_delta: float) -> void:
	if phase != 1:
		return
	frame += 1
	Input.action_press("move_right")
	if strategy < 2:
		Input.action_press("run")
		if frame == 3:
			Input.action_press("jump")
		if frame == 4:
			Input.action_release("jump")
		if strategy == 1 and frame == 20:
			Input.action_press("jump")
		if strategy == 1 and frame == 21:
			Input.action_release("jump")
	else:
		# Estrategia 2: caminar (sin correr, sin saltar) para descartar falsos
		# positivos por exceso de velocidad en huecos chicos/solapados.
		Input.action_release("run")
	# frame>5: el primer par de frames tras instanciar a Luke, is_on_floor()
	# puede dar false transitoriamente (todavia no se asento la fisica) aun
	# parado en el mismo lugar -- eso no cuenta como "salio de A".
	if frame > 5 and not luke.is_on_floor():
		left_a = true
	if debug_trace and frame <= 20:
		print("    TRACE f=%d pos=%s onfloor=%s left_a=%s vel=%s" % [frame, luke.global_position, luke.is_on_floor(), left_a, luke.velocity])
	var b: Dictionary = current_test.b
	if left_a and luke.is_on_floor() and frame > 6:
		var on_b: bool = absf(luke.global_position.x - b.x) <= b.half_w + 5.0 and absf(luke.global_position.y - (b.y - b.half_h - LUKE_GROUND_OFFSET)) <= 6.0
		if on_b:
			landed_ok = true
			_finish_test()
			return
		else:
			if strategy < 2:
				strategy += 1
				_start_jump_arena()
				return
			_finish_test()
			return
	if frame > 240:
		if strategy < 2:
			strategy += 1
			_start_jump_arena()
			return
		_finish_test()

func _finish_test() -> void:
	var a: Dictionary = current_test.a
	var b: Dictionary = current_test.b
	var strategy_names := ["salto simple", "doble salto", "caminando sin saltar"]
	if not landed_ok:
		print("  DEBUG landing pos=", luke.global_position, " expected_b_surface_y=", (b.y - b.half_h - LUKE_GROUND_OFFSET), " b_x_range=[", b.x - b.half_w, ",", b.x + b.half_w, "]")
	_check(landed_ok, "%s: %s -> %s alcanzable (gap=%.0fpx, dy=%.0fpx, estrategia: %s)" % [
		current_test.level_path, a.name, b.name, current_test.gap, b.y - a.y,
		strategy_names[strategy]])
	_run_next_test()

extends Node2D

## C2: vidas extra escondidas en cajas.
##
## Comprueba, para los 16 niveles, que:
##  1. Cada nivel tiene su caja secreta con una vida extra adentro.
##  2. La escalera de plataformas grises que lleva hasta ella es escalable:
##     cada tramo se simula con fisica real (los mismos planes de input que
##     usa diag_world4_reachability) y tiene que haber al menos uno que
##     aterrice. En las arenas de jefe no hay escalera nueva (la caja va
##     arriba de todo, en la plataforma mas alta de la arena, que ya hay que
##     subir con el jefe atras), asi que solo se verifica el punto 3.
##  3. Parado en la plataforma de la caja, el golpe de Luke la rompe y
##     aparece la vida extra.

const LUKE_SCENE := preload("res://scenes/player/player.tscn")
const LUKE_GROUND_OFFSET := 50.0
const MOVEMENT_PROPS := [
	"walk_speed", "run_speed", "ground_acceleration", "ground_deceleration",
	"air_acceleration", "gravity", "jump_velocity", "double_jump_velocity",
	"max_fall_speed",
]
const PLANS := [
	{"run": false, "hold": 999, "dbl": false},
	{"run": true, "hold": 999, "dbl": false},
	{"run": false, "hold": 999, "dbl": true},
	{"run": true, "hold": 999, "dbl": true},
	{"run": true, "hold": 34, "dbl": true},
	{"run": false, "hold": 44, "dbl": true},
	{"run": true, "hold": 24, "dbl": true},
	{"run": false, "hold": 30, "dbl": true},
	{"run": true, "hold": 46, "dbl": true},
	{"run": false, "hold": 60, "dbl": true},
	{"run": true, "hold": 16, "dbl": true},
]

var levels: Array[String] = []
var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: ", label)
	else:
		print("  FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	for world in range(1, 5):
		for n in range(1, 4):
			levels.append("res://scenes/levels/world_%d_level_%d.tscn" % [world, n])
		levels.append("res://scenes/levels/world_%d_boss.tscn" % world)
	for path in levels:
		await _audit(path)
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _audit(path: String) -> void:
	print("--- ", path.get_file(), " ---")
	var level: Node = load(path).instantiate()
	add_child(level)
	await get_tree().physics_frame
	var box: Node2D = level.get_node_or_null("SecretLifeBox")
	if box == null:
		_check(false, "tiene caja secreta")
		level.queue_free()
		await get_tree().process_frame
		return
	var has_life: bool = box.contents != null and String(box.contents.resource_path).ends_with("extra_life.tscn")
	_check(has_life, "la caja secreta contiene una vida extra")

	var luke_props := {}
	var level_luke: Node = level.get_node_or_null("Luke")
	for prop in MOVEMENT_PROPS:
		luke_props[prop] = level_luke.get(prop)

	# Cadena a escalar: base -> SecretPlatA -> B -> C
	var chain: Array = []
	var ladder: Array = []
	for name in ["SecretPlatA", "SecretPlatB", "SecretPlatC"]:
		var node: Node2D = level.get_node_or_null(name)
		if node != null:
			ladder.append(_plat_info(node))
	if not ladder.is_empty():
		var base := _nearest_platform_below(level, ladder[0])
		if not base.is_empty():
			chain.append(base)
		chain.append_array(ladder)
	level.queue_free()
	await get_tree().process_frame

	for i in range(chain.size() - 1):
		var a: Dictionary = chain[i]
		var b: Dictionary = chain[i + 1]
		var result := await _can_reach(a, b, luke_props)
		_check(result.ok, "%s -> %s alcanzable (dx=%.0f dy=%.0f) [%s]" % [
			a.name, b.name, b.x - a.x, b.y - a.y, result.how])

	await _check_break(path)

func _plat_info(node: Node2D) -> Dictionary:
	var shape: CollisionShape2D = node.get_node_or_null("CollisionShape2D")
	return {
		"name": node.name,
		"x": node.global_position.x + shape.position.x,
		"y": node.global_position.y + shape.position.y,
		"half_w": shape.shape.size.x / 2.0,
		"half_h": shape.shape.size.y / 2.0,
	}

func _nearest_platform_below(level: Node, target: Dictionary) -> Dictionary:
	var best := {}
	var best_d := INF
	for child in level.get_children():
		if not (child is StaticBody2D) or child.name.begins_with("Secret"):
			continue
		if child.name.ends_with("Boundary") or child.name in ["Ground", "SeaFloor"]:
			continue
		var shape: CollisionShape2D = child.get_node_or_null("CollisionShape2D")
		if shape == null or not (shape.shape is RectangleShape2D):
			continue
		var info := _plat_info(child)
		if info.y <= target.y:
			continue
		var d: float = absf(info.x - target.x) + absf(info.y - target.y)
		if d < best_d:
			best_d = d
			best = info
	return best

func _can_reach(a: Dictionary, b: Dictionary, props: Dictionary) -> Dictionary:
	var toward_right: bool = b.x >= a.x
	for plan in PLANS:
		var arena := Node2D.new()
		add_child(arena)
		_make_platform(arena, a.x, a.y, a.half_w, a.half_h)
		_make_platform(arena, b.x, b.y, b.half_w, b.half_h)
		_make_platform(arena, (a.x + b.x) / 2.0, maxf(a.y, b.y) + 800.0, 6000.0, 40.0)
		var luke: Luke = LUKE_SCENE.instantiate()
		for prop in MOVEMENT_PROPS:
			luke.set(prop, props[prop])
		var edge: float = a.half_w - 12.0
		luke.position = Vector2(a.x + (edge if toward_right else -edge), a.y - a.half_h - LUKE_GROUND_OFFSET)
		arena.add_child(luke)
		luke.velocity = Vector2.ZERO
		var dir_action := "move_right" if toward_right else "move_left"
		var target_surface: float = b.y - b.half_h - LUKE_GROUND_OFFSET
		var landed := false
		var left_a := false
		for frame in range(1, 220):
			if frame <= 3 + int(plan.hold):
				Input.action_press(dir_action)
				if plan.run:
					Input.action_press("run")
			else:
				Input.action_release(dir_action)
				Input.action_release("run")
			if frame == 3:
				Input.action_press("jump")
			if frame == 4:
				Input.action_release("jump")
			if plan.dbl and frame == 26:
				Input.action_press("jump")
			if plan.dbl and frame == 27:
				Input.action_release("jump")
			await get_tree().physics_frame
			if frame > 5 and not luke.is_on_floor():
				left_a = true
			if left_a and luke.is_on_floor() and frame > 6:
				landed = absf(luke.global_position.x - b.x) <= b.half_w + 4.0 \
					and absf(luke.global_position.y - target_surface) <= 6.0
				break
			if left_a and luke.global_position.y > target_surface + 160.0:
				break
		Input.action_release(dir_action)
		Input.action_release("run")
		Input.action_release("jump")
		arena.queue_free()
		await get_tree().process_frame
		if landed:
			return {"ok": true, "how": "%s%s, direccion %s" % [
				"correr" if plan.run else "caminar",
				" + doble salto" if plan.dbl else "",
				"todo el salto" if int(plan.hold) >= 999 else ("%d frames" % plan.hold)]}
	return {"ok": false, "how": "ningun plan de input funciono"}

## Parado sobre la plataforma de la caja, el golpe la rompe y sale la vida.
func _check_break(path: String) -> void:
	var level: Node = load(path).instantiate()
	add_child(level)
	await get_tree().physics_frame
	var box: Node2D = level.get_node_or_null("SecretLifeBox")
	var luke: Luke = level.get_node_or_null("Luke")
	if box == null or luke == null:
		level.queue_free()
		await get_tree().process_frame
		return
	luke.gravity = 0.0
	# Invencible durante la prueba: en algunos niveles hay un enemigo cerca
	# de la caja y el respawn por dano invalidaba la medicion.
	luke.has_invincibility = true
	luke.global_position = box.global_position - Vector2(90.0, 0.0)
	luke.velocity = Vector2.ZERO
	luke.facing_direction = 1
	await get_tree().physics_frame
	Input.action_press("attack")
	await get_tree().physics_frame
	Input.action_release("attack")
	for i in range(12):
		await get_tree().physics_frame
	var broken := not is_instance_valid(box)
	var spawned := 0
	for child in level.get_children():
		if child is ExtraLife:
			spawned += 1
	_check(broken and spawned == 1, "el golpe rompe la caja y aparece la vida extra (rota=%s, vidas=%d)" % [broken, spawned])
	level.queue_free()
	await get_tree().process_frame

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

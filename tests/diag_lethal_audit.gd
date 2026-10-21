extends Node2D

## A2: auditoria de "zonas letales sin diseno visual".
##
## Regla pedida por el usuario: Luke solo puede morir si algo lo pincha o lo
## ataca un villano. Ninguna zona que haga dano puede ser invisible.
##
## Este test recorre los 16 niveles + el minijuego final, instancia cada uno
## de verdad (asi que tambien ve lo que se genera en runtime, como el
## GroundSpikeField), junta todas las areas que hacen dano al tocarlas que NO
## pertenecen a un enemigo (el enemigo ya es su propio aviso visual) y
## comprueba que cada una tenga arte visible encima.
##
## No cuentan como "arte visible" los fondos ni las capas gigantes: solo
## sprites/poligonos de tamano razonable que se solapen con el area letal.

const LEVELS := [
	"res://scenes/levels/world_1_level_1.tscn",
	"res://scenes/levels/world_1_level_2.tscn",
	"res://scenes/levels/world_1_level_3.tscn",
	"res://scenes/levels/world_1_boss.tscn",
	"res://scenes/levels/world_2_level_1.tscn",
	"res://scenes/levels/world_2_level_2.tscn",
	"res://scenes/levels/world_2_level_3.tscn",
	"res://scenes/levels/world_2_boss.tscn",
	"res://scenes/levels/world_3_level_1.tscn",
	"res://scenes/levels/world_3_level_2.tscn",
	"res://scenes/levels/world_3_level_3.tscn",
	"res://scenes/levels/world_3_boss.tscn",
	"res://scenes/levels/world_4_level_1.tscn",
	"res://scenes/levels/world_4_level_2.tscn",
	"res://scenes/levels/world_4_level_3.tscn",
	"res://scenes/levels/world_4_boss.tscn",
	"res://scenes/levels/final_screen.tscn",
]
## Un sprite mas grande que esto es decorado de fondo, no senal de peligro.
const MAX_DECOR_SIZE := 1200.0

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	for path in LEVELS:
		await _audit(path)
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _audit(path: String) -> void:
	var level: Node = load(path).instantiate()
	add_child(level)
	# Un par de frames para que corran los _ready() que generan geometria
	# (GroundSpikeField crea sus tramos de pinchos en runtime).
	await get_tree().physics_frame
	await get_tree().physics_frame
	var hazards := _collect_hazards(level)
	var visuals := _collect_visuals(level)
	var uncovered: Array[String] = []
	for hz in hazards:
		var rect: Rect2 = hz.rect
		var covered := false
		for v in visuals:
			if rect.intersects(v.rect):
				covered = true
				break
		if not covered:
			uncovered.append("%s en %s" % [hz.name, str(rect)])
	_check(uncovered.is_empty(), "%s: %d zonas letales de entorno, todas con arte visible%s" % [
		path.get_file(), hazards.size(),
		"" if uncovered.is_empty() else (" -- SIN ARTE: " + ", ".join(uncovered))])
	level.queue_free()
	await get_tree().process_frame

## Areas que danan a Luke y no pertenecen a un enemigo.
func _collect_hazards(root: Node) -> Array:
	var result: Array = []
	for node in _walk(root):
		if not (node is Area2D):
			continue
		var is_hazard: bool = node is DamageZone or node is SpikeStrip or node is FallDamageFloor
		if not is_hazard:
			continue
		if _has_enemy_ancestor(node):
			continue
		for child in node.get_children():
			if child is CollisionShape2D and child.shape is RectangleShape2D:
				var size: Vector2 = child.shape.size * node.global_scale
				var center: Vector2 = child.global_position
				result.append({
					"name": node.name,
					"rect": Rect2(center - size * 0.5, size),
				})
	return result

func _collect_visuals(root: Node) -> Array:
	var result: Array = []
	for node in _walk(root):
		if not (node is CanvasItem) or not node.visible:
			continue
		var rect := Rect2()
		if node is Sprite2D and node.texture != null:
			var size: Vector2 = node.texture.get_size() * node.global_scale
			if node.region_enabled:
				size = node.region_rect.size * node.global_scale
			if size.x > MAX_DECOR_SIZE or size.y > MAX_DECOR_SIZE:
				continue
			var origin: Vector2 = node.global_position
			rect = Rect2(origin - size * 0.5, size) if node.centered else Rect2(origin, size)
		elif node is Polygon2D and node.polygon.size() >= 3:
			var mn := Vector2.INF
			var mx := -Vector2.INF
			for p in node.polygon:
				mn = mn.min(p)
				mx = mx.max(p)
			var size2: Vector2 = (mx - mn) * node.global_scale
			if size2.x > MAX_DECOR_SIZE or size2.y > MAX_DECOR_SIZE:
				continue
			rect = Rect2(node.global_position + mn * node.global_scale, size2)
		else:
			continue
		result.append({"name": node.name, "rect": rect})
	return result

func _has_enemy_ancestor(node: Node) -> bool:
	var parent := node.get_parent()
	while parent != null:
		if parent is EnemyBase:
			return true
		parent = parent.get_parent()
	return false

func _walk(node: Node) -> Array:
	var result: Array = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_walk(child))
	return result

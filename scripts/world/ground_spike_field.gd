class_name GroundSpikeField
extends Node2D

## Cubre de pinchos VISIBLES todo el piso de un nivel salvo donde hay
## villanos o zonas seguras de diseno (spawn, checkpoints, cartel de mision,
## meta). Reemplaza al viejo FallDamageFloor de "Corazones de Oro" (Mundo 2),
## que mataba a Luke al aterrizar en el piso sin que se viera absolutamente
## nada: el usuario pidio que Luke solo muera si algo lo pincha o lo ataca un
## villano, y que todo el piso peligroso se vea peligroso.
##
## Se calcula en runtime a partir de la geometria real del nivel, asi que no
## puede quedar desfasado si despues se mueve un villano o se alarga el piso.

const SPIKE_STRIP := preload("res://scenes/objects/spike_strip.tscn")

## StaticBody2D del piso del nivel (se usa su CollisionShape2D para saber
## desde donde hasta donde llega el suelo y a que altura esta su superficie).
@export var ground_path: NodePath = ^"../Ground"
## Margen libre de pinchos a cada lado de la zona de patrulla de un villano:
## ahi el peligro es el villano, no el piso.
@export var villain_clearance := 70.0
## Un villano cuenta como "de piso" si esta a esta distancia de la superficie.
@export var villain_floor_band := 260.0
## Semiancho de las zonas seguras automaticas.
@export var spawn_clearance := 280.0
@export var finish_clearance := 240.0
@export var checkpoint_clearance := 150.0
@export var sign_clearance := 120.0
## Tramos sin pinchos extra definidos a mano: cada Vector2 es (x_min, x_max).
@export var extra_safe_zones: Array[Vector2] = []
## Tramos mas cortos que esto no reciben pinchos (no se leerian bien).
@export var min_segment_width := 90.0

## Expuesto para los tests: lista de Vector2(x_min, x_max) efectivamente
## cubiertos con pinchos.
var covered_segments: Array[Vector2] = []
var surface_y := 0.0

func _ready() -> void:
	var level := get_parent()
	var ground := get_node_or_null(ground_path) as StaticBody2D
	if level == null or ground == null:
		push_warning("GroundSpikeField: no encontre el piso en %s" % ground_path)
		return
	var ground_shape := ground.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if ground_shape == null or not (ground_shape.shape is RectangleShape2D):
		return
	var rect: RectangleShape2D = ground_shape.shape
	var center := ground.global_position + ground_shape.position
	var ground_min := center.x - rect.size.x * 0.5
	var ground_max := center.x + rect.size.x * 0.5
	surface_y = center.y - rect.size.y * 0.5

	var blocked: Array[Vector2] = []
	blocked.append_array(extra_safe_zones)
	blocked.append_array(_safe_zones(level))
	blocked.append_array(_villain_zones(level))
	covered_segments = _subtract(ground_min, ground_max, blocked)
	for seg in covered_segments:
		var width := seg.y - seg.x
		if width < min_segment_width:
			continue
		var strip: SpikeStrip = SPIKE_STRIP.instantiate()
		strip.strip_width = width
		strip.global_position = Vector2((seg.x + seg.y) * 0.5, surface_y)
		add_child(strip)

## Zonas de diseno donde Luke tiene que poder pisar el suelo sin morir.
func _safe_zones(level: Node) -> Array[Vector2]:
	var zones: Array[Vector2] = []
	for child in level.get_children():
		var x: float = child.global_position.x if child is Node2D else 0.0
		if child is Marker2D and child.name.begins_with("SpawnPoint"):
			zones.append(Vector2(x - spawn_clearance, x + spawn_clearance))
		elif child.name.begins_with("Finish"):
			zones.append(Vector2(x - finish_clearance, x + finish_clearance))
		elif child.name.begins_with("Checkpoint"):
			zones.append(Vector2(x - checkpoint_clearance, x + checkpoint_clearance))
		elif child.name.begins_with("MissionSign"):
			zones.append(Vector2(x - sign_clearance, x + sign_clearance))
	return zones

## Tramos ocupados por villanos de piso: ahi no van pinchos porque el peligro
## visible ya es el villano.
func _villain_zones(level: Node) -> Array[Vector2]:
	var zones: Array[Vector2] = []
	for child in level.get_children():
		if not (child is EnemyBase):
			continue
		var enemy: EnemyBase = child
		var dy: float = absf(enemy.global_position.y - surface_y)
		if dy > villain_floor_band:
			continue
		var reach: float = enemy.patrol_distance + villain_clearance
		zones.append(Vector2(enemy.global_position.x - reach, enemy.global_position.x + reach))
	return zones

## Devuelve [min,max] menos la union de blocked, como lista de tramos.
func _subtract(seg_min: float, seg_max: float, blocked: Array[Vector2]) -> Array[Vector2]:
	var sorted := blocked.duplicate()
	sorted.sort_custom(func(a, b): return a.x < b.x)
	var result: Array[Vector2] = []
	var cursor := seg_min
	for b in sorted:
		if b.y <= cursor:
			continue
		if b.x > cursor:
			result.append(Vector2(cursor, minf(b.x, seg_max)))
		cursor = maxf(cursor, b.y)
		if cursor >= seg_max:
			break
	if cursor < seg_max:
		result.append(Vector2(cursor, seg_max))
	return result

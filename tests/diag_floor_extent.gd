extends Node2D

## E1: "el fondo no llega hasta el final / se corta". Causa real (confirmada
## pixel a pixel con captura real): no era el fondo (el cielo/skyline), era
## el PISO. BlockTop/BlockBody de cada nivel eran UN SOLO Sprite2D de
## 64x64 ESTIRADO via `scale` hasta x148 para cubrir todo el nivel, en vez
## de mosaico real. La textura del tile tiene una linea de "mortero" de
## 2-3px en sus bordes (para que se vea la junta cuando se REPITE); al
## estirar un unico tile en vez de repetirlo, esos 2-3px de mortero se
## agrandaban a una banda SOLIDA de cientos de pixeles en cada punta del
## piso, tapando fondo y piso real -- esa banda oscura es lo que se
## reportaba como "fondo cortado".
##
## Fix: en vez de un Sprite2D estirado, cada piso ahora es una fila de
## Sprite2D normales ("BlockTop", "BlockTop2", "BlockTop3"...). Este test
## junta el rectangulo de TODOS los Sprite2D hijos directos de Ground (sin
## importar el nombre exacto, por los distintos patrones historicos:
## BlockTop/BlockBody en la mayoria, "Visual" en Mundo 1 Nivel 1 y 2) y lo
## compara contra la colision solida real.

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
## Margen tolerado en los bordes.
const TOLERANCE := 70.0
## Ningun tile individual puede ser mas ancho que esto (si lo es, volvio el
## bug del tile unico estirado en vez de mosaico real).
const MAX_TILE_WIDTH := 400.0

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	for path in LEVELS:
		_audit(path)
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _audit(path: String) -> void:
	var level: Node = load(path).instantiate()
	add_child(level)
	var ground: StaticBody2D = level.get_node_or_null("Ground")
	if ground == null:
		ground = level.get_node_or_null("SeaFloor")
	if ground == null:
		print("SKIP: ", path.get_file(), " (sin nodo de piso 'Ground'/'SeaFloor')")
		level.queue_free()
		return
	var shape_node: CollisionShape2D = ground.get_node_or_null("CollisionShape2D")
	if shape_node == null or not (shape_node.shape is RectangleShape2D):
		print("SKIP: ", path.get_file(), " (piso sin CollisionShape2D rectangular)")
		level.queue_free()
		return
	var rect: RectangleShape2D = shape_node.shape
	var collide_center: Vector2 = ground.global_position + shape_node.position
	var collide_x0: float = collide_center.x - rect.size.x * 0.5
	var collide_x1: float = collide_center.x + rect.size.x * 0.5

	var visual_x0 := INF
	var visual_x1 := -INF
	var widest_tile := 0.0
	var tile_count := 0
	for child in ground.get_children():
		if not (child is Sprite2D) or child.texture == null:
			continue
		var tex_w: float = child.texture.get_size().x * child.global_scale.x
		var center: float = child.global_position.x
		visual_x0 = minf(visual_x0, center - tex_w * 0.5)
		visual_x1 = maxf(visual_x1, center + tex_w * 0.5)
		widest_tile = maxf(widest_tile, tex_w)
		tile_count += 1
	if tile_count == 0:
		print("SKIP: ", path.get_file(), " (piso sin sprite visual)")
		level.queue_free()
		return

	var gap_left: float = visual_x0 - collide_x0
	var gap_right: float = collide_x1 - visual_x1
	var ok: bool = gap_left <= TOLERANCE and gap_right <= TOLERANCE
	_check(ok, "%-26s piso solido x=[%.0f,%.0f]  piso visible x=[%.0f,%.0f] (%d tiles)  hueco_izq=%.0fpx hueco_der=%.0fpx" % [
		path.get_file(), collide_x0, collide_x1, visual_x0, visual_x1, tile_count, gap_left, gap_right])
	_check(widest_tile <= MAX_TILE_WIDTH,
		"%-26s ningun tile individual estirado de mas (mas ancho=%.0fpx, limite=%.0fpx)" % [
			path.get_file(), widest_tile, MAX_TILE_WIDTH])
	level.queue_free()

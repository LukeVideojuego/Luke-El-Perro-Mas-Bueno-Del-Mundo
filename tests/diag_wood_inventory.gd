extends Node2D

## B1: inventario de TODOS los objetos de madera de todos los niveles, que es
## cada uno, para que sirve, y si llega al piso con terminacion.
##
## El reclamo era "postes o carteles de madera que no se para que sirven; se
## ve solo la parte de arriba, no llegan al piso y les falta la terminacion".
## Este test los enumera y mide, para cada uno, la distancia entre su borde
## inferior visible y el piso solido que tiene debajo (raycast real).
##
## Los que tienen poste (cartel de mision, cartel de salida, bandera de meta,
## bandera de checkpoint) ahora llevan un WoodPost que se mide solo contra el
## piso, asi que se verifica su largo efectivo. Los que se apoyan directo
## (cercos, cajones) se verifican por el borde inferior de su sprite.

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

## textura de madera -> para que sirve
const WOOD := {
	"sign.png": "cartel de mision (texto del objetivo)",
	"sign_exit.png": "cartel de salida (indica donde esta la meta)",
	"flag_green_a.png": "bandera de meta (fin del nivel)",
	"flag_green_b.png": "bandera de meta (fin del nivel)",
	"flag_blue_a.png": "bandera de checkpoint (apagada)",
	"flag_blue_b.png": "bandera de checkpoint (encendida)",
	"flag_off.png": "POSTE SIN BANDERA (no deberia quedar ninguno)",
	"fence.png": "cerco decorativo del borde del nivel",
	"fence_broken.png": "cerco roto decorativo",
	"wood_crate.png": "cajon de madera decorativo",
	"bridge.png": "puente de madera",
	"bridge_logs.png": "puente de troncos",
	"ladder_middle.png": "escalera",
}
## Separacion maxima tolerada entre el objeto y el piso.
const MAX_GAP := 10.0

var fail_count := 0
var totals := {}

func _check(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: ", label)
	else:
		print("  FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	for path in LEVELS:
		await _audit(path)
	print("")
	print("=== INVENTARIO DE OBJETOS DE MADERA ===")
	for key in totals:
		print("  %-26s %3d unidades  -> %s" % [key, totals[key], WOOD[key]])
	print("")
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _audit(path: String) -> void:
	var level: Node = load(path).instantiate()
	add_child(level)
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("--- ", path.get_file(), " ---")
	var space := get_world_2d().direct_space_state
	var found := 0
	for node in _walk(level):
		if not (node is Sprite2D) or node.texture == null:
			continue
		var file: String = node.texture.resource_path.get_file()
		if not WOOD.has(file):
			continue
		found += 1
		totals[file] = int(totals.get(file, 0)) + 1
		var owner_node: Node2D = node.get_parent() if node.get_parent() is Node2D else node
		var post: Node2D = owner_node.get_node_or_null("WoodPost")
		var bottom := _visible_bottom(node)
		if post != null:
			bottom = post.global_position.y + (post.post_top + post.measured_length) * post.global_scale.y
		var start := Vector2(node.global_position.x, bottom - 24.0)
		var query := PhysicsRayQueryParameters2D.create(start, start + Vector2(0.0, 1400.0))
		query.collision_mask = 1
		query.collide_with_areas = false
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			_check(false, "%-16s (%s): no hay piso debajo" % [owner_node.name, file])
			continue
		var gap: float = float(hit.position.y) - bottom
		_check(absf(gap) <= MAX_GAP, "%-16s (%-18s) borde inferior a %.0fpx del piso%s" % [
			owner_node.name, file, gap, "" if post == null else (" (poste de %.0fpx)" % post.measured_length)])
	if found == 0:
		print("  (sin objetos de madera)")
	level.queue_free()
	await get_tree().process_frame

## Borde inferior realmente visible (rect opaco de la textura ya escalado).
func _visible_bottom(sprite: Sprite2D) -> float:
	var tex_size: Vector2 = sprite.texture.get_size()
	var used_bottom: float = tex_size.y
	var image := sprite.texture.get_image()
	if image != null:
		var used := image.get_used_rect()
		if used.size.y > 0:
			used_bottom = float(used.position.y + used.size.y)
	var scale_y: float = absf(sprite.global_scale.y)
	var center_y: float = sprite.global_position.y + sprite.offset.y * sprite.global_scale.y
	var top: float = center_y - tex_size.y * scale_y * 0.5 if sprite.centered else center_y
	return top + used_bottom * scale_y

func _walk(node: Node) -> Array:
	var result: Array = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_walk(child))
	return result

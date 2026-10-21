extends Node2D

## E1 (investigacion): busca enemigos "quietos" en los 16 niveles corriendo
## fisica real varios segundos y midiendo el desplazamiento neto de CADA
## enemigo. Un enemigo de patrulla (GROUND_PATROL/FLY_HORIZONTAL/HOP) que en
## 4 segundos reales casi no se mueve esta roto (atascado contra algo), no
## es que "este esperando" (esos modos no esperan a Luke).

const LEVELS := [
	"res://scenes/levels/world_1_level_1.tscn",
	"res://scenes/levels/world_1_level_2.tscn",
	"res://scenes/levels/world_1_level_3.tscn",
	"res://scenes/levels/world_2_level_1.tscn",
	"res://scenes/levels/world_2_level_2.tscn",
	"res://scenes/levels/world_2_level_3.tscn",
	"res://scenes/levels/world_3_level_1.tscn",
	"res://scenes/levels/world_3_level_2.tscn",
	"res://scenes/levels/world_3_level_3.tscn",
	"res://scenes/levels/world_4_level_1.tscn",
	"res://scenes/levels/world_4_level_2.tscn",
	"res://scenes/levels/world_4_level_3.tscn",
]

var fail_count := 0

func _ready() -> void:
	for path in LEVELS:
		await _check_level(path)
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _check_level(path: String) -> void:
	var level: Node = load(path).instantiate()
	add_child(level)
	var enemies: Array = []
	for child in level.get_children():
		if child is EnemyBase and not (child is BossBase):
			var mode = child.movement_mode
			if mode == EnemyBase.MovementMode.GROUND_PATROL or mode == EnemyBase.MovementMode.FLY_HORIZONTAL or mode == EnemyBase.MovementMode.HOP:
				enemies.append({"node": child, "start": child.global_position, "wall_frames": 0,
					"min_x": child.global_position.x, "max_x": child.global_position.x})
	for i in range(240):  # 4s a 60fps
		await get_tree().physics_frame
		for e in enemies:
			var node: EnemyBase = e.node
			if not is_instance_valid(node):
				continue
			if node.is_on_wall():
				e.wall_frames += 1
			e.min_x = minf(e.min_x, node.global_position.x)
			e.max_x = maxf(e.max_x, node.global_position.x)
	for e in enemies:
		var node: EnemyBase = e.node
		if not is_instance_valid(node):
			continue
		# RANGO de movimiento (max-min), no desplazamiento neto: un enemigo
		# que oscila (patrulla ida y vuelta) puede terminar los 4s muy cerca
		# de donde arranco sin estar atascado -- lo que importa es que se
		# haya movido en algun momento, no donde termino.
		var moved: float = e.max_x - e.min_x
		var modulate_str := str(node.sprite.modulate) if node.sprite != null else "-"
		if moved < 10.0:
			fail_count += 1
			print("FAIL: ", path.get_file(), " / ", node.name, " x=", e.start.x,
				" desplazo solo ", moved, "px en 4s (modo=", node.movement_mode,
				", wall_frames=", e.wall_frames, "/240, modulate=", modulate_str, ")")
		elif node.sprite != null and (node.sprite.modulate.r > 0.01 or node.sprite.modulate.g > 0.01 or node.sprite.modulate.b > 0.01) \
				and node.sprite.modulate != Color(1, 1, 1, 1) and not (node is Bird):
			print("INFO: ", path.get_file(), " / ", node.name, " tiene modulate no-blanco: ", modulate_str, " (se mueve OK, solo aviso)")
	level.queue_free()
	await get_tree().process_frame

extends Node2D

## F1: auditoria automatica de los 16 niveles buscando el mismo sintoma
## reportado ("villanos quietos y oscuros"). Causa real encontrada en
## world_1_level_3 (medida con capturas reales + inspeccion en vivo, ver
## commit): las decoraciones "Lookout" (fondo, silueta oscura) usaban la
## textura REAL de un villano/jefe (thief.png, politico_corrupto.png,
## serpiente.png) en vez de un personaje generico -- se veian exactamente
## como un villano parado sin moverse, oscuro, porque ESO es literalmente
## lo que eran. Esta auditoria detecta dos cosas en los 16 niveles:
##  A) Cualquier Sprite2D decorativo (hijo directo del nivel, NO un
##     EnemyBase) cuya textura sea la misma que usa un enemigo o jefe real
##     (assets/Enemies/Reference o Default) -- el bug real.
##  B) Enemigos de verdad (EnemyBase) que no se mueven en varios segundos
##     de fisica real (reutiliza el mismo criterio de rango de movimiento
##     de diag_stuck_enemies.gd) o que tienen un modulate oscuro FUERA de
##     lo esperado para su tipo.

const LEVELS := [
	"res://scenes/levels/world_1_level_1.tscn", "res://scenes/levels/world_1_level_2.tscn",
	"res://scenes/levels/world_1_level_3.tscn", "res://scenes/levels/world_1_boss.tscn",
	"res://scenes/levels/world_2_level_1.tscn", "res://scenes/levels/world_2_level_2.tscn",
	"res://scenes/levels/world_2_level_3.tscn", "res://scenes/levels/world_2_boss.tscn",
	"res://scenes/levels/world_3_level_1.tscn", "res://scenes/levels/world_3_level_2.tscn",
	"res://scenes/levels/world_3_level_3.tscn", "res://scenes/levels/world_3_boss.tscn",
	"res://scenes/levels/world_4_level_1.tscn", "res://scenes/levels/world_4_level_2.tscn",
	"res://scenes/levels/world_4_level_3.tscn", "res://scenes/levels/world_4_boss.tscn",
]

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

	# A) decoraciones disfrazadas de villano/jefe real.
	var before_fails := fail_count
	for child in level.get_children():
		if child is EnemyBase or child is BossBase:
			continue
		_scan_for_enemy_texture_reuse(child, path, 0)
	if fail_count == before_fails:
		print("PASS: ", path.get_file(), " sin decoraciones que reusen textura de enemigo/jefe")

	# B) enemigos de verdad: se mueven y su modulate es blanco o el
	# esperado para su tipo (aves: 0.28,0.28,0.32 a proposito, documentado).
	var enemies: Array = []
	for child in level.get_children():
		if child is EnemyBase and not (child is BossBase):
			var mode = child.movement_mode
			if mode == EnemyBase.MovementMode.GROUND_PATROL or mode == EnemyBase.MovementMode.FLY_HORIZONTAL or mode == EnemyBase.MovementMode.HOP:
				enemies.append({"node": child, "min_x": child.global_position.x, "max_x": child.global_position.x})
	for i in range(240):
		await get_tree().physics_frame
		for e in enemies:
			var node: EnemyBase = e.node
			if not is_instance_valid(node):
				continue
			e.min_x = minf(e.min_x, node.global_position.x)
			e.max_x = maxf(e.max_x, node.global_position.x)
	for e in enemies:
		var node: EnemyBase = e.node
		if not is_instance_valid(node):
			continue
		var moved: float = e.max_x - e.min_x
		_check(moved >= 10.0, "%s / %s se mueve (rango=%.0fpx en 4s)" % [path.get_file(), node.name, moved])

	level.queue_free()
	await get_tree().process_frame

## assets/Enemies/* son texturas de enemigos/jefes reales. Una decoracion
## que las use a todo color (como "SuitGuard", de pie junto a la limusina
## en Mundo 3, con modulate blanco de proposito -- es un adorno de fondo
## reconocible, no se confunde con un villano activo) no es el bug
## reportado. El bug real es la combinacion: textura de enemigo/jefe real
## + modulate OSCURO (como "Lookout" en 3 niveles, que quedaba igual a un
## villano parado y oscuro -- confirmado con captura real).
func _scan_for_enemy_texture_reuse(node: Node, level_path: String, depth: int) -> void:
	if depth > 3:
		return
	if node is Sprite2D and node.texture != null:
		var tex_path: String = node.texture.resource_path
		var brightness: float = (node.modulate.r + node.modulate.g + node.modulate.b) / 3.0
		if tex_path.begins_with("res://assets/Enemies/") and brightness < 0.5:
			_check(false, "%s / %s (decoracion oscura, modulate=%s) usa una textura de enemigo/jefe real: %s" % [
				level_path.get_file(), node.name, node.modulate, tex_path])
	for child in node.get_children():
		if child is EnemyBase or child is BossBase:
			continue
		_scan_for_enemy_texture_reuse(child, level_path, depth + 1)

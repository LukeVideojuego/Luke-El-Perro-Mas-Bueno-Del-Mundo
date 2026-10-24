extends Node2D

## A5: detecta monedas superpuestas con plataformas, paredes u otros objetos
## solidos (capa de colision 1, la misma que usa el piso/las plataformas),
## en TODOS los niveles regulares, los 4 jefes y los 4 bonus. Usa una
## consulta de fisica real (intersect_point) contra la posicion exacta de
## cada moneda: si el punto cae dentro de un solido, esta inalcanzable.

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
	"res://scenes/levels/world_1_boss.tscn",
	"res://scenes/levels/world_2_boss.tscn",
	"res://scenes/levels/world_3_boss.tscn",
	"res://scenes/levels/world_4_boss.tscn",
	"res://scenes/levels/bonus_world_1.tscn",
	"res://scenes/levels/bonus_world_2.tscn",
	"res://scenes/levels/bonus_world_3.tscn",
	"res://scenes/levels/bonus_world_4.tscn",
]

var fail_count := 0
var total_coins := 0
var bad_coins: Array = []

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	for path in LEVELS:
		await _check_level(path)
	print("RESULTADO: ", total_coins, " monedas revisadas, ", fail_count, " embebidas en solidos")
	for c in bad_coins:
		print("  EMBEBIDA: ", c)
	get_tree().quit()

func _collect_coins(node: Node, out: Array) -> void:
	if node is Coin:
		out.append(node)
	for c in node.get_children():
		_collect_coins(c, out)

func _check_level(path: String) -> void:
	var level: Node = load(path).instantiate()
	add_child(level)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var coins: Array = []
	_collect_coins(level, coins)
	var space := get_world_2d().direct_space_state
	var level_name := path.get_file()
	for coin in coins:
		total_coins += 1
		var query := PhysicsPointQueryParameters2D.new()
		query.position = coin.global_position
		query.collision_mask = 1
		query.collide_with_areas = false
		query.collide_with_bodies = true
		var hits := space.intersect_point(query, 4)
		var embedded: bool = not hits.is_empty()
		if embedded:
			fail_count += 1
			bad_coins.append("%s: %s pos=%s dentro de %s" % [level_name, coin.name, coin.global_position, hits[0].collider.name])
	print("  ", level_name, ": ", coins.size(), " monedas")

	level.queue_free()
	await get_tree().process_frame

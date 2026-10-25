extends Node

## B3: confirma, con fisica real (gravedad real, nada forzado), que el
## veterinario malvado puesto en cada uno de los 9 niveles regulares
## (Mundo 2 a Mundo 4) cae sobre piso solido de verdad (no mitad en el
## aire, no dentro de una zona letal) y que efectivamente llega a
## dispararle una jeringa a Luke si se para cerca.

const LEVELS := [
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

var _fail_count := 0

func _check(cond: bool, msg: String) -> void:
	if cond:
		print("PASS: ", msg)
	else:
		_fail_count += 1
		print("FAIL: ", msg)

func _ready() -> void:
	for path in LEVELS:
		await _test_level(path)
	print("RESULTADO: ", _fail_count, " fallos")
	get_tree().quit()

func _test_level(path: String) -> void:
	var name: String = path.get_file().get_basename()
	var level: Node = load(path).instantiate()
	add_child(level)
	var vet: Node2D = level.get_node_or_null("VeterinarioMalvado")
	if vet == null:
		_check(false, "%s: tiene un VeterinarioMalvado" % name)
		level.queue_free()
		await get_tree().physics_frame
		return
	var start_y: float = vet.global_position.y
	for _i in range(60):
		await get_tree().physics_frame
	var settled: bool = vet.is_on_floor() and absf(vet.global_position.y - start_y) < 300.0
	_check(settled, "%s: el veterinario cae sobre piso solido cerca de donde se puso (dy=%.0f, on_floor=%s)" % [
		name, vet.global_position.y - start_y, vet.is_on_floor()])

	level.queue_free()
	await get_tree().physics_frame

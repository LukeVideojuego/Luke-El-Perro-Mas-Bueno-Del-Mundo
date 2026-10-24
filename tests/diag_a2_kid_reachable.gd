extends Node

## A2a: en los 12 niveles, Luke tiene que poder llegar CAMINANDO (sin saltar)
## desde el spawn hasta pararse frente al chico. Simula con fisica real: solo
## sostiene move_right, nunca jump, y verifica que Luke termina cerca del
## chico sin haberse caido (Y mucho mayor a la del spawn = cayo a un pozo).

const LEVELS := [
	"world_1_level_1", "world_1_level_2", "world_1_level_3",
	"world_2_level_1", "world_2_level_2", "world_2_level_3",
	"world_3_level_1", "world_3_level_2", "world_3_level_3",
	"world_4_level_1", "world_4_level_2", "world_4_level_3",
]

const WALK_SECONDS := 4.0
const REACH_DIST := 110.0
const FALL_MARGIN := 250.0

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	for level_id in LEVELS:
		await _check_level(level_id)
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _check_level(level_id: String) -> void:
	var level: Node = load("res://scenes/levels/%s.tscn" % level_id).instantiate()
	add_child(level)
	await get_tree().physics_frame
	var luke: Luke = level.get_node("Luke")
	var kid: Node2D = level.get_node("MissionSign")
	var spawn_y: float = luke.global_position.y
	var start_x: float = luke.global_position.x
	var kid_x: float = kid.global_position.x

	Input.action_press("move_right")
	var frames := int(WALK_SECONDS * 60.0)
	var fell := false
	var min_dist: float = abs(luke.global_position.x - kid_x)
	for i in range(frames):
		await get_tree().physics_frame
		min_dist = minf(min_dist, absf(luke.global_position.x - kid_x))
		if luke.global_position.y > spawn_y + FALL_MARGIN:
			fell = true
			break
	Input.action_release("move_right")
	print("  INFO %s: stop_x=%.0f on_wall=%s min_dist=%.0f" % [level_id, luke.global_position.x, luke.is_on_wall(), min_dist])

	_check(not fell, "%s: Luke no se cae caminando del spawn (x=%.0f) hacia el chico (x=%.0f)" % [level_id, start_x, kid_x])
	_check(min_dist <= REACH_DIST, "%s: Luke llega caminando a %.0fpx del chico (umbral %.0fpx)" % [level_id, min_dist, REACH_DIST])

	level.queue_free()
	await get_tree().process_frame

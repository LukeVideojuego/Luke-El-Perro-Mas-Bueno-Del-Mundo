extends Node2D

## Detecta enemigos cuyo patrol_direction cambia de signo con una frecuencia
## anormal (más de 4 veces por segundo), lo cual se percibe en pantalla como
## un parpadeo/vibración en vez de una patrulla fluida. Recorre TODOS los
## niveles regulares (no jefes) con física real, uno a la vez.

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

const TEST_FRAMES := 240

var level_index := 0
var level: Node = null
var frame := 0
var enemies: Array = []
var flip_counts: Dictionary = {}
var last_sign: Dictionary = {}
var any_fail := false

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	_start_level()

func _start_level() -> void:
	frame = 0
	flip_counts.clear()
	last_sign.clear()
	enemies.clear()
	var scene: PackedScene = load(LEVELS[level_index])
	level = scene.instantiate()
	add_child(level)
	_collect_enemies(level)
	for e in enemies:
		flip_counts[e] = 0
		last_sign[e] = 0.0

func _collect_enemies(node: Node) -> void:
	if node is EnemyBase and not (node is BossBase):
		enemies.append(node)
	for c in node.get_children():
		_collect_enemies(c)

func _physics_process(_delta: float) -> void:
	if level == null:
		return
	frame += 1
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var s := signf(e.velocity.x)
		if s != 0.0:
			if last_sign.get(e, 0.0) != 0.0 and s != last_sign[e]:
				flip_counts[e] = flip_counts.get(e, 0) + 1
			last_sign[e] = s
	if frame >= TEST_FRAMES:
		_finish_level()

func _finish_level() -> void:
	var level_name: String = LEVELS[level_index].get_file()
	var seconds := TEST_FRAMES / 60.0
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var flips: int = flip_counts.get(e, 0)
		var rate := flips / seconds
		if rate > 4.0:
			any_fail = true
			print("FAIL: ", level_name, " ", e.name, " parpadea (", flips, " cambios de direccion en ", seconds, "s = ", rate, "/s) patrol_speed=", e.patrol_speed, " patrol_distance=", e.patrol_distance, " pos=", e.global_position)
	print("OK: ", level_name, " revisados ", enemies.size(), " enemigos")
	level.queue_free()
	level = null
	level_index += 1
	if level_index >= LEVELS.size():
		print("RESULTADO: ", ("hay enemigos con parpadeo" if any_fail else "0 fallos"))
		get_tree().quit()
	else:
		call_deferred("_start_level")

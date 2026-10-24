extends Node2D

## B4: capturas reales in-engine de los 3 enemigos nuevos integrados en sus
## niveles reales (no una escena de prueba aislada).

var level: Node
var cam: Camera2D
var frame := 0
var stage := 0

const SHOTS := [
	{"level": "res://scenes/levels/world_1_level_2.tscn", "node": "SkaterThiefOne", "name": "skater_thief_en_nivel"},
	{"level": "res://scenes/levels/world_2_level_2.tscn", "node": "ScammerOne", "name": "scammer_en_nivel"},
	{"level": "res://scenes/levels/world_3_level_2.tscn", "node": "ShieldGuardOne", "name": "shield_guard_en_nivel"},
]

func _ready() -> void:
	get_window().size = Vector2i(1000, 560)
	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()
	_load_stage()

func _load_stage() -> void:
	if level != null:
		level.queue_free()
	var s: Dictionary = SHOTS[stage]
	level = load(s.level).instantiate()
	add_child(level)
	frame = 0

func _physics_process(_delta: float) -> void:
	frame += 1
	var s: Dictionary = SHOTS[stage]
	var enemy := level.get_node_or_null(s.node)
	if enemy == null:
		return
	cam.position = enemy.global_position + Vector2(0, -100)
	cam.zoom = Vector2(1.1, 1.1)
	if frame == 40:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotB4_%s.png" % s.name)
		print("SAVED ", s.name)
		stage += 1
		if stage >= SHOTS.size():
			print("LISTO")
			get_tree().quit()
		else:
			_load_stage()

extends Node2D

## A6: capturas reales (no-headless) de los chicos que reemplazan al
## cartel de madera en cada uno de los 12 niveles regulares, para
## confirmar que estan bien parados en el piso (ni flotando ni hundidos).

const LEVELS := [
	"world_1_level_1", "world_1_level_2", "world_1_level_3",
	"world_2_level_1", "world_2_level_2", "world_2_level_3",
	"world_3_level_1", "world_3_level_2", "world_3_level_3",
	"world_4_level_1", "world_4_level_2", "world_4_level_3",
]

var level: Node
var cam: Camera2D
var frame := 0
var idx := -1

func _ready() -> void:
	get_window().size = Vector2i(700, 500)
	_next()

func _next() -> void:
	if level != null:
		level.queue_free()
		level = null
	if cam != null:
		cam.queue_free()
		cam = null
	idx += 1
	if idx >= LEVELS.size():
		print("LISTO")
		get_tree().quit()
		return
	var name: String = LEVELS[idx]
	level = load("res://scenes/levels/%s.tscn" % name).instantiate()
	add_child(level)
	var luke := level.get_node_or_null("Luke")
	if luke:
		luke.visible = false
	var kid: Node2D = level.get_node("MissionSign")
	cam = Camera2D.new()
	cam.position = kid.global_position + Vector2(0, -60)
	cam.zoom = Vector2(1.6, 1.6)
	add_child(cam)
	cam.make_current()
	frame = 0

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 8:
		await RenderingServer.frame_post_draw
		var name: String = LEVELS[idx]
		get_viewport().get_texture().get_image().save_png("res://../shotA6_%s.png" % name)
		print("GUARDADA shotA6_", name)
		_next()

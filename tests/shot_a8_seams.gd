extends Node2D

## A8: capturas reales de las costuras de fondo repetido, antes cubiertas
## con elementos decorativos nuevos delante del fondo (sin tocar las
## imagenes de fondo en si).

const SHOTS := [
	{"level": "res://scenes/levels/world_1_level_1.tscn", "x": 2996.0, "name": "w1l1_costura1"},
	{"level": "res://scenes/levels/world_2_level_2.tscn", "x": 5993.0, "name": "w2l2_costura2"},
	{"level": "res://scenes/levels/world_4_level_1.tscn", "x": 3069.0, "name": "w4l1_costura1"},
]

var level: Node
var cam: Camera2D
var frame := 0
var idx := -1

func _ready() -> void:
	get_window().size = Vector2i(1100, 560)
	_next()

func _next() -> void:
	if level != null:
		level.queue_free()
		level = null
	if cam != null:
		cam.queue_free()
		cam = null
	idx += 1
	if idx >= SHOTS.size():
		print("LISTO")
		get_tree().quit()
		return
	var s: Dictionary = SHOTS[idx]
	level = load(String(s.level)).instantiate()
	add_child(level)
	var luke := level.get_node_or_null("Luke")
	if luke:
		luke.visible = false
	cam = Camera2D.new()
	cam.position = Vector2(float(s.x), 700.0)
	cam.zoom = Vector2(0.75, 0.75)
	add_child(cam)
	cam.make_current()
	frame = 0

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 8:
		await RenderingServer.frame_post_draw
		var s: Dictionary = SHOTS[idx]
		get_viewport().get_texture().get_image().save_png("res://../shotA8_%s.png" % s.name)
		print("GUARDADA shotA8_", s.name)
		_next()

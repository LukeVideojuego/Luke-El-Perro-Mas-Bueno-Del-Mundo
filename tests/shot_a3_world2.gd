extends Node2D

## A3: capturas reales (no-headless) de Mundo 2 Nivel 1 y Nivel 2 despues de
## bajar la densidad de enemigos y limitar los pinchos a tramos sueltos, para
## confirmar visualmente que ya no es "todo el piso es peligroso".

const SHOTS := [
	{"level": "res://scenes/levels/world_2_level_1.tscn", "x": 900.0, "name": "w2l1_tramo_pinchos"},
	{"level": "res://scenes/levels/world_2_level_1.tscn", "x": 3600.0, "name": "w2l1_zona_libre"},
	{"level": "res://scenes/levels/world_2_level_2.tscn", "x": 900.0, "name": "w2l2_tramo_pinchos"},
	{"level": "res://scenes/levels/world_2_level_2.tscn", "x": 4800.0, "name": "w2l2_zona_libre"},
]

var level: Node
var cam: Camera2D
var frame := 0
var idx := -1

func _ready() -> void:
	get_window().size = Vector2i(1000, 560)
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
	cam.position = Vector2(float(s.x), 820.0)
	cam.zoom = Vector2(0.75, 0.75)
	add_child(cam)
	cam.make_current()
	frame = 0

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 8:
		await RenderingServer.frame_post_draw
		var s: Dictionary = SHOTS[idx]
		get_viewport().get_texture().get_image().save_png("res://../shotA3_%s.png" % s.name)
		print("GUARDADA shotA3_", s.name)
		_next()

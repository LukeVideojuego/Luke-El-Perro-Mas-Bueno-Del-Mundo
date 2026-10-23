extends Node2D

## F7: capturas reales (no-headless) del nuevo piso marino (arena/rocas/algas)
## con cangrejos visibles bajo las medusas, para confirmar que se ve la razon
## por la que Luke muere ahi, sin tapar el camino de medusas de arriba.

const LEVEL_PATH := "res://scenes/levels/world_4_level_2.tscn"

var level: Node
var cam: Camera2D
var frame := 0

const SHOTS := [
	{"x": 900.0, "y": 920.0, "zoom": 1.3, "name": "cerca"},
	{"x": 2600.0, "y": 950.0, "zoom": 0.55, "name": "amplia"},
	{"x": 5000.0, "y": 920.0, "zoom": 1.0, "name": "medio"},
]
var idx := 0

func _ready() -> void:
	get_window().size = Vector2i(900, 560)
	level = load(LEVEL_PATH).instantiate()
	add_child(level)
	var luke := level.get_node_or_null("Luke")
	if luke:
		luke.visible = false
	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()
	_apply_shot()

func _apply_shot() -> void:
	var s: Dictionary = SHOTS[idx]
	cam.position = Vector2(s.x, s.y)
	cam.zoom = Vector2(s.zoom, s.zoom)
	frame = 0

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 6:
		await RenderingServer.frame_post_draw
		var s: Dictionary = SHOTS[idx]
		get_viewport().get_texture().get_image().save_png("res://../shotF7_seafloor_%s.png" % s.name)
		idx += 1
		if idx >= SHOTS.size():
			get_tree().quit()
		else:
			_apply_shot()

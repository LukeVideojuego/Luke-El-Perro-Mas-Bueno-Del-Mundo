extends Node

## A6: capturas reales (no-headless) panoramicas del piso marino de
## world_4_level_2 (Mundo 4 Nivel 2), para confirmar que ahora hay muchos
## mas cangrejos cubriendo todo el piso, y que se nota a simple vista que
## no se puede pasar por abajo.

const LEVEL := preload("res://scenes/levels/world_4_level_2.tscn")
const SHOTS := [1200.0, 4600.0, 8000.0]

var level: Node
var cam: Camera2D
var frame := 0
var idx := 0

func _ready() -> void:
	get_window().size = Vector2i(1100, 500)
	level = LEVEL.instantiate()
	add_child(level)
	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()
	cam.zoom = Vector2(0.55, 0.55)

func _process(_delta: float) -> void:
	if idx >= SHOTS.size():
		return
	frame += 1
	cam.global_position = Vector2(SHOTS[idx], 980)
	if frame == 6:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotA6_sea_crabs_%d.png" % idx)
		print("GUARDADA shotA6_sea_crabs_", idx)
		idx += 1
		frame = 0
		if idx >= SHOTS.size():
			get_tree().quit()

extends Node

## A6: primer plano real (no-headless) de un tramo del piso marino, para ver
## los cangrejos individuales bien de cerca.

const LEVEL := preload("res://scenes/levels/world_4_level_2.tscn")

var level: Node
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(900, 400)
	level = LEVEL.instantiate()
	add_child(level)
	var cam := Camera2D.new()
	add_child(cam)
	cam.make_current()
	cam.global_position = Vector2(2200, 975)
	cam.zoom = Vector2(1.8, 1.8)

func _process(_delta: float) -> void:
	frame += 1
	if frame == 6:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotA6_sea_crabs_closeup.png")
		print("GUARDADA closeup")
		get_tree().quit()

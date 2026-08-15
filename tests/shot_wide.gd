extends Node2D

@export var scene_path := "res://scenes/levels/world_1_level_3.tscn"
@export var out_name := "wide_w1"
var level: Node

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	var packed := load(scene_path) as PackedScene
	level = packed.instantiate()
	add_child(level)
	var cam := Camera2D.new()
	cam.zoom = Vector2(0.28, 0.28)
	cam.position = Vector2(2200, 750)
	add_child(cam)
	cam.make_current()

func _process(_delta: float) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://../shot_%s.png" % out_name)
	print("SAVED shot_", out_name)
	get_tree().quit()

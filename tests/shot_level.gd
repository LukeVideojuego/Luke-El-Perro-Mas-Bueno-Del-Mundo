extends Node2D

@export var scene_path := "res://scenes/levels/world_1_level_2.tscn"
@export var out_name := "world1_2_coins"
@export var camera_focus_x := 800.0
var level: Node
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	var packed := load(scene_path) as PackedScene
	level = packed.instantiate()
	add_child(level)
	var luke := level.get_node_or_null("Luke")
	if luke != null and camera_focus_x > 0.0:
		luke.global_position.x = camera_focus_x

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 20:
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://../shot_%s_a.png" % out_name)
		print("SAVED shot_", out_name, "_a")
	if frame == 140:
		await RenderingServer.frame_post_draw
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://../shot_%s_b.png" % out_name)
		print("SAVED shot_", out_name, "_b")
	if frame == 145:
		get_tree().quit()

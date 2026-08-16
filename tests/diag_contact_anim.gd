extends Node2D

@export var scene_path := "res://scenes/levels/world_1_level_3.tscn"
@export var enemy_name := "ThiefOne"
@export var out_name := "steal"
var level: Node
var luke: Node
var enemy: Node
var frame := 0
var triggered := false

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	var packed := load(scene_path) as PackedScene
	level = packed.instantiate()
	add_child(level)
	luke = level.get_node_or_null("Luke")
	enemy = level.get_node_or_null(enemy_name)
	if enemy == null:
		print("ENEMY NOT FOUND: ", enemy_name)

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 5 and enemy != null and luke != null:
		luke.global_position = enemy.global_position + Vector2(0, -2)
		luke.velocity = Vector2.ZERO
		var cam := level.get_node_or_null("Camera2D")
		if cam == null:
			cam = luke.get_node_or_null("Camera2D")
		if cam != null:
			cam.global_position = enemy.global_position
		print("TELEPORTED luke to ", enemy.global_position)
	if frame == 12:
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://../shot_contact_%s_a.png" % out_name)
		print("SAVED shot_contact_", out_name, "_a")
	if frame == 20:
		await RenderingServer.frame_post_draw
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://../shot_contact_%s_b.png" % out_name)
		print("SAVED shot_contact_", out_name, "_b")
	if frame == 40:
		await RenderingServer.frame_post_draw
		var img3 := get_viewport().get_texture().get_image()
		img3.save_png("res://../shot_contact_%s_c.png" % out_name)
		print("SAVED shot_contact_", out_name, "_c")
	if frame == 45:
		print("DONE frame=", frame)
		get_tree().quit()

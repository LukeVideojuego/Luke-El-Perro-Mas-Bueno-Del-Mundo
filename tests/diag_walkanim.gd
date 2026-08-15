extends Node2D

const LEVEL := preload("res://scenes/levels/test_level.tscn")
var level: Node
var luke: CharacterBody2D
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(400, 400)
	level = LEVEL.instantiate()
	add_child(level)
	luke = level.get_node("Luke")
	var cam := luke.get_node("Camera2D")
	cam.zoom = Vector2(4, 4)
	Input.action_press("move_right")

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 20:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shot_walkanim_1.png")
		print("frame1 anim=", luke.animated_sprite.animation, " sprite_frame=", luke.animated_sprite.frame)
	if frame == 24:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shot_walkanim_2.png")
		print("frame2 anim=", luke.animated_sprite.animation, " sprite_frame=", luke.animated_sprite.frame)
	if frame == 30:
		get_tree().quit()

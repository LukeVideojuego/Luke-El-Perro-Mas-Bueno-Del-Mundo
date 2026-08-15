extends Node2D

const LEVEL := preload("res://scenes/levels/final_screen.tscn")
var level: Node
var luke: CharacterBody2D
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	level = LEVEL.instantiate()
	add_child(level)
	luke = level.get_node("Luke")
	var diego = level.get_node("Diego")
	print("before: is_hugged=", diego.is_hugged, " hugged_count=", level.hugged_count)
	luke.global_position = diego.global_position

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 10:
		var diego = level.get_node("Diego")
		print("after: is_hugged=", diego.is_hugged, " hugged_count=", level.hugged_count, " heart_visible=", diego.get_node("Heart").visible, " sprite_texture=", diego.sprite.texture.resource_path)
	if frame == 15:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shot_hug_reaction.png")
		print("SAVED shot_hug_reaction")
	if frame == 20:
		get_tree().quit()

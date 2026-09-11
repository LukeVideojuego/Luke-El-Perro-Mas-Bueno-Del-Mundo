extends Node2D

const LEVEL := preload("res://scenes/levels/world_4_level_2.tscn")
var level: Node
var frame := 0
var cam: Camera2D

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	level = LEVEL.instantiate()
	add_child(level)

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 5:
		var fish: Node2D = level.get_node("FishBlueOne")
		cam = Camera2D.new()
		cam.zoom = Vector2(2.5, 2.5)
		cam.position = fish.global_position
		add_child(cam)
		cam.make_current()
	if frame == 10:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shot_sea_shark.png")
		print("SAVED shot_sea_shark")
	if frame == 14:
		get_tree().quit()

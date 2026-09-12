extends Node2D

const LEVEL := preload("res://scenes/levels/world_4_level_2.tscn")
var level: Node
var luke: Node
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	level = LEVEL.instantiate()
	add_child(level)
	luke = level.get_node("Luke")
	luke.set_protective_aura(true)
	luke.global_position = Vector2(2000, 400)

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame % 10 == 0 and frame <= 150:
		print("f=", frame, " pos=", luke.global_position, " on_floor=", luke.is_on_floor(), " lives=", GameState.lives)
	if frame == 160:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shot_sea_floor_fix.png")
		print("SAVED shot_sea_floor_fix")
	if frame == 165:
		get_tree().quit()

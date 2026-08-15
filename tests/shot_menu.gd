extends Node

const MAIN_SCENE := preload("res://scenes/main.tscn")
var main: Node
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	main = MAIN_SCENE.instantiate()
	add_child(main)

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 10:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shot_menu.png")
		print("SAVED shot_menu")
	if frame == 15:
		get_tree().quit()

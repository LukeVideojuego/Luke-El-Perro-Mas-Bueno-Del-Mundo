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
	if frame == 5:
		GameState.highest_order_reached = 7
		main.get_node("MainMenu").map_requested.emit()
	if frame == 15:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shot_world_map.png")
		print("SAVED shot_world_map")
	if frame == 20:
		get_tree().quit()

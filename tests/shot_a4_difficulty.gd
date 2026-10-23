extends Node

## A4: captura real (no-headless) del selector de dificultad nuevo.

const MAIN_SCENE := preload("res://scenes/main.tscn")
var main: Node
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	main = MAIN_SCENE.instantiate()
	add_child(main)

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 8:
		var menu: Node = main.get_node("MainMenu")
		menu.new_game_button.pressed.emit()
	if frame == 14:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotA4_difficulty.png")
		print("SAVED shotA4_difficulty")
	if frame == 18:
		get_tree().quit()

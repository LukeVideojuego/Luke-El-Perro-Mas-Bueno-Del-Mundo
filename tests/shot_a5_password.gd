extends Node2D

## A5: captura real (no-headless) del cartel de contraseña al completar
## un nivel.

const MAIN_SCENE := preload("res://scenes/main.tscn")
var main: Node
var frame := 0
var saved := false

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	main = MAIN_SCENE.instantiate()
	add_child(main)
	main.start_game()

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 90 and main.intro_cinematic != null:
		main._on_intro_finished()
	if frame == 220:
		var level: Node = main.active_level
		var finish: Node = level.get_node_or_null("Finish")
		var luke: Luke = level.get_node("Luke")
		luke.global_position = finish.global_position
	if frame == 235 and not saved:
		saved = true
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotA5_password.png")
		print("SAVED shotA5_password")
	if frame == 245:
		get_tree().quit()

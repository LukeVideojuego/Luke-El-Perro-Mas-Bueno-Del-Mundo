extends Node2D

## A7: capturas reales de: una huella dorada en un nivel real, y la
## pantalla ALBUM DE LUKE con progreso parcial.

const MAIN_SCENE := preload("res://scenes/main.tscn")
var main: Node
var frame := 0
var phase := 0

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	main = MAIN_SCENE.instantiate()
	add_child(main)

func _physics_process(_delta: float) -> void:
	frame += 1
	match phase:
		0:
			if frame == 5:
				main.start_game()
			if frame == 90 and main.intro_cinematic != null:
				main._on_intro_finished()
			if frame == 220:
				var level: Node = main.active_level
				var paw: Node2D = level.get_node("GoldenPaw1")
				var cam: Camera2D = level.get_node("Luke/Camera2D")
				cam.position = paw.global_position
				cam.zoom = Vector2(1.6, 1.6)
				phase = 1
				frame = 0
		1:
			if frame == 6:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://../shotA7_paw_en_nivel.png")
				print("SAVED shotA7_paw_en_nivel")
				# marcar progreso parcial para la foto del album
				GameState.collect_paw("world_1_level_1", 0)
				GameState.collect_paw("world_1_level_1", 1)
				GameState.collect_paw("world_1_level_2", 0)
				main.queue_free()
				main = MAIN_SCENE.instantiate()
				add_child(main)
				phase = 2
				frame = 0
		2:
			if frame == 5:
				var menu: Node = main.get_node("MainMenu")
				menu.album_button.pressed.emit()
			if frame == 10:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://../shotA7_album.png")
				print("SAVED shotA7_album")
				get_tree().quit()

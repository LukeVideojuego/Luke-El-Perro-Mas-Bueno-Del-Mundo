extends Node2D

## Capturas reales de las pantallas de UI nuevas (pausa y game over) y de los
## paneles de cinematica ya sin rotulo.
const MAIN_SCENE := preload("res://scenes/main.tscn")
const GAME_OVER := preload("res://scenes/ui/game_over_screen.tscn")
const PAUSE := preload("res://scenes/ui/pause_screen.tscn")
const INTRO := preload("res://scenes/cinematics/intro_cinematic.tscn")

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	await _shot_game_over()
	await _shot_pause()
	await _shot_intro()
	get_tree().quit()

func _save(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../" + path)
	print("GUARDADA ", path)

func _shot_game_over() -> void:
	var screen := GAME_OVER.instantiate()
	add_child(screen)
	screen.setup(2)
	for i in range(12):
		await get_tree().process_frame
	await _save("shotC1_game_over.png")
	screen.queue_free()
	await get_tree().process_frame

func _shot_pause() -> void:
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame
	main.start_game()
	for i in range(90):
		await get_tree().process_frame
	if main.intro_cinematic != null:
		main._on_intro_finished()
	for i in range(150):
		await get_tree().process_frame
	main.set_paused(true)
	for i in range(6):
		await get_tree().process_frame
	await _save("shotB4_pausa.png")
	main.set_paused(false)
	get_tree().paused = false
	main.queue_free()
	await get_tree().process_frame

func _shot_intro() -> void:
	var intro := INTRO.instantiate()
	add_child(intro)
	for i in range(12):
		await get_tree().process_frame
	await _save("shotB3_intro_panel1.png")
	intro._advance()
	for i in range(30):
		await get_tree().process_frame
	await _save("shotB3_intro_panel2.png")
	intro._advance()
	for i in range(30):
		await get_tree().process_frame
	await _save("shotB3_intro_panel3.png")
	intro.queue_free()
	await get_tree().process_frame

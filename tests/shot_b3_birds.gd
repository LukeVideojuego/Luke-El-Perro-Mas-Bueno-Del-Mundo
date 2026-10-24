extends Node2D

## B3: captura real con zoom de un Bird en juego, alternando las 2 poses
## (reposo/aleteo) durante su patrulla.

const BIRD_SCENE := preload("res://scenes/enemies/bird.tscn")
var bird: Node2D
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(500, 500)
	bird = BIRD_SCENE.instantiate()
	bird.position = Vector2(250, 250)
	bird.gravity = 0.0
	bird.modulate = Color(0.28, 0.28, 0.32, 1)
	add_child(bird)
	var cam := Camera2D.new()
	cam.position = Vector2(250, 250)
	cam.zoom = Vector2(5.0, 5.0)
	add_child(cam)
	cam.make_current()

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 10:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotB3_bird_pose_a.png")
		print("GUARDADA pose_a")
	if frame == 20:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotB3_bird_pose_b.png")
		print("GUARDADA pose_b")
	if frame == 30:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotB3_bird_pose_c.png")
		print("GUARDADA pose_c")
		get_tree().quit()

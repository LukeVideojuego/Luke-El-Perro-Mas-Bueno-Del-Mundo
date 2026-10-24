extends Node2D

## A3: captura real con zoom de un checkpoint azul para ver si la base del
## poste (que toca el piso) y la bandera de arriba quedan alineadas.

const CHECKPOINT := preload("res://scenes/objects/checkpoint.tscn")
var cp: Node2D
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(500, 500)
	var ground := StaticBody2D.new()
	add_child(ground)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(800, 100)
	shape.shape = rect
	shape.position = Vector2(0, 950)
	ground.add_child(shape)
	var vis := ColorRect.new()
	vis.color = Color(0.4, 0.3, 0.2)
	vis.size = Vector2(800, 100)
	vis.position = Vector2(-400, 900)
	ground.add_child(vis)

	await get_tree().physics_frame
	await get_tree().physics_frame
	cp = CHECKPOINT.instantiate()
	cp.position = Vector2(0, 850)
	add_child(cp)

	var cam := Camera2D.new()
	cam.position = Vector2(0, 850)
	cam.zoom = Vector2(6.0, 6.0)
	add_child(cam)
	cam.make_current()

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 15:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotA3_checkpoint_before.png")
		print("GUARDADA checkpoint_before")
		get_tree().quit()

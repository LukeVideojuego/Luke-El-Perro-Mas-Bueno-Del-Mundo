extends Node2D

## 0a: captura real con zoom del aguila (pose de aleteo) dentro de
## world_1_level_2, para confirmar que ya no queda el triangulo marron.

const LEVEL := preload("res://scenes/levels/world_1_level_2.tscn")

var level: Node2D
var bird: Node2D
var cam: Camera2D
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(640, 480)
	level = LEVEL.instantiate()
	add_child(level)
	for n in level.get_children():
		if n is Bird:
			bird = n
			break
	cam = Camera2D.new()
	add_child(cam)
	cam.zoom = Vector2(5.0, 5.0)

func _process(_delta: float) -> void:
	frame += 1
	if bird == null:
		get_tree().quit()
		return
	cam.make_current()
	cam.global_position = bird.global_position
	if frame == 20:
		bird.get_node("Sprite2D").texture = bird.walk_texture
	if frame == 24:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shot0a_eagle_flap_ingame.png")
		print("GUARDADA shot0a_eagle_flap_ingame")
		get_tree().quit()

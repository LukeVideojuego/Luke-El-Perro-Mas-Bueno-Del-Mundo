extends Node2D

## B3: captura real (no-headless) de Luke gordo (idle/caminando), usando
## el arte de referencia_visual/luke_gordo.jpg.

const LUKE_SCENE := preload("res://scenes/player/player.tscn")

var luke: Luke
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(500, 400)
	var ground := StaticBody2D.new()
	ground.collision_layer = 1
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(2000.0, 80.0)
	cs.shape = rect
	ground.add_child(cs)
	ground.position = Vector2(250.0, 320.0)
	add_child(ground)

	luke = LUKE_SCENE.instantiate()
	luke.position = Vector2(250, 250)
	add_child(luke)
	luke.apply_fat_effect()

	var cam := Camera2D.new()
	cam.position = Vector2(250, 260)
	cam.zoom = Vector2(3.0, 3.0)
	add_child(cam)
	cam.make_current()

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 10:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotB3_luke_gordo_idle.png")
		print("GUARDADA shotB3_luke_gordo_idle")
	if frame == 12:
		Input.action_press("move_right")
	if frame == 24:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotB3_luke_gordo_walk.png")
		print("GUARDADA shotB3_luke_gordo_walk")
		get_tree().quit()

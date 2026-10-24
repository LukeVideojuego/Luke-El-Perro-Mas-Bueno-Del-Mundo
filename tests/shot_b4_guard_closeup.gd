extends Node2D

var level: Node
var guard
var cam: Camera2D
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(500, 400)
	level = load("res://scenes/levels/world_3_level_2.tscn").instantiate()
	add_child(level)
	guard = level.get_node("ShieldGuardOne")
	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 10:
		guard.set_physics_process(false)
		guard.velocity = Vector2.ZERO
		guard.sprite.flip_h = true
	cam.position = guard.global_position + Vector2(0, -90)
	cam.zoom = Vector2(2.2, 2.2)
	if frame == 20:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotB4_guard_closeup.png")
		print("SAVED closeup")
		print("LISTO")
		get_tree().quit()

extends Node2D

## A3: verifica con capturas reales in-game (checkpoint azul y bandera de
## meta verde) que el poste quedo alineado en un nivel real, no solo en el
## entorno sintetico.

var level: Node
var frame := 0
var cam: Camera2D

func _ready() -> void:
	get_window().size = Vector2i(800, 600)
	level = load("res://scenes/levels/world_1_level_1.tscn").instantiate()
	add_child(level)

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 5:
		cam = Camera2D.new()
		cam.zoom = Vector2(3.0, 3.0)
		add_child(cam)
		cam.make_current()
	if frame == 10:
		var cp := level.get_node("CheckpointOne")
		cam.global_position = cp.global_position + Vector2(0, -90)
	if frame == 16:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotA3_real_checkpoint.png")
		print("GUARDADA real_checkpoint")
	if frame == 20:
		var fin := level.get_node("Finish")
		cam.global_position = fin.global_position + Vector2(0, -90)
	if frame == 26:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotA3_real_finish.png")
		print("GUARDADA real_finish")
		get_tree().quit()

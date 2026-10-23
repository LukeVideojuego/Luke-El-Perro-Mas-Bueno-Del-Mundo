extends Node2D

## A6: captura real del globo de dialogo de un chico, mostrado al apretar
## un boton estando cerca.

const LEVEL := preload("res://scenes/levels/world_2_level_1.tscn")
var level: Node
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(900, 560)
	level = LEVEL.instantiate()
	add_child(level)
	var kid: Node2D = level.get_node("MissionSign")
	var luke: Node2D = level.get_node("Luke")
	luke.global_position = kid.global_position
	var cam := Camera2D.new()
	cam.position = kid.global_position + Vector2(0, -90)
	cam.zoom = Vector2(1.1, 1.1)
	add_child(cam)
	cam.make_current()

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 5:
		Input.action_press("attack")
	if frame == 6:
		Input.action_release("attack")
	if frame == 12:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotA6_dialogo.png")
		print("SAVED shotA6_dialogo")
	if frame == 16:
		get_tree().quit()

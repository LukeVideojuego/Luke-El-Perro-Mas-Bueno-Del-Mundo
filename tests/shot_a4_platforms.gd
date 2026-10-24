extends Node2D

## A4: captura real de la zona de world_1_level_3 donde las plataformas
## pasaban de gris a verde, y donde el ladron en patineta quedaba trabado.

var level: Node
var frame := 0
var cam: Camera2D

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	level = load("res://scenes/levels/world_1_level_3.tscn").instantiate()
	add_child(level)

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 5:
		cam = Camera2D.new()
		cam.zoom = Vector2(0.8, 0.8)
		cam.position = Vector2(7150, 820)
		add_child(cam)
		cam.make_current()
	if frame == 12:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotA4_platforms_fixed.png")
		print("GUARDADA platforms_fixed")
	if frame > 12 and frame < 300:
		pass
	if frame == 300:
		var skater := level.get_node_or_null("SkaterThiefTwo")
		print("skater pos=", skater.global_position if skater else "N/A")
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotA4_skater_after5s.png")
		print("GUARDADA skater_after5s")
		get_tree().quit()

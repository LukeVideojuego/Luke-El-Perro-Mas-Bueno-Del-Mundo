extends Node2D

## A5: captura real de un cluster de monedas que estaba embebido en una
## plataforma (world_2_level_1, CoinE sobre PlatformSix) para confirmar que
## ahora flotan en el aire, alcanzables desde arriba de la plataforma.

var level: Node
var frame := 0
var cam: Camera2D

func _ready() -> void:
	get_window().size = Vector2i(900, 600)
	level = load("res://scenes/levels/world_2_level_1.tscn").instantiate()
	add_child(level)

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 5:
		cam = Camera2D.new()
		cam.zoom = Vector2(1.5, 1.5)
		cam.position = Vector2(4900, 740)
		add_child(cam)
		cam.make_current()
	if frame == 12:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotA5_coins_fixed.png")
		print("GUARDADA coins_fixed")
		get_tree().quit()

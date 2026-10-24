extends Node2D

## B1: verifica que el fondo nuevo del minijuego final cubre la pantalla
## completa (sin Luke dibujado, sin zonas grises), usando el flujo real
## (level_base via main.gd no aplica aca directo, pero level_base.gd si
## tiene _apply_camera_limits() corriendo en _ready igual que cualquier
## nivel regular).

const LEVEL_SCENE := preload("res://scenes/levels/final_screen.tscn")

var level: Node
var frame := 0
var cam: Camera2D

func _ready() -> void:
	get_window().size = Vector2i(1920, 1080)
	level = LEVEL_SCENE.instantiate()
	add_child(level)

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 3:
		var luke = level.get_node("Luke")
		cam = luke.get_node("Camera2D")
	if frame == 90:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotB1_final_mid.png")
	if frame == 95:
		cam.global_position += Vector2(0, -2000)
	if frame == 100:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotB1_final_top.png")
	if frame == 105:
		cam.global_position += Vector2(-3000, 1800)
	if frame == 110:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotB1_final_left.png")
		get_tree().quit()

extends Node2D

## F9: captura real (no-headless) de la Serpiente quieta vs en movimiento
## (carga), para confirmar visualmente el balanceo (sway_enabled, ya
## activo en boss_base.gd) y que el recorte de la silueta sigue limpio en
## ese angulo.

const BOSS_SCENE := preload("res://scenes/enemies/serpent_boss.tscn")
const LUKE_SCENE := preload("res://scenes/player/player.tscn")

var boss
var luke
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(800, 700)
	var ground := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(3000.0, 80.0)
	shape.shape = rect
	ground.add_child(shape)
	ground.position = Vector2(400, 700)
	ground.collision_layer = 1
	add_child(ground)
	boss = BOSS_SCENE.instantiate()
	boss.position = Vector2(400, 500)
	add_child(boss)
	# Luke bien lejos (fuera de camara) para que _get_player() encuentre un
	# objetivo real y el jefe cargue de verdad con su propia logica, en vez
	# de asignarle la velocidad a mano (_handle_charge la pisa cada frame).
	luke = LUKE_SCENE.instantiate()
	luke.name = "Luke"
	luke.position = Vector2(3200, 660)
	luke.gravity = 0.0
	add_child(luke)
	var cam := Camera2D.new()
	cam.position = Vector2(400, 480)
	cam.zoom = Vector2(1.2, 1.2)
	add_child(cam)
	cam.make_current()

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 2:
		boss.set_physics_process(false)
	if frame == 10:
		boss.global_position = Vector2(400, 700 - 40 - 153.5)
		boss.velocity = Vector2.ZERO
	if frame == 15:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotF9_serpent_idle.png")
		print("idle sprite.rotation=", boss.get_node("Sprite2D").rotation, " velocity=", boss.velocity)
	if frame == 16:
		boss.set_physics_process(true)
	if frame == 24:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotF9_serpent_moving.png")
		print("moving sprite.rotation=", boss.get_node("Sprite2D").rotation, " velocity=", boss.velocity)
		get_tree().quit()

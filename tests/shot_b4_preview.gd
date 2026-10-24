extends Node2D

## B4: vista previa rapida de los 3 enemigos nuevos (sin nivel real) para
## chequear escala/proporciones antes de integrarlos en los niveles.

const SKATER := preload("res://scenes/enemies/skater_thief.tscn")
const SCAMMER := preload("res://scenes/enemies/scammer.tscn")
const GUARD := preload("res://scenes/enemies/shield_guard.tscn")
const LUKE_SCENE := preload("res://scenes/player/player.tscn")

var cam: Camera2D
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(1000, 500)
	var ground := StaticBody2D.new()
	add_child(ground)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 40)
	shape.shape = rect
	shape.position = Vector2(500, 300)
	ground.add_child(shape)

	var luke: Node2D = LUKE_SCENE.instantiate()
	luke.name = "Luke"
	luke.global_position = Vector2(-500, 260)
	add_child(luke)

	var skater: Node2D = SKATER.instantiate()
	skater.global_position = Vector2(150, 260)
	add_child(skater)

	var scammer: Node2D = SCAMMER.instantiate()
	scammer.global_position = Vector2(450, 260)
	add_child(scammer)

	var guard: Node2D = GUARD.instantiate()
	guard.global_position = Vector2(750, 260)
	add_child(guard)

	cam = Camera2D.new()
	cam.position = Vector2(450, 230)
	cam.zoom = Vector2(0.85, 0.85)
	add_child(cam)
	cam.make_current()

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 15:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotB4_preview.png")
		print("SAVED preview")
		print("LISTO")
		get_tree().quit()

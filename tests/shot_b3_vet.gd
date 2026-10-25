extends Node2D

## B3: captura real (no-headless) con zoom del veterinario malvado: parado
## (idle/caminando) y en el instante de lanzar la jeringa.

const VET_SCENE := preload("res://scenes/enemies/veterinario_malvado.tscn")
const LUKE_SCENE := preload("res://scenes/player/player.tscn")

var vet: Node2D
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

	vet = VET_SCENE.instantiate()
	vet.position = Vector2(250, 250)
	add_child(vet)

	luke = LUKE_SCENE.instantiate()
	luke.position = Vector2(480, 250)
	add_child(luke)

	var cam := Camera2D.new()
	cam.position = Vector2(300, 260)
	cam.zoom = Vector2(2.2, 2.2)
	add_child(cam)
	cam.make_current()

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 20:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotB3_vet_idle.png")
		print("GUARDADA shotB3_vet_idle")
	if frame == 65:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotB3_vet_throw.png")
		print("GUARDADA shotB3_vet_throw (throw_pose_left=", vet._throw_pose_left, ")")
	if frame == 68:
		var children := get_children()
		for c in children:
			if c is SyringeProjectile:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://../shotB3_syringe_flight.png")
				print("GUARDADA shotB3_syringe_flight")
				break
	if frame == 160:
		get_tree().quit()

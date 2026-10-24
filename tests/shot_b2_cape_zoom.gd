extends Node2D

## B2: captura real con zoom de Luke con la capa (reposo y salto), para
## revisar la alineacion fina con su lomo. Usa un piso real para que
## is_on_floor() (que es lo que elige la pose) funcione de verdad.

const LUKE_SCENE := preload("res://scenes/player/player.tscn")
var luke: Luke
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(500, 500)
	GameState.reset_for_new_game()
	GameState.coins = 300
	GameState.buy_item("suit_cape")

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
	var cam := Camera2D.new()
	cam.position = Vector2(250, 240)
	cam.zoom = Vector2(4.0, 4.0)
	add_child(cam)
	cam.make_current()

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 20:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotB2_cape_rest_zoom.png")
		print("GUARDADA rest_zoom on_floor=", luke.is_on_floor())
	if frame == 25:
		Input.action_press("jump")
	if frame == 26:
		Input.action_release("jump")
	if frame == 40:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotB2_cape_jump_zoom.png")
		print("GUARDADA jump_zoom on_floor=", luke.is_on_floor(), " vel=", luke.velocity)
		get_tree().quit()

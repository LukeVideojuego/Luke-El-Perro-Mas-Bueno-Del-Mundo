extends Node2D

## A2: captura real con zoom del globo de dialogo tipo comic de los chicos.

const KID_SCENE := preload("res://scenes/objects/kid_npc.tscn")
var kid: Node2D
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(900, 700)
	var bg := ColorRect.new()
	bg.color = Color(0.3, 0.6, 0.85, 1)
	bg.size = Vector2(900, 700)
	bg.position = Vector2(-450, -450)
	add_child(bg)

	kid = KID_SCENE.instantiate()
	kid.kid_name = "Zoe"
	kid.interaction_text = "Zoe: Hola Luke, los ladrones andan sueltos por el barrio. Esquiva o ataca a los ladrones y a las aves, y llega hasta la bandera verde."
	kid.position = Vector2(0, 0)
	add_child(kid)

	var cam := Camera2D.new()
	cam.position = Vector2(0, -120)
	cam.zoom = Vector2(1.3, 1.3)
	add_child(cam)
	cam.make_current()

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 5:
		kid.hint_label.text = kid.interaction_text
		kid.hint_label.visible = true
	if frame == 10:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotA2_bubble_long.png")
		print("GUARDADA bubble_long")
	if frame == 15:
		kid.interaction_text = "Bauti: Ok."
		kid.hint_label.text = kid.interaction_text
	if frame == 25:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotA2_bubble_short.png")
		print("GUARDADA bubble_short")
		get_tree().quit()

extends Node2D

## A3: captura real (no-headless) con zoom de Bauti y Fausto uno al lado del
## otro, para verificar que Fausto (rehecho a partir del modelo de Bauti) se
## distingue claramente: pelo negro vs castaño, remera naranja vs gris a
## rayas, short verde vs azul marino.

const BAUTI := preload("res://assets/characters/Kids/EndOfWorld1/bauti.png")
const FAUSTO := preload("res://assets/characters/Kids/EndOfWorld1/fausto.png")

func _ready() -> void:
	get_window().size = Vector2i(500, 500)

	var bg := ColorRect.new()
	bg.size = Vector2(500, 500)
	bg.position = Vector2(-250, -250)
	bg.color = Color(0.55, 0.78, 0.4)
	bg.z_index = -10
	add_child(bg)

	var bauti := Sprite2D.new()
	bauti.texture = BAUTI
	bauti.position = Vector2(-40, 0)
	add_child(bauti)

	var fausto := Sprite2D.new()
	fausto.texture = FAUSTO
	fausto.position = Vector2(40, 0)
	add_child(fausto)

	var cam := Camera2D.new()
	cam.position = Vector2(0, 0)
	cam.zoom = Vector2(4.0, 4.0)
	add_child(cam)
	cam.make_current()

var frame := 0

func _process(_delta: float) -> void:
	frame += 1
	if frame == 10:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotA3_bauti_fausto.png")
		print("GUARDADA shotA3_bauti_fausto.png")
		get_tree().quit()

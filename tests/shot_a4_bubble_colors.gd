extends Node

## A4: captura real (no-headless) del globo de dialogo de los chicos (fondo
## marron del cuerpo de Luke, letras celestes de sus ojos) en 3 niveles
## reales distintos, para confirmar que el cambio de color se ve en el
## juego de verdad y no solo en una escena de prueba aislada.

const LEVELS := [
	"res://scenes/levels/world_1_level_1.tscn",
	"res://scenes/levels/world_2_level_2.tscn",
	"res://scenes/levels/world_4_level_3.tscn",
]

var idx := 0
var level: Node
var sign: Node
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(900, 700)
	_load_next()

func _load_next() -> void:
	if level != null:
		level.queue_free()
	level = load(LEVELS[idx]).instantiate()
	add_child(level)
	sign = level.get_node_or_null("MissionSign")
	frame = 0

func _process(_delta: float) -> void:
	if sign == null:
		return
	frame += 1
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		for c in level.get_children():
			if c is Camera2D:
				cam = c
	if cam:
		cam.global_position = sign.global_position + Vector2(0, -130)
		cam.zoom = Vector2(1.4, 1.4)
		cam.make_current()
	if frame == 3:
		sign.hint_label.text = sign.interaction_text
		sign.hint_label.visible = true
	if frame == 10:
		await RenderingServer.frame_post_draw
		var name_part: String = LEVELS[idx].get_file().get_basename()
		get_viewport().get_texture().get_image().save_png("res://../shotA4_bubble_%s.png" % name_part)
		print("GUARDADA shotA4_bubble_", name_part)
		idx += 1
		if idx >= LEVELS.size():
			get_tree().quit()
		else:
			_load_next()

extends Node

## A5: captura real (no-headless) con zoom de un tramo de pinchos del piso
## en los 4 mundos, para confirmar que ahora se distinguen claramente del
## fondo (mas contraste, contorno negro marcado, brillo en las puntas).

const LEVELS := [
	"res://scenes/levels/world_1_level_2.tscn",
	"res://scenes/levels/world_2_level_2.tscn",
	"res://scenes/levels/world_3_level_1.tscn",
	"res://scenes/levels/world_4_level_1.tscn",
]
const NODE_NAMES := ["SpikeHazardOne", "SpikeVisualsOne"]

var idx := 0
var level: Node
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(900, 700)
	_load_next()

func _load_next() -> void:
	if level != null:
		level.queue_free()
	level = load(LEVELS[idx]).instantiate()
	add_child(level)
	frame = 0

func _process(_delta: float) -> void:
	frame += 1
	if frame != 5:
		return
	var hazard: Node2D = null
	for n in NODE_NAMES:
		hazard = level.get_node_or_null(n)
		if hazard != null:
			break
	var cam := Camera2D.new()
	add_child(cam)
	cam.make_current()
	if hazard != null:
		cam.global_position = hazard.global_position + Vector2(0, -60)
	cam.zoom = Vector2(2.2, 2.2)
	await RenderingServer.frame_post_draw
	var name_part: String = LEVELS[idx].get_file().get_basename()
	get_viewport().get_texture().get_image().save_png("res://../shotA5_spikes_%s.png" % name_part)
	print("GUARDADA shotA5_spikes_", name_part, " hazard=", hazard)
	cam.queue_free()
	idx += 1
	if idx >= LEVELS.size():
		get_tree().quit()
	else:
		_load_next()

extends Node2D

## A7: capturas reales del pozo del bonus (DigSpot) en los 4 mundos, para
## confirmar que ahora se ve claramente, sin NPCs/objetos/decoracion
## pegados encima.

const LEVELS := [
	"res://scenes/levels/world_4_level_2.tscn",
]

var level: Node
var idx := 0
var frame := 0
var cam: Camera2D

func _ready() -> void:
	get_window().size = Vector2i(900, 600)
	_load_next()

func _load_next() -> void:
	if level != null:
		level.queue_free()
	if idx >= LEVELS.size():
		get_tree().quit()
		return
	level = load(LEVELS[idx]).instantiate()
	add_child(level)
	frame = 0

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 5:
		var dig := level.get_node("DigSpot")
		cam = Camera2D.new()
		cam.zoom = Vector2(3.0, 3.0)
		cam.position = dig.global_position + Vector2(0, -20)
		add_child(cam)
		cam.make_current()
	if frame == 12:
		await RenderingServer.frame_post_draw
		var level_name: String = LEVELS[idx].get_file().get_basename()
		get_viewport().get_texture().get_image().save_png("res://../shotA7_%s.png" % level_name)
		print("GUARDADA ", level_name)
		idx += 1
		_load_next()

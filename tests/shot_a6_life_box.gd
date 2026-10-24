extends Node2D

## A6: capturas reales de la cadena de plataformas de la vida escondida en
## cada mundo, para confirmar visualmente que se ve cada vez mas dificil
## (mas chica y separada) de Mundo 2 a Mundo 4.

const LEVELS := [
	"res://scenes/levels/world_1_level_1.tscn",
	"res://scenes/levels/world_2_level_1.tscn",
	"res://scenes/levels/world_3_level_1.tscn",
	"res://scenes/levels/world_4_level_1.tscn",
]

var level: Node
var idx := 0
var frame := 0
var cam: Camera2D

func _ready() -> void:
	get_window().size = Vector2i(1000, 900)
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
		var a := level.get_node("SecretPlatA")
		var box := level.get_node("SecretLifeBox")
		cam = Camera2D.new()
		cam.zoom = Vector2(0.85, 0.85)
		cam.position = (a.global_position + box.global_position) / 2.0
		add_child(cam)
		cam.make_current()
	if frame == 12:
		await RenderingServer.frame_post_draw
		var level_name: String = LEVELS[idx].get_file().get_basename()
		get_viewport().get_texture().get_image().save_png("res://../shotA6_%s.png" % level_name)
		print("GUARDADA ", level_name)
		idx += 1
		_load_next()

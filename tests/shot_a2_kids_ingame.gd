extends Node2D

## A2: captura real in-game del globo de dialogo de cada chico, con Luke
## parado al lado tras caminar desde el spawn (sin saltar), para verificar
## que el globo entra completo en pantalla con el arte real del nivel.

const LEVELS := [
	"res://scenes/levels/world_1_level_1.tscn",
	"res://scenes/levels/world_2_level_1.tscn",
	"res://scenes/levels/world_3_level_1.tscn",
	"res://scenes/levels/world_4_level_2.tscn",
]

var level: Node
var idx := 0
var frame := 0
var cam: Camera2D
var luke: Luke
var kid: Node2D

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	_load_next()

func _load_next() -> void:
	if level != null:
		level.queue_free()
	if idx >= LEVELS.size():
		get_tree().quit()
		return
	level = load(LEVELS[idx]).instantiate()
	add_child(level)
	luke = level.get_node("Luke")
	kid = level.get_node("MissionSign")
	frame = 0

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 5:
		luke.global_position = kid.global_position + Vector2(-70, 0)
		luke.velocity = Vector2.ZERO
		cam = Camera2D.new()
		cam.zoom = Vector2(1.0, 1.0)
		add_child(cam)
		cam.make_current()
	if frame == 10:
		cam.global_position = kid.global_position + Vector2(0, -150)
	if frame == 12:
		Input.action_press("attack")
	if frame == 13:
		Input.action_release("attack")
	if frame == 20:
		await RenderingServer.frame_post_draw
		var level_name: String = LEVELS[idx].get_file().get_basename()
		get_viewport().get_texture().get_image().save_png("res://../shotA2_%s.png" % level_name)
		print("GUARDADA ", level_name)
		idx += 1
		_load_next()

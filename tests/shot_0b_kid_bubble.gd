extends Node

## 0b: captura real del globo de dialogo de un chico, disparado de verdad
## (Luke parado al lado + boton apretado), en 2 niveles, para confirmar
## fondo marron (cuerpo de Luke) + letras celestes (ojos de Luke).

const LEVELS := [
	"res://scenes/levels/world_1_level_1.tscn",
	"res://scenes/levels/world_3_level_2.tscn",
]

var idx := 0
var level: Node
var kid: Node2D
var luke: Node2D
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(1000, 640)
	_load_next()

func _load_next() -> void:
	if level != null:
		level.queue_free()
	level = load(LEVELS[idx]).instantiate()
	add_child(level)
	luke = level.get_node("Luke")
	for n in level.get_children():
		if n is KidNpc:
			kid = n
	frame = 0

func _physics_process(_delta: float) -> void:
	if kid == null:
		return
	frame += 1
	if frame < 10:
		luke.global_position = kid.global_position + Vector2(-60, -20)
	if frame == 30:
		Input.action_press("interact")
	if frame == 32:
		Input.action_release("interact")
	var cam := get_viewport().get_camera_2d()
	if cam:
		cam.global_position = kid.global_position + Vector2(0, -150)
		cam.zoom = Vector2(1.6, 1.6)
	if frame == 45:
		await RenderingServer.frame_post_draw
		var name_part: String = LEVELS[idx].get_file().get_basename()
		get_viewport().get_texture().get_image().save_png("res://../shot0b_kid_bubble_%s.png" % name_part)
		print("GUARDADA shot0b_kid_bubble_", name_part, " visible=", kid.hint_label.visible)
		idx += 1
		if idx >= LEVELS.size():
			get_tree().quit()
		else:
			_load_next()

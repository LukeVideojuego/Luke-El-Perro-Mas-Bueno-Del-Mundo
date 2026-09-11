extends Node2D

## Captura real (con render de verdad, sin --headless) de zonas con carteles
## de mision / banderas de meta / minicercos, en varios niveles, con zoom,
## para verificar si de verdad tocan el piso.

const LEVELS := [
	"res://scenes/levels/world_1_level_1.tscn",
	"res://scenes/levels/world_2_level_1.tscn",
	"res://scenes/levels/world_3_level_1.tscn",
]

var level: Node
var idx := 0
var frame := 0
var cam: Camera2D

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
	frame = 0

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 5:
		cam = Camera2D.new()
		cam.zoom = Vector2(3.0, 3.0)
		add_child(cam)
		cam.make_current()
	if frame == 12:
		var sign_node: Node2D = level.get_node("MissionSign")
		cam.position = sign_node.global_position + Vector2(0, 32)
		await RenderingServer.frame_post_draw
		var path := "res://../shot_sign_%d.png" % idx
		get_viewport().get_texture().get_image().save_png(path)
		print("SAVED ", path)
	if frame == 20:
		var finish_node: Node2D = level.get_node_or_null("Finish")
		if finish_node != null:
			cam.position = finish_node.global_position + Vector2(0, 0)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://../shot_finish_%d.png" % idx)
			print("SAVED shot_finish_", idx)
	if frame == 28:
		var fence_node: Node2D = level.get_node_or_null("FenceA")
		if fence_node != null:
			cam.position = fence_node.global_position
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://../shot_fence_%d.png" % idx)
			print("SAVED shot_fence_", idx)
	if frame == 34:
		idx += 1
		_load_next()

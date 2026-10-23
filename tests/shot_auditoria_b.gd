extends Node2D

## Auditoria comercial: captura real de cada jefe EN PLENA PELEA (no parado
## quieto). Un controlador simple mueve a Luke hacia el jefe y ataca en
## bucle durante varios segundos antes de la foto, asi se ve a Luke
## atacando y al jefe reaccionando/moviendose.

const LEVELS := [
	{"scene": "res://scenes/levels/world_1_boss.tscn", "boss": "ThiefBoss", "label": "jefe1_don_sombra"},
	{"scene": "res://scenes/levels/world_2_boss.tscn", "boss": "WitchBoss", "label": "jefe2_bruja_olvido"},
	{"scene": "res://scenes/levels/world_3_boss.tscn", "boss": "CorruptBoss", "label": "jefe3_gran_codicia"},
	{"scene": "res://scenes/levels/world_4_boss.tscn", "boss": "SerpentBoss", "label": "jefe4_reina_veneno"},
]

var level: Node
var luke: Luke
var boss: Node2D
var cam: Camera2D
var frame := 0
var idx := -1

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	_next()

func _next() -> void:
	if level != null:
		level.queue_free()
		level = null
	idx += 1
	if idx >= LEVELS.size():
		print("LISTO: capturas de jefes terminadas")
		get_tree().quit()
		return
	var data: Dictionary = LEVELS[idx]
	level = load(String(data.scene)).instantiate()
	add_child(level)
	luke = level.get_node("Luke")
	boss = level.get_node(String(data.boss))
	# Arranca a Luke cerca del jefe (en vez de en su SpawnPoint lejano) para
	# que la pelea ya este en marcha para cuando se saque la foto.
	luke.global_position = boss.global_position + Vector2(-140.0, 0.0)
	cam = Camera2D.new()
	cam.zoom = Vector2(0.9, 0.9)
	add_child(cam)
	cam.make_current()
	frame = 0

func _physics_process(_delta: float) -> void:
	if idx < 0 or idx >= LEVELS.size() or level == null:
		return
	frame += 1
	if is_instance_valid(boss):
		cam.position = (luke.global_position + boss.global_position) / 2.0
	else:
		cam.position = luke.global_position
	# IA simple: caminar hacia el jefe y atacar sin parar.
	var dx: float = 0.0
	if is_instance_valid(boss):
		dx = boss.global_position.x - luke.global_position.x
	if absf(dx) > 70.0:
		Input.action_press("move_right" if dx > 0.0 else "move_left")
		Input.action_release("move_left" if dx > 0.0 else "move_right")
	else:
		Input.action_release("move_left")
		Input.action_release("move_right")
	if frame % 14 == 0:
		Input.action_press("attack")
	if frame % 14 == 2:
		Input.action_release("attack")

	var data: Dictionary = LEVELS[idx]
	if frame == 150:
		Input.action_release("move_left")
		Input.action_release("move_right")
		Input.action_release("attack")
		await RenderingServer.frame_post_draw
		var out_path := "res://auditoria/%s.png" % data.label
		get_viewport().get_texture().get_image().save_png(out_path)
		print("GUARDADA ", data.label)
		_next()

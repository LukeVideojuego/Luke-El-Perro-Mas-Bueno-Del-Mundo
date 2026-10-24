extends Node2D

## B1: capturas reales de los 4 bonus + el minijuego final en varios
## puntos de camara (centro, arriba de todo, abajo de todo, bien a la
## izquierda), para confirmar que no quedan zonas grises/vacias con los
## fondos nuevos + el limite de camara agregado a bonus_level.gd. Arranca
## el nivel igual que el juego real (level.start(luke), con la camara de
## Luke apagada como hace main.gd) para que la captura sea fiel.

const LEVELS := [
	"res://scenes/levels/bonus_world_1.tscn",
	"res://scenes/levels/bonus_world_2.tscn",
	"res://scenes/levels/bonus_world_3.tscn",
	"res://scenes/levels/bonus_world_4.tscn",
]
const LUKE_SCENE := preload("res://scenes/player/player.tscn")

var level: Node
var luke: Luke
var idx := 0
var frame := 0
var cam: Camera2D

func _ready() -> void:
	get_window().size = Vector2i(1920, 1080)
	_load_next()

func _load_next() -> void:
	if level != null:
		level.queue_free()
	if idx >= LEVELS.size():
		get_tree().quit()
		return
	level = load(LEVELS[idx]).instantiate()
	add_child(level)
	luke = LUKE_SCENE.instantiate()
	level.add_child(luke)
	var luke_camera: Camera2D = luke.get_node_or_null("Camera2D")
	if luke_camera != null:
		luke_camera.enabled = false
	level.start(luke)
	cam = level.get_node("Camera2D")
	frame = 0

func _physics_process(_delta: float) -> void:
	if idx >= LEVELS.size():
		return
	frame += 1
	var level_name: String = LEVELS[idx].get_file().get_basename()
	if frame == 90:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotB1_%s_mid.png" % level_name)
	if frame == 95:
		cam.global_position += Vector2(0, -2000)
	if frame == 100:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotB1_%s_top.png" % level_name)
	if frame == 105:
		cam.global_position += Vector2(0, 2500)
	if frame == 110:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotB1_%s_bottom.png" % level_name)
	if frame == 115:
		cam.global_position += Vector2(-3000, -800)
	if frame == 120:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotB1_%s_left.png" % level_name)
		idx += 1
		_load_next()

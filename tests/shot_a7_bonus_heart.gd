extends Node

## A7: captura real (no-headless) de la vida sobre la plataforma movil al
## final del recorrido, en los 4 bonus.

const BONUS_SCENES := [
	"res://scenes/levels/bonus_world_1.tscn",
	"res://scenes/levels/bonus_world_2.tscn",
	"res://scenes/levels/bonus_world_3.tscn",
	"res://scenes/levels/bonus_world_4.tscn",
]
const LUKE_SCENE := preload("res://scenes/player/player.tscn")

var idx := 0
var bonus: Node
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(700, 500)
	_load_next()

func _load_next() -> void:
	if bonus != null:
		bonus.queue_free()
	bonus = load(BONUS_SCENES[idx]).instantiate()
	add_child(bonus)
	var luke: Luke = LUKE_SCENE.instantiate()
	bonus.add_child(luke)
	bonus.start(luke)
	var platform: Node2D = bonus.get_node("HeartPlatform")
	# BonusLevel._physics_process() tira la camara hacia Luke todo el
	# tiempo (lerp): para una captura fija cerca del final del recorrido
	# hay que mover tambien a Luke ahi, si no la camara se va de nuevo
	# hacia el arranque del nivel en los primeros physics ticks.
	luke.global_position = Vector2(platform.global_position.x, 860.0)
	bonus.camera.global_position = platform.global_position + Vector2(0, -10)
	bonus.camera.zoom = Vector2(1.3, 1.3)
	frame = 0

func _process(_delta: float) -> void:
	frame += 1
	if frame == 10:
		await RenderingServer.frame_post_draw
		var name_part: String = BONUS_SCENES[idx].get_file().get_basename()
		get_viewport().get_texture().get_image().save_png("res://../shotA7_heart_%s.png" % name_part)
		print("GUARDADA shotA7_heart_", name_part)
		idx += 1
		if idx >= BONUS_SCENES.size():
			get_tree().quit()
		else:
			_load_next()

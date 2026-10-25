extends Node

## B1: capturas reales (no-headless) de los 4 fondos nuevos de los bonus,
## con la camara bien arriba (altura maxima de salto) y bien abajo, para
## confirmar que nunca se ve gris/vacio en el rango que la camara puede
## mostrar durante el juego.

const BONUS_SCENES := [
	"res://scenes/levels/bonus_world_1.tscn",
	"res://scenes/levels/bonus_world_2.tscn",
	"res://scenes/levels/bonus_world_3.tscn",
	"res://scenes/levels/bonus_world_4.tscn",
]

var idx := 0
var bonus: Node
var frame := 0
var shot_idx := 0
const SHOT_OFFSETS := [Vector2(0, -350), Vector2(0, 0), Vector2(0, 400)]

func _ready() -> void:
	get_window().size = Vector2i(960, 540)
	_load_next()

func _load_next() -> void:
	if bonus != null:
		bonus.queue_free()
	bonus = load(BONUS_SCENES[idx]).instantiate()
	add_child(bonus)
	bonus.camera.zoom = Vector2(1.0, 1.0)
	bonus.camera.global_position = Vector2(900, 900) + SHOT_OFFSETS[0]
	bonus.camera.make_current()
	frame = 0
	shot_idx = 0

func _process(_delta: float) -> void:
	frame += 1
	if frame == 6:
		await RenderingServer.frame_post_draw
		var name_part: String = BONUS_SCENES[idx].get_file().get_basename()
		get_viewport().get_texture().get_image().save_png("res://../shotB1_%s_%d.png" % [name_part, shot_idx])
		print("GUARDADA shotB1_", name_part, "_", shot_idx)
		shot_idx += 1
		frame = 0
		if shot_idx >= SHOT_OFFSETS.size():
			idx += 1
			if idx >= BONUS_SCENES.size():
				get_tree().quit()
			else:
				_load_next()
		else:
			bonus.camera.global_position = Vector2(900, 900) + SHOT_OFFSETS[shot_idx]

extends Node2D

## B1: capturas reales: el pozo con el hueso en un nivel real, el pozo ya
## usado, y una vista panoramica de cada uno de los 4 bonus.

const MAIN_SCENE := preload("res://scenes/main.tscn")
var main: Node
var frame := 0
var phase := 0

const BONUS_SHOTS := [
	{"path": "res://scenes/levels/bonus_world_1.tscn", "name": "mundo1_cielo"},
	{"path": "res://scenes/levels/bonus_world_2.tscn", "name": "mundo2_playa"},
	{"path": "res://scenes/levels/bonus_world_3.tscn", "name": "mundo3_lava"},
	{"path": "res://scenes/levels/bonus_world_4.tscn", "name": "mundo4_aurora"},
]
var bonus_idx := 0
var bonus_level: Node

func _ready() -> void:
	get_window().size = Vector2i(1100, 560)
	main = MAIN_SCENE.instantiate()
	add_child(main)

func _physics_process(_delta: float) -> void:
	frame += 1
	match phase:
		0:
			if frame == 2:
				var menu := main.get_node_or_null("MainMenu")
				if menu != null:
					menu.queue_free()
				GameState.reset_for_new_game()
				GameState.current_level_id = "world_1_level_2"
			if frame == 4:
				main.load_level("world_1_level_2")
			if frame == 10:
				var level: Node = main.active_level
				var dig: Node2D = level.get_node("DigSpot")
				var cam: Camera2D = level.get_node("Luke/Camera2D")
				cam.position = dig.global_position
				cam.zoom = Vector2(2.2, 2.2)
				phase = 1
				frame = 0
		1:
			if frame == 6:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://../shotB1_pozo_con_hueso.png")
				print("SAVED shotB1_pozo_con_hueso")
				# Recarga el mismo nivel ya marcado como usado (en vez de
				# cavar de verdad, que entraria al bonus): asi la foto
				# muestra el agujero solo, sin cruzar a otra pantalla.
				GameState.set_dig_spot_used("world_1_level_2", true)
				main.load_level("world_1_level_2")
				phase = 2
				frame = 0
		2:
			if frame == 10:
				var level: Node = main.active_level
				var dig: Node2D = level.get_node("DigSpot")
				var cam: Camera2D = level.get_node("Luke/Camera2D")
				cam.position = dig.global_position
				cam.zoom = Vector2(2.2, 2.2)
				phase = 3
				frame = 0
		3:
			if frame == 6:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://../shotB1_pozo_usado.png")
				print("SAVED shotB1_pozo_usado")
				phase = 4
				frame = 0
		4:
			main.queue_free()
			main = null
			_next_bonus()
			phase = 5
			frame = 0
		5:
			if frame == 10:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://../shotB1_bonus_%s.png" % BONUS_SHOTS[bonus_idx].name)
				print("SAVED shotB1_bonus_", BONUS_SHOTS[bonus_idx].name)
				bonus_idx += 1
				if bonus_idx >= BONUS_SHOTS.size():
					get_tree().quit()
				else:
					_next_bonus()
					frame = 0

func _next_bonus() -> void:
	if bonus_level != null:
		bonus_level.queue_free()
	bonus_level = load(BONUS_SHOTS[bonus_idx].path).instantiate()
	add_child(bonus_level)
	var cam: Camera2D = bonus_level.get_node("Camera2D")
	cam.zoom = Vector2(0.42, 0.42)
	cam.position = Vector2(2150, 750)
	cam.make_current()

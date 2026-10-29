extends Node

## Carga 3: rendimiento por nivel, con render REAL (correr SIN --headless) a
## 844x390 con la camara de celular. Luke recorre el nivel de punta a punta
## (lo va moviendo el test, invencible) y se mide por cuadro:
##  - tiempo real de cada cuadro completo (juego + dibujo), sin vsync ni
##    tope de FPS (los monitores TIME_* de Godot se refrescan de a ratos)
##  - llamadas de dibujo y objetos dibujados en el cuadro
##  - nodos, enemigos con fisica activos y cuantos estan dentro de camara
##
##   godot --path . res://tests/diag_perf_levels.tscn -- [nivel ...]

const MAIN_SCENE := preload("res://scenes/main.tscn")
const DEFAULT_LEVELS := ["world_4_level_3", "world_2_level_3", "world_3_level_2",
		"world_1_level_1", "world_1_boss", "world_2_boss", "world_3_boss", "world_4_boss"]

var main: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_window().size = Vector2i(844, 390)
	TouchControls.touch_mode = true
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await _frames(10)
	main._free_menu()
	main.game_started = true
	GameState.reset_for_new_game()
	var levels: Array = Array(OS.get_cmdline_user_args()).filter(func(a: String) -> bool: return not a.begins_with("--"))
	if levels.is_empty():
		levels = DEFAULT_LEVELS
	print("nivel             cuadro_ms: med      p95      max | draw_med draw_max | obj_max | nodos | enem(act/en_cam)")
	for lv in levels:
		await _measure(lv)
	get_tree().quit()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _measure(level_id: String) -> void:
	main.load_level(level_id)
	await _frames(30)
	var luke: Luke = main.active_level.get_node("Luke")
	luke.can_receive_damage = false
	var cam: Camera2D = luke.get_node("Camera2D")
	var x0 := float(cam.limit_left) + 150.0
	var x1 := float(cam.limit_right) - 150.0
	var cpu: Array[float] = []
	var draws: Array[float] = []
	var objs := 0.0
	var enemies_max := 0
	var oncam_max := 0
	var steps := 600
	var last := Time.get_ticks_usec()
	for i in steps:
		# Avanza como si corriera (y vuelve a su altura si se cae).
		var x := lerpf(x0, x1, float(i) / float(steps))
		if absf(luke.global_position.x - x) > 40.0 or luke.global_position.y > 1100.0:
			luke.global_position = Vector2(x, 700.0)
			luke.velocity = Vector2.ZERO
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		cpu.append((now - last) / 1000.0)
		last = now
		if OS.get_cmdline_user_args().has("--picos") and cpu[-1] > 3.5 and i > 5:
			print("  pico %.1f ms cuadro %d luke %s nodos %d" % [cpu[-1], i, luke.global_position.round(), get_tree().get_node_count()])
		draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		objs = maxf(objs, Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
		if i % 30 == 0:
			var view := get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_visible_rect()
			var act := 0
			var oncam := 0
			for n in main.active_level.find_children("*", "CharacterBody2D", true, false):
				if n is EnemyBase and n.is_physics_processing() and not n.is_defeated:
					act += 1
					if view.has_point(n.global_position):
						oncam += 1
			enemies_max = maxi(enemies_max, act)
			oncam_max = maxi(oncam_max, oncam)
	cpu.sort()
	draws.sort()
	print("%-20s %7.2f  %7.2f  %7.2f | %8.0f %8.0f | %7.0f | %5d | %d/%d" % [level_id,
			cpu[cpu.size() / 2], cpu[int(cpu.size() * 0.95)], cpu[-1],
			draws[draws.size() / 2], draws[-1], objs,
			main.active_level.get_tree().get_node_count(), enemies_max, oncam_max])

extends Node2D

const MAIN_SCENE := preload("res://scenes/main.tscn")

var main: Node
var frame := 0
var phase := 0
var wait_start := 0
var failures := 0

const WATCHDOG_FRAMES := 900
const STABLE_FRAMES := 5

var expected_level := ""
var stable_frames := 0

func _ready() -> void:
	main = MAIN_SCENE.instantiate()
	add_child(main)

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		printerr("FAIL: ", label)

func _phase(to: int) -> void:
	phase = to
	wait_start = frame
	stable_frames = 0
	print("PHASE->", to, " at frame ", frame)

func _current_level() -> Node:
	var container := main.get_node("LevelContainer")
	return container.get_child(container.get_child_count() - 1)

func _transition() -> CanvasLayer:
	return main.get_node("LevelTransition")

func _waited() -> bool:
	return frame - wait_start > WATCHDOG_FRAMES

func _is_stable(target: String) -> bool:
	if GameState.current_level_id != target:
		stable_frames = 0
		return false
	if main.is_transitioning or _transition().get_node("Overlay").visible:
		stable_frames = 0
		return false
	stable_frames += 1
	return stable_frames >= STABLE_FRAMES

func _teleport_to_finish() -> void:
	var level := _current_level()
	var luke: Node2D = level.get_node("Luke")
	var finish: Node2D = level.get_node("Finish")
	luke.global_position = finish.global_position
	print("TELEPORT en nivel ", GameState.current_level_id)

func _physics_process(_delta: float) -> void:
	frame += 1
	match phase:
		0:
			if frame == 10:
				_check(main.get_node_or_null("MainMenu") != null, "menú principal presente al arrancar")
				_check(GameState.current_level_id == "", "ningún nivel activo antes de empezar")
				main.start_game()
				expected_level = "world_1_level_1"
				_phase(1)
		1:
			if _is_stable(expected_level):
				_teleport_to_finish()
				expected_level = "world_1_level_2"
				_phase(2)
			elif _waited():
				_check(false, "world_1_level_1 cargado")
				_fail_early()
		2:
			if _is_stable(expected_level):
				_check(main.is_transitioning == false, "transición a world_1_level_2 finalizada")
				_check(not _transition().get_node("Overlay").visible, "overlay oculto tras el fade-out")
				_teleport_to_finish()
				expected_level = "world_1_level_3"
				_phase(3)
			elif _waited():
				_check(false, "world_1_level_2 cargado")
				_fail_early()
		3:
			if _is_stable(expected_level):
				_check(main.is_transitioning == false, "transición a world_1_level_3 finalizada")
				_check(not _transition().get_node("Overlay").visible, "overlay oculto tras la segunda transición")
				_teleport_to_finish()
				expected_level = "world_1_boss"
				_phase(4)
			elif _waited():
				_check(false, "world_1_level_3 cargado")
				_fail_early()
		4:
			if _is_stable(expected_level):
				_check(_current_level().get_node_or_null("ThiefBoss") != null, "nivel jefe del Mundo 1 cargado")
				print("RESULTADO: ", 0 if failures == 0 else failures, " fallos")
				get_tree().quit(failures)
			elif _waited():
				_check(false, "world_1_boss cargado")
				_fail_early()

func _fail_early() -> void:
	print("RESULTADO: 1 fallo")
	get_tree().quit(1)

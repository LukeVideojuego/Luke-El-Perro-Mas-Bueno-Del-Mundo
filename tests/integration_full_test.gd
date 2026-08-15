extends Node2D

## Test de integración de CADENA COMPLETA: menú → 4 mundos (niveles + jefes) → pantalla final.
## Derrota jefes llamando a receive_attack y completa niveles teletransportando a Luke a la meta.

const MAIN_SCENE := preload("res://scenes/main.tscn")

const CHAIN := [
	"world_1_level_1", "world_1_level_2", "world_1_level_3", "world_1_boss",
	"world_2_level_1", "world_2_level_2", "world_2_level_3", "world_2_boss",
	"world_3_level_1", "world_3_level_2", "world_3_level_3", "world_3_boss",
	"world_4_level_1", "world_4_level_2", "world_4_level_3", "world_4_boss",
	"final_screen",
]

var main: Node
var frame := 0
var phase := 1
var chain_index := 0
var wait_start := 0
var stable_frames := 0
var failures := 0

## La cinemática final ahora tiene 2 paneles con timeout automático de 10s
## cada uno (hasta ~1200 frames a 60fps) antes de cargar final_screen.
const WATCHDOG_FRAMES := 1300
const STABLE_FRAMES := 5

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

func _teleport_to_finish() -> bool:
	var level := _current_level()
	if not level.has_node("Finish") or not level.has_node("Luke"):
		return false
	var luke: Node2D = level.get_node("Luke")
	var finish: Node2D = level.get_node("Finish")
	luke.global_position = finish.global_position
	return true

func _hug_everyone() -> bool:
	var level := _current_level()
	var luke := level.get_node("Luke")
	var people := level.get_tree().get_nodes_in_group("huggable")
	if people.is_empty():
		return false
	for person in people:
		person._on_body_entered(luke)
	return true

func _defeat_boss() -> bool:
	var level := _current_level()
	var luke := level.get_node("Luke")
	for child in level.get_children():
		if child is BossBase:
			var hits := int(child.max_health)
			for i in hits:
				child.receive_attack(luke)
			return true
	return false

func _complete_current_step() -> bool:
	var step: String = CHAIN[chain_index]
	var is_boss := step.ends_with("_boss")
	if is_boss:
		return _defeat_boss()
	return _teleport_to_finish()

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 10:
		_check(main.get_node_or_null("MainMenu") != null, "menú principal presente al arrancar")
		main.start_game()
		_phase(1)
	match phase:
		1:
			var target: String = CHAIN[chain_index]
			if _is_stable(target):
				var is_last := chain_index == CHAIN.size() - 1
				if is_last:
					_check(GameState.current_level_id == "final_screen", "pantalla final alcanzada (toda la progresión)")
					var ok := _hug_everyone()
					_check(ok, "minijuego de abrazos disponible en la pantalla final")
					_phase(2)
				else:
					var completed := _complete_current_step()
					_check(completed, "completado " + target)
					chain_index += 1
					_phase(1)
			elif _waited():
				_check(false, "nivel cargado: " + target)
				_fail_early()
		2:
			if not main.is_transitioning and _transition().get_node("Overlay").visible:
				var title: String = _transition().get_node("Overlay/Center/Title").text
				_check(title == "¡JUEGO COMPLETADO!", "overlay de '¡JUEGO COMPLETADO!' mostrado tras la pantalla final")
				print("RESULTADO: ", 0 if failures == 0 else failures, " fallos")
				get_tree().quit(failures)
			elif _waited():
				_check(false, "juego completado mostrado")
				_fail_early()

func _fail_early() -> void:
	print("RESULTADO: 1 fallo")
	get_tree().quit(1)

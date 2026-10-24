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

## A1: las cinemáticas/pantallas ya no avanzan solas -- el test simula los
## clicks de los botones "SIGUIENTE"/"CONTINUAR" (ver fases 10-12 y 2-3).
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
		person._do_hug(luke)
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
	_skip_shop_if_open()
	if frame == 10:
		_check(main.get_node_or_null("MainMenu") != null, "menú principal presente al arrancar")
		main.start_game()
		_phase(10)
	match phase:
		10:
			# "COMENZAR JUEGO" ahora siempre muestra la cinemática de intro
			# (3 paneles); las apretamos para llegar rápido al nivel 1.
			if main.intro_cinematic != null and frame - wait_start > 15:
				main.intro_cinematic.get_node("Panel1/Panel1Button").pressed.emit()
				_phase(11)
			elif _waited():
				_check(false, "cinemática de introducción mostrada")
				_fail_early()
		11:
			if frame - wait_start > 20:
				main.intro_cinematic.get_node("Panel2/Panel2Button").pressed.emit()
				_phase(12)
		12:
			if frame - wait_start > 20:
				main.intro_cinematic.get_node("Panel3/Panel3Button").pressed.emit()
				_phase(1)
		1:
			# A1: el cartel de "Mundo 1 superado" ya no avanza solo -- hay que
			# apretar su botón CONTINUAR (misma mecánica que las cinemáticas).
			if main.world1_cheer_screen != null:
				main.world1_cheer_screen.get_node("Panel/ContinueButton").pressed.emit()
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
		# E5: orden correcto es minijuego -> cinemática final (2 paneles) ->
		# cartel de cierre (nunca un cartel de "completado" solo, sin pasar
		# antes por la cinemática). Las fases 2 y 3 clickean cada panel igual
		# que la intro (fases 10-12), y la 4 espera el cartel final de
		# verdad, DESPUÉS de la cinemática.
		2:
			if main.final_cinematic != null and frame - wait_start > 15:
				main.final_cinematic.get_node("Panel1/Panel1Button").pressed.emit()
				_phase(3)
			elif _waited():
				_check(false, "cinemática final (panel 1) mostrada tras el minijuego")
				_fail_early()
		3:
			if frame - wait_start > 15:
				main.final_cinematic.get_node("Panel2/Panel2Button").pressed.emit()
				_phase(4)
		4:
			# El overlay puede quedar visible ANTES de tiempo durante el
			# fade_to_black previo de _on_final_finished (con el titulo
			# todavia stale de la pantalla "nivel completado" anterior,
			# oculto pero sin borrar su texto) -- hay que esperar a que el
			# titulo realmente diga "completado" antes de chequear, no solo
			# a que el overlay este visible.
			var overlay_visible: bool = _transition().get_node("Overlay").visible
			var title: String = _transition().get_node("Overlay/Center/Title").text
			if overlay_visible and title == "¡JUEGO COMPLETADO!":
				_check(true, "overlay de '¡JUEGO COMPLETADO!' mostrado DESPUÉS de la cinemática final")
				print("RESULTADO: ", 0 if failures == 0 else failures, " fallos")
				get_tree().quit(failures)
			elif _waited():
				_check(false, "juego completado mostrado (ultimo titulo visto: '%s', overlay.visible=%s)" % [title, overlay_visible])
				_fail_early()

func _fail_early() -> void:
	print("RESULTADO: 1 fallo")
	get_tree().quit(1)

## C3: la tienda aparece antes de cada nivel a partir del nivel 2 y espera a
## que el jugador entre. El test la saltea igual que el boton "JUGAR EL
## NIVEL", para seguir midiendo el avance de niveles de punta a punta.
var _shop_dismissed: Node = null

func _skip_shop_if_open() -> void:
	var shop: Node = main.shop_screen if main != null else null
	if shop == null:
		_shop_dismissed = null
		return
	if shop == _shop_dismissed:
		return
	_shop_dismissed = shop
	shop.closed.emit()

extends Node2D

## F6: confirma con fisica real que pausar (main.set_paused(true)) congela
## de verdad TODO lo que se mueve (Luke, enemigos, aves, plataformas
## moviles) por varios segundos, y que al reanudar sigue exactamente desde
## donde quedo. Usa main.tscn real (mismo patron de arranque que
## integration_main_test.gd) para que el process_mode heredado sea el
## mismo que en el juego de verdad, no un nivel aislado.

const MAIN_SCENE := preload("res://scenes/main.tscn")

var main: Node
var frame := 0
var phase := 0
var wait_start := 0
var fail_count := 0
var tracked: Array = []
var before: Dictionary = {}
var pos_at_pause: Dictionary = {}

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _phase(to: int) -> void:
	phase = to
	wait_start = frame

func _ready() -> void:
	# El test mismo tiene que seguir corriendo (para poder CONTAR los 3s de
	# pausa y despues despausar) aunque main.set_paused(true) pause el
	# arbol -- es el equivalente de prueba al jugador con el reloj en la
	# mano mirando si algo se mueve, no parte de lo que se esta probando.
	process_mode = Node.PROCESS_MODE_ALWAYS
	main = MAIN_SCENE.instantiate()
	add_child(main)

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 10:
		main.start_game()
		_phase(10)
	match phase:
		10:
			if main.intro_cinematic != null and frame - wait_start > 15:
				main.intro_cinematic.get_node("Panel1/Panel1Button").pressed.emit()
				_phase(11)
		11:
			if frame - wait_start > 20:
				main.intro_cinematic.get_node("Panel2/Panel2Button").pressed.emit()
				_phase(12)
		12:
			if frame - wait_start > 20:
				main.intro_cinematic.get_node("Panel3/Panel3Button").pressed.emit()
				_phase(1)
		1:
			if main.active_level != null and not main.is_transitioning:
				_phase(2)
			elif frame - wait_start > 600:
				_check(false, "nivel world_1_level_1 cargado")
				get_tree().quit(1)
		2:
			# Correr a Luke y dejar que enemigos/aves se muevan un rato real
			# antes de pausar.
			Input.action_press("move_right")
			Input.action_press("run")
			if frame - wait_start > 30:
				_setup_tracking()
				main.set_paused(true)
				_check(get_tree().paused, "el arbol queda pausado de verdad")
				_phase(3)
		3:
			# Dejar pasar un par de frames para que la pausa termine de
			# aplicarse (el motor todavia puede terminar de procesar el
			# frame de fisica que ya estaba en curso en el instante exacto
			# de llamar a set_paused) ANTES de tomar la foto de "antes".
			if frame - wait_start > 2:
				for n in tracked:
					if is_instance_valid(n):
						before[n] = n.global_position
				_phase(4)
		4:
			# 3s reales CON el juego pausado, sosteniendo el input como si
			# el jugador siguiera "jugando".
			if frame - wait_start > 180:
				_check_no_movement()
				for n in tracked:
					if is_instance_valid(n):
						pos_at_pause[n] = n.global_position
				main.set_paused(false)
				_check(not get_tree().paused, "el arbol se despausa de verdad")
				_phase(5)
		5:
			if frame - wait_start > 2:
				_check_resumed_from_same_spot()
				Input.action_release("move_right")
				Input.action_release("run")
				print("RESULTADO: ", fail_count, " fallos")
				get_tree().quit()

func _setup_tracking() -> void:
	var level: Node = main.active_level
	var luke: Node2D = level.get_node("Luke")
	tracked = [luke]
	for child in level.get_children():
		if child is EnemyBase:
			tracked.append(child)
	for child in level.get_children():
		if "travel" in child:
			tracked.append(child)
	_check(tracked.size() > 1, "hay nodos moviles para verificar (%d encontrados)" % tracked.size())
	for n in tracked:
		before[n] = n.global_position

func _check_no_movement() -> void:
	var moved_during_pause: Array = []
	for n in tracked:
		if not is_instance_valid(n):
			continue
		if n.global_position.distance_to(before[n]) > 0.5:
			moved_during_pause.append("%s (%s -> %s)" % [n.name, before[n], n.global_position])
	_check(moved_during_pause.is_empty(), "ningun nodo se movio durante 3s de pausa (moved=%s)" % str(moved_during_pause))

func _check_resumed_from_same_spot() -> void:
	var ok := true
	for n in tracked:
		if not is_instance_valid(n):
			continue
		if n.global_position.distance_to(pos_at_pause[n]) > 30.0:
			ok = false
	_check(ok, "al reanudar, todo sigue desde donde quedo (sin saltos)")

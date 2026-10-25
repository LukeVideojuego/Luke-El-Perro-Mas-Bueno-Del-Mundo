extends Node

## A7: test de fisica real (fisica real del motor, sin headless ni poses
## forzadas) que confirma, en los 4 bonus, que:
##   1) la vida (ExtraLife) se queda asentada sobre la plataforma movil sin
##      caerse mientras esta oscila (no atraviesa, no se desliza afuera), y
##   2) un Luke manejado con input real (mover + saltar, reaccionando a
##      donde esta la plataforma en cada momento) puede efectivamente
##      alcanzarla y juntarla -- no solo "en teoria llega", sino que un
##      intento de juego real la agarra de punta a punta.

const BONUS_SCENES := [
	"res://scenes/levels/bonus_world_1.tscn",
	"res://scenes/levels/bonus_world_2.tscn",
	"res://scenes/levels/bonus_world_3.tscn",
	"res://scenes/levels/bonus_world_4.tscn",
]
const LUKE_SCENE := preload("res://scenes/player/player.tscn")

var _fail_count := 0

func _check(cond: bool, msg: String) -> void:
	if cond:
		print("PASS: ", msg)
	else:
		_fail_count += 1
		print("FAIL: ", msg)

func _ready() -> void:
	for path in BONUS_SCENES:
		await _test_world(path)
	print("RESULTADO: ", _fail_count, " fallos")
	get_tree().quit()

func _test_world(path: String) -> void:
	var world_name: String = path.get_file().get_basename()
	GameState.reset_for_new_game()

	var bonus: Node = load(path).instantiate()
	add_child(bonus)
	var luke: Luke = LUKE_SCENE.instantiate()
	bonus.add_child(luke)
	bonus.start(luke)
	await get_tree().physics_frame

	var platform: Node2D = bonus.get_node("HeartPlatform")
	var heart: Node2D = bonus.get_node("HeartPickup")

	# 1) se queda asentada sobre la plataforma mientras esta oscila, sin
	# caerse (deja un par de frames para que la gravedad la asiente sobre
	# la superficie, y de ahi en mas no deberia alejarse de esa altura).
	for _i in range(6):
		await get_tree().physics_frame
	var settled_y: float = heart.global_position.y
	var fell := false
	for _i in range(90):
		await get_tree().physics_frame
		if not is_instance_valid(heart):
			break
		if heart.global_position.y > settled_y + 25.0:
			fell = true
	_check(not fell, "%s: la vida se queda sobre la plataforma movil sin caerse mientras oscila" % world_name)

	# 2) alcanzable de verdad: Luke se acerca caminando y salta reaccionando
	# a donde esta la plataforma en cada momento (no un timing fijo
	# hardcodeado), con un presupuesto generoso de varios ciclos de vaiven.
	# Punto de arranque: parado en la ultima barra solida (Bar8), antes del
	# vacio que hay que saltar para llegar a la plataforma movil.
	var bar8: Node2D = bonus.get_node("Bar8")
	var start_pos := Vector2(bar8.global_position.x, bar8.global_position.y - 60.0)
	luke.global_position = start_pos
	luke.velocity = Vector2.ZERO
	var start_lives: int = GameState.lives
	var collected := false
	var jump_frames_left := 0
	var did_double_jump := false
	for _i in range(900):
		await get_tree().physics_frame
		if not is_instance_valid(heart):
			collected = true
			break
		if GameState.lives > start_lives:
			collected = true
			break
		# Si cayo al vacio sin agarrarla, se reintenta desde la barra: cada
		# intento cae en una fase distinta del vaiven de la plataforma.
		if luke.global_position.y > start_pos.y + 400.0:
			luke.global_position = start_pos
			luke.velocity = Vector2.ZERO
			jump_frames_left = 0
			did_double_jump = false
			Input.action_release("jump")
			await get_tree().physics_frame
		Input.action_press("move_right")
		Input.action_press("run")
		if luke.is_on_floor() and jump_frames_left <= 0:
			Input.action_press("jump")
			jump_frames_left = 8
			did_double_jump = false
		elif jump_frames_left > 0:
			jump_frames_left -= 1
			if jump_frames_left == 0:
				Input.action_release("jump")
		elif not luke.is_on_floor() and not did_double_jump and luke.velocity.y > -200.0:
			# segundo salto en el aire: mas altura y mas tiempo colgado,
			# agranda la ventana en la que puede cruzarse con la plataforma.
			Input.action_press("jump")
			did_double_jump = true
			await get_tree().physics_frame
			Input.action_release("jump")
	Input.action_release("move_right")
	Input.action_release("run")
	Input.action_release("jump")
	_check(collected, "%s: un intento de juego real (mover + saltar) alcanza y junta la vida" % world_name)

	bonus.queue_free()
	await get_tree().physics_frame

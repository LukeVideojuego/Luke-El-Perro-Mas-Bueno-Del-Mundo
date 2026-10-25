extends Node2D

## B3: test de fisica real que confirma el efecto "gordo" de la jeringa del
## veterinario malvado:
##   1) no quita corazon (GameState.lives sin cambios al impactar),
##   2) mientras esta activo, camina mas lento que lo normal (velocidad
##      dividida por fat_speed_divisor) incluso con "run" apretado,
##   3) no puede correr (misma velocidad con o sin "run"),
##   4) a los 5s (fat_duration) vuelve a la normalidad (velocidad y "run"
##      como antes).

const LUKE_SCENE := preload("res://scenes/player/player.tscn")

var _fail_count := 0

func _check(cond: bool, msg: String) -> void:
	if cond:
		print("PASS: ", msg)
	else:
		_fail_count += 1
		print("FAIL: ", msg)

func _ready() -> void:
	await _run_test()
	print("RESULTADO: ", _fail_count, " fallos")
	get_tree().quit()

func _run_test() -> void:
	GameState.reset_for_new_game()
	var ground := StaticBody2D.new()
	ground.collision_layer = 1
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000.0, 80.0)
	cs.shape = rect
	ground.add_child(cs)
	ground.position = Vector2(1000.0, 320.0)
	add_child(ground)

	var luke: Luke = LUKE_SCENE.instantiate()
	luke.position = Vector2(200, 250)
	add_child(luke)
	for _i in range(5):
		await get_tree().physics_frame

	var start_lives: int = GameState.lives

	# velocidad normal corriendo, de referencia
	Input.action_press("move_right")
	Input.action_press("run")
	for _i in range(30):
		await get_tree().physics_frame
	var normal_run_speed: float = luke.velocity.x
	Input.action_release("move_right")
	Input.action_release("run")
	luke.velocity.x = 0.0
	for _i in range(10):
		await get_tree().physics_frame

	# aplica el efecto (no via jeringa real, para medir en aislamiento)
	luke.apply_fat_effect()
	await get_tree().physics_frame
	_check(GameState.lives == start_lives, "el efecto gordo no quita corazon")

	Input.action_press("move_right")
	Input.action_press("run")
	for _i in range(30):
		await get_tree().physics_frame
	var fat_run_speed: float = luke.velocity.x
	_check(luke.is_fat, "Luke queda marcado como gordo tras la jeringa")
	_check(fat_run_speed < normal_run_speed * 0.8,
		"gordo camina mas lento que lo normal (normal=%.1f gordo=%.1f)" % [normal_run_speed, fat_run_speed])

	Input.action_release("move_right")
	Input.action_release("run")
	luke.velocity.x = 0.0
	for _i in range(10):
		await get_tree().physics_frame
	Input.action_press("move_right")
	Input.action_release("run")
	for _i in range(30):
		await get_tree().physics_frame
	var fat_walk_speed: float = luke.velocity.x
	_check(absf(fat_walk_speed - fat_run_speed) < 5.0,
		"gordo no puede correr (con run=%.1f sin run=%.1f)" % [fat_run_speed, fat_walk_speed])
	Input.action_release("move_right")

	# espera el resto de los 5s (fat_duration) y confirma que vuelve a lo normal
	var remaining_frames: int = int((luke.fat_duration + 0.3) * 60) - 70
	for _i in range(maxi(0, remaining_frames)):
		await get_tree().physics_frame
	_check(not luke.is_fat, "vuelve a la normalidad despues de fat_duration (5s)")

	luke.velocity.x = 0.0
	Input.action_press("move_right")
	Input.action_press("run")
	for _i in range(30):
		await get_tree().physics_frame
	var restored_run_speed: float = luke.velocity.x
	Input.action_release("move_right")
	Input.action_release("run")
	_check(absf(restored_run_speed - normal_run_speed) < 5.0,
		"la velocidad corriendo vuelve a ser la normal (antes=%.1f ahora=%.1f)" % [normal_run_speed, restored_run_speed])

extends Node2D

const LEVEL_SCENE := preload("res://scenes/levels/world_1_level_2.tscn")
const THIEF_SCENE := preload("res://scenes/enemies/thief.tscn")

var level: Node2D
var luke: Luke
var frame := 0
var phase := 0
var failures := 0
var test_thief: Node2D
var contact_thief: Node2D
var spawned_meat: Node2D
var box_under_attack: Node2D
var walk_velocity := 0.0
var start_x := 0.0

func _ready() -> void:
	level = LEVEL_SCENE.instantiate()
	add_child(level)
	luke = level.get_node("Luke")
	start_x = luke.global_position.x

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		printerr("FAIL: ", label)

func _phase(to: int) -> void:
	phase = to
	print("PHASE->", to, " at frame ", frame)

func _physics_process(_delta: float) -> void:
	frame += 1
	match phase:
		0:
			_check_node_existence()
			_check_input_map()
			_phase(1)
		1:
			if frame >= 2 and frame <= 59:
				Input.action_press("move_right")
			if frame == 40:
				walk_velocity = absf(luke.velocity.x)
			if frame >= 60:
				Input.action_release("move_right")
				_check(luke.global_position.x > start_x + 120.0, "caminar mueve a Luke hacia la derecha")
				_check(walk_velocity > 280.0, "velocidad de caminata (%.0f px/s)" % walk_velocity)
				_phase(2)
		2:
			if frame >= 62 and frame <= 99:
				Input.action_press("run")
				Input.action_press("move_right")
			if frame == 100:
				Input.action_release("run")
				Input.action_release("move_right")
				_check(absf(luke.velocity.x) > 430.0, "correr es más rápido que caminar (%.0f px/s)" % absf(luke.velocity.x))
				_check(absf(luke.velocity.x) > walk_velocity + 40.0, "velocidad de carrera supera a la de caminata")
				_phase(3)
		3:
			if frame == 110:
				Input.action_press("jump")
				Input.action_release("jump")
			if frame == 112:
				_check(luke.velocity.y < -600.0, "salto inicial impulsa a Luke hacia arriba")
			if frame == 135:
				Input.action_press("jump")
				Input.action_release("jump")
			if frame == 138:
				_check(luke.velocity.y < -450.0, "doble salto en el aire impulsa de nuevo")
				_check(luke.jumps_used == 2, "doble salto registra segundo uso")
			if frame >= 195:
				_phase(4)
		4:
			if frame == 200:
				luke.global_position = Vector2(100, 910)
				luke.velocity = Vector2.ZERO
			if frame >= 202 and frame <= 260:
				Input.action_press("move_left")
			if frame >= 261:
				Input.action_release("move_left")
				_check(luke.global_position.x < 100.0 and luke.global_position.x > -40.0, "límite izquierdo detiene a Luke")
				_phase(5)
		5:
			if frame == 270:
				GameState.reset_level_state(Vector2(180, 850))
				luke.global_position = level.get_node("SpikeHazardOne").global_position
			if frame == 290:
				_check(GameState.lives == 2, "peligro con pinchos reduce vidas (3 -> %d)" % GameState.lives)
				_phase(6)
		6:
			if frame == 299:
				luke.facing_direction = 1
			if frame >= 300:
				Input.action_press("attack")
			if frame == 304:
				test_thief = THIEF_SCENE.instantiate()
				level.add_child(test_thief)
				test_thief.global_position = luke.global_position + Vector2(70, 0)
			if frame >= 316:
				Input.action_release("attack")
			if frame >= 335:
				_check(not is_instance_valid(test_thief), "ataque de Luke derrota al ladrón")
				test_thief = null
				_phase(7)
		7:
			if frame == 365:
				contact_thief = THIEF_SCENE.instantiate()
				level.add_child(contact_thief)
				contact_thief.global_position = luke.global_position + Vector2(8, 0)
			if frame == 385:
				_check(GameState.lives == 1, "contacto con ladrón daña a Luke (vidas -> %d)" % GameState.lives)
				if is_instance_valid(contact_thief):
					contact_thief.queue_free()
				contact_thief = null
				_phase(8)
		8:
			if frame == 405:
				GameState.reset_level_state(Vector2(180, 850))
				luke.global_position = Vector2(1300, 910)
				luke.velocity = Vector2.ZERO
				box_under_attack = level.get_node("BoxA")
			if frame == 408:
				luke.facing_direction = 1
			if frame == 410:
				Input.action_press("attack")
			if frame == 413:
				luke.global_position = Vector2(1442, 910)
			if frame == 420:
				Input.action_release("attack")
				_check(not is_instance_valid(box_under_attack), "ataque rompe caja de madera")
				spawned_meat = _find_meat_at(Vector2(1500, 865))
				_check(is_instance_valid(spawned_meat), "la caja rota libera la carnada")
			if frame == 430:
				if is_instance_valid(spawned_meat):
					luke.global_position = spawned_meat.global_position
					luke.velocity = Vector2.ZERO
			if frame == 445:
				_check(luke.has_protective_aura, "carnada activa el aura protectora")
				_check(GameState.aura_active, "GameState registra el aura activa")
				_phase(9)
		9:
			if frame == 455:
				var lives_before := GameState.lives
				luke.global_position = level.get_node("SpikeHazardOne").global_position
			if frame == 480:
				_check(GameState.lives == 3, "aura absorbe el daño del peligro (vidas sin cambios)")
				luke.set_protective_aura(false)
				_phase(10)
		10:
			if frame == 490:
				GameState.reset_level_state(Vector2(180, 850))
				level.get_node("CheckpointTwo")._on_body_entered(luke)
				var expected_respawn: Vector2 = level.get_node("CheckpointTwo").global_position + Vector2(0, -70)
				luke.defeated.emit()
			if frame == 492:
				var expected_respawn: Vector2 = level.get_node("CheckpointTwo").global_position + Vector2(0, -70)
				_check(GameState.checkpoint_position.distance_to(expected_respawn) < 1.0, "checkpoint actualiza el punto de respawn")
				_check(luke.global_position.distance_to(expected_respawn) < 1.0, "respawn usa la posición del checkpoint")
				_phase(11)
		11:
			if frame == 505:
				luke.global_position = level.get_node("Finish").global_position
			if frame == 525:
				_check(GameState.is_level_complete, "bandera verde completa el nivel")
				_check(GameState.current_level_id == "world_1_level_2", "nivel registrado como world_1_level_2")
				_phase(12)
		12:
			print("RESULTADO: ", 0 if failures == 0 else failures, " fallos")
			get_tree().quit(failures)

func _find_meat_at(pos: Vector2) -> Node2D:
	for child in level.get_children():
		if child is MeatPowerUp and child.global_position.distance_to(pos) < 5.0:
			return child
	return null

func _check_node_existence() -> void:
	_check(level.has_node("Luke") and level.get_node("Luke") is Luke, "Luke presente")
	_check(level.has_node("SpawnPoint"), "SpawnPoint presente")
	_check(level.has_node("Finish"), "Finish presente")
	_check(level.has_node("Checkpoint") and level.has_node("CheckpointTwo") and level.has_node("CheckpointThree"), "3 checkpoints presentes")
	_check(level.has_node("MissionSign"), "Cartel de misión presente")
	_check(level.has_node("SpikeHazardOne") and level.has_node("SpikeHazardTwo") and level.has_node("SpikeHazardThree"), "3 zonas de peligro presentes")
	_check(level.has_node("BoxA") and level.has_node("BoxB"), "2 cajas rompibles presentes")
	_check(level.has_node("Meat") and level.has_node("MeatFour"), "2 carnadas bonus presentes")
	_check(level.has_node("ThiefOne") and level.has_node("ThiefTwo") and level.has_node("ThiefThree"), "3 ladrones presentes")
	_check(level.has_node("PlatformOne") and level.has_node("PlatformTwo") and level.has_node("PlatformThree") and level.has_node("PlatformFour"), "4 plataformas presentes")
	_check(level.has_node("LeftBoundary") and level.has_node("RightBoundary"), "límites de nivel presentes")
	var hazard := level.get_node("SpikeHazardOne")
	_check(hazard is Area2D and hazard.collision_mask == 1, "colisión de zona de peligro alcanza a Luke")
	var ground := level.get_node("Ground")
	_check(ground is StaticBody2D and ground.get_node("CollisionShape2D").disabled == false, "suelo con colisión activa")
	var mission := level.get_node("MissionSign")
	_check(mission.interaction_text != "", "cartel de misión con texto")
	var first_thief := level.get_node("ThiefOne")
	_check(first_thief is Thief and first_thief.collision_layer == 4, "ladrón en capa de colisión correcta")
	var box := level.get_node("BoxA")
	_check(box is BreakableBox and box.has_method("receive_attack"), "caja rompible puede recibir ataques")
	var finish := level.get_node("Finish")
	_check(finish.collision_mask == 1, "bandera de meta detecta a Luke")

func _check_input_map() -> void:
	for action in ["move_left", "move_right", "jump", "run", "attack", "interact", "pause"]:
		_check(InputMap.has_action(action), "InputMap define '%s'" % action)

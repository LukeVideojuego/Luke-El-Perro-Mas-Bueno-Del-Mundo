extends Node

## A6: verifica con fisica real que la vida escondida de cada nivel sigue
## siendo alcanzable. Maneja a Luke con un "auto-climber" que apunta, salto
## a salto, a cada plataforma de la cadena secreta en orden (A -> B -> C ->
## ... -> caja): salta apenas puede (combo salto + doble salto en el apice,
## el maximo alcance posible) y dirige el movimiento horizontal hacia el
## proximo escalon, frenando al acercarse para no pasarse de largo en una
## plataforma chica. Si ni siquiera este agente optimo llega, nadie puede.

const LEVELS := [
	"world_1_level_1", "world_1_level_2", "world_1_level_3",
	"world_2_level_1", "world_2_level_2", "world_2_level_3",
	"world_3_level_1", "world_3_level_2", "world_3_level_3",
	"world_4_level_1", "world_4_level_2", "world_4_level_3",
]

const REACH_DIST := 140.0
const LEG_SECONDS := 2.5
const ARRIVE_X := 25.0

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	for level_id in LEVELS:
		await _check_level(level_id)
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _waypoints(level: Node) -> Array:
	var names := ["SecretPlatB", "SecretPlatC", "SecretPlatD", "SecretPlatE", "SecretPlatF", "SecretLifeBox"]
	var out: Array = []
	for n in names:
		var node: Node2D = level.get_node_or_null(n)
		if node != null:
			out.append(node)
	return out

func _check_level(level_id: String) -> void:
	var level: Node = load("res://scenes/levels/%s.tscn" % level_id).instantiate()
	add_child(level)
	await get_tree().physics_frame
	var luke: Luke = level.get_node("Luke")
	var box: Node2D = level.get_node("SecretLifeBox")
	var plat_a: Node2D = level.get_node("SecretPlatA")
	var waypoints := _waypoints(level)

	# Inmune a dano y con el checkpoint clavado en la propia cadena: un
	# enemigo/pincho de paso (ajeno a la cadena secreta) no debe poder
	# mandar a Luke de vuelta al spawn real y arruinar la medicion de la
	# geometria -- lo que se mide es si la cadena es escalable, no si
	# ademas hay que esquivar un bicho que pasaba por ahi.
	GameState.lives = 99
	GameState.checkpoint_position = plat_a.global_position
	luke.set_protective_aura(true)
	luke.global_position = plat_a.global_position + Vector2(0.0, -70.0)
	luke.velocity = Vector2.ZERO
	await get_tree().physics_frame

	var min_dist := luke.global_position.distance_to(box.global_position)

	for target in waypoints:
		var leg_frames := int(LEG_SECONDS * 60.0)
		var jumped := false
		for i in range(leg_frames):
			await get_tree().physics_frame
			var on_floor: bool = luke.is_on_floor()
			var dx: float = target.global_position.x - luke.global_position.x
			if absf(dx) > ARRIVE_X:
				if dx > 0.0:
					Input.action_press("move_right")
					Input.action_release("move_left")
				else:
					Input.action_press("move_left")
					Input.action_release("move_right")
			else:
				Input.action_release("move_left")
				Input.action_release("move_right")
			if on_floor and not jumped:
				jumped = true
				Input.action_press("jump")
				await get_tree().physics_frame
				Input.action_release("jump")
			# El doble salto solo se usa si hace falta: si al llegar al apice
			# del primero Luke TODAVIA esta mas abajo que el escalon de
			# destino, lo suma; si ya esta a la altura (o mas arriba), no lo
			# gasta, para no pasarse de largo en plataformas chicas con un
			# salto mas grande del necesario.
			elif jumped and luke.jumps_used == 1 and luke.velocity.y >= 0.0 \
					and luke.global_position.y > target.global_position.y:
				Input.action_press("jump")
				await get_tree().physics_frame
				Input.action_release("jump")
			var d: float = luke.global_position.distance_to(box.global_position)
			min_dist = minf(min_dist, d)
			if d <= REACH_DIST:
				break
			if jumped and on_floor and absf(dx) <= ARRIVE_X:
				break
		if min_dist <= REACH_DIST:
			break

	Input.action_release("move_left")
	Input.action_release("move_right")

	_check(min_dist <= REACH_DIST, "%s: vida escondida alcanzable (dist minima %.0fpx, box=%s)" % [level_id, min_dist, box.global_position])

	level.queue_free()
	await get_tree().process_frame

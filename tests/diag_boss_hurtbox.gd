extends Node2D

## B7: comprueba que un golpe en CUALQUIER parte del cuerpo del jefe le baja
## la vida, con el golpe cuerpo a cuerpo y con el huesito lanzado, en pose
## quieta y en pose de salto.
##
## Antes el ataque de Luke solo detectaba contra el CollisionShape2D del
## CharacterBody2D del jefe, que es su cuerpo FISICO (el que apoya en el
## piso): 32x51 px en Don Sombra para un sprite de ~230px de alto. Pegarle en
## la cabeza o en el torso no contaba.
##
## Para cada jefe se prueban 3 alturas (cabeza / torso / parte baja) x 2 poses
## x 2 ataques = 12 casos. La altura se saca del rectangulo real de la caja
## receptora, que a su vez se ajusta al rectangulo opaco de la textura que el
## jefe este mostrando en ese momento.

const BOSSES := [
	{"name": "Don Sombra (Mundo 1)", "path": "res://scenes/enemies/thief_boss.tscn"},
	{"name": "La Bruja del Olvido (Mundo 2)", "path": "res://scenes/enemies/witch_boss.tscn"},
	{"name": "El Gran Codicia (Mundo 3)", "path": "res://scenes/enemies/corrupt_boss.tscn"},
	{"name": "La Serpiente (Mundo 4)", "path": "res://scenes/enemies/serpent_boss.tscn"},
]
const LUKE_SCENE := preload("res://scenes/player/player.tscn")
const BONE_SCENE := preload("res://scenes/objects/thrown_bone.tscn")
const FLOOR_Y := 900.0
const BOSS_X := 1000.0

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: ", label)
	else:
		print("  FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	for boss_info in BOSSES:
		print("--- ", boss_info.name, " ---")
		for pose in ["quieto", "salto"]:
			var zones := await _measure_zones(boss_info, pose)
			if zones.is_empty():
				_check(false, "%s: no pude medir la silueta" % pose)
				continue
			print("  pose %-7s silueta y=[%.0f, %.0f] (alto %.0fpx)" % [
				pose, zones.top, zones.bottom, zones.bottom - zones.top])
			for zone_name in ["cabeza", "torso", "parte baja"]:
				var y: float = zones[zone_name]
				var hit_melee := await _try_melee(boss_info, pose, y)
				_check(hit_melee, "%s / %-10s / golpe  -> baja la vida" % [pose, zone_name])
				var hit_bone := await _try_bone(boss_info, pose, y)
				_check(hit_bone, "%s / %-10s / huesito -> baja la vida" % [pose, zone_name])
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _build_arena() -> Node2D:
	var arena := Node2D.new()
	add_child(arena)
	var ground := StaticBody2D.new()
	ground.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000.0, 80.0)
	shape.shape = rect
	ground.add_child(shape)
	ground.position = Vector2(BOSS_X, FLOOR_Y + 40.0)
	arena.add_child(ground)
	return arena

## Instancia el jefe, lo deja asentarse, lo congela en la pose pedida y
## devuelve [arena, boss].
func _spawn_boss(boss_info: Dictionary, pose: String) -> Array:
	var arena := _build_arena()
	var boss: Node2D = load(String(boss_info.path)).instantiate()
	boss.position = Vector2(BOSS_X, FLOOR_Y - 200.0)
	arena.add_child(boss)
	await get_tree().physics_frame
	# Congelar al jefe para que el caso de prueba sea determinista: estos
	# jefes saltan solos cada 0.35-0.8s, asi que dejarlos "asentarse" N
	# frames los dejaba a una altura distinta en cada corrida. Se lo apoya
	# analiticamente sobre el piso usando su propio cuerpo fisico.
	boss.set_physics_process(false)
	boss.velocity = Vector2.ZERO
	var body_shape: CollisionShape2D = boss.get_node_or_null("CollisionShape2D")
	if body_shape != null and body_shape.shape is RectangleShape2D:
		boss.global_position.y = FLOOR_Y - (body_shape.position.y + body_shape.shape.size.y * 0.5)
	if pose == "salto":
		var sprite: Sprite2D = boss.get_node_or_null("Sprite2D")
		if sprite != null and boss.get("jump_texture") != null:
			sprite.texture = boss.jump_texture
		boss.global_position.y -= 120.0
	for i in range(4):
		await get_tree().physics_frame
	return [arena, boss]

func _hurtbox_rect(boss: Node2D) -> Rect2:
	var hurtbox: Area2D = boss.get_node_or_null("HurtBox")
	if hurtbox == null:
		return Rect2()
	for child in hurtbox.get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			var size: Vector2 = child.shape.size
			return Rect2(child.global_position - size * 0.5, size)
	return Rect2()

func _measure_zones(boss_info: Dictionary, pose: String) -> Dictionary:
	var pair := await _spawn_boss(boss_info, pose)
	var arena: Node2D = pair[0]
	var boss: Node2D = pair[1]
	var rect := _hurtbox_rect(boss)
	var result := {}
	if rect.size.y > 0.0:
		result = {
			"top": rect.position.y,
			"bottom": rect.position.y + rect.size.y,
			"cabeza": rect.position.y + rect.size.y * 0.12,
			"torso": rect.position.y + rect.size.y * 0.5,
			"parte baja": rect.position.y + rect.size.y * 0.88,
		}
	arena.queue_free()
	await get_tree().process_frame
	return result

func _try_melee(boss_info: Dictionary, pose: String, target_y: float) -> bool:
	var pair := await _spawn_boss(boss_info, pose)
	var arena: Node2D = pair[0]
	var boss: Node2D = pair[1]
	var before: int = boss.health
	var luke: Luke = LUKE_SCENE.instantiate()
	# gravedad 0 para poder posicionarlo a la altura exacta del golpe sin
	# inventarle plataformas; el resto del ataque es el codigo real.
	luke.gravity = 0.0
	# El hitbox del golpe esta 58px delante del centro de Luke.
	luke.position = Vector2(BOSS_X - 58.0 - 20.0, target_y)
	arena.add_child(luke)
	luke.velocity = Vector2.ZERO
	luke.facing_direction = 1
	Input.action_press("attack")
	await get_tree().physics_frame
	Input.action_release("attack")
	for i in range(8):
		await get_tree().physics_frame
	var after: int = boss.health if is_instance_valid(boss) else -1
	arena.queue_free()
	await get_tree().process_frame
	return after < before

func _try_bone(boss_info: Dictionary, pose: String, target_y: float) -> bool:
	var pair := await _spawn_boss(boss_info, pose)
	var arena: Node2D = pair[0]
	var boss: Node2D = pair[1]
	var before: int = boss.health
	var bone := BONE_SCENE.instantiate()
	arena.add_child(bone)
	bone.launch(Vector2(BOSS_X - 320.0, target_y), 1.0, null)
	for i in range(50):
		await get_tree().physics_frame
		if is_instance_valid(boss) and boss.health < before:
			break
	var after: int = boss.health if is_instance_valid(boss) else -1
	arena.queue_free()
	await get_tree().process_frame
	return after < before

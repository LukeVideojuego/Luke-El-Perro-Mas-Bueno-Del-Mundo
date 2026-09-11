extends Node2D

## Punto 13: en el nivel de mar (world_4_level_2) las aves se reemplazan por
## anzuelos. Verifica: (1) el spawner larga un anzuelo, (2) cae en línea
## recta a la misma velocidad que la caca de las aves (bird_poop.gd
## fall_speed), (3) tiene una tanza visible que lo conecta hacia arriba,
## (4) daña a Luke al tocarlo y desaparece, (5) si no toca a Luke,
## desaparece igual al tocar el piso.

const SPAWNER := preload("res://scenes/objects/fishhook_spawner.tscn")
const HOOK := preload("res://scenes/objects/fishhook.tscn")
const BIRD_POOP := preload("res://scenes/objects/bird_poop.tscn")
const LUKE_SCENE := preload("res://scenes/player/player.tscn")

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _check_speed_matches() -> void:
	var hook = HOOK.instantiate()
	var poop = BIRD_POOP.instantiate()
	_check(is_equal_approx(hook.fall_speed, poop.fall_speed), "el anzuelo cae a la misma velocidad que la caca de las aves (%s vs %s)" % [hook.fall_speed, poop.fall_speed])
	hook.free()
	poop.free()

func _make_floor(parent: Node2D, y: float) -> void:
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(400, 40)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(0, y)
	parent.add_child(floor_body)

var arena: Node2D
var spawner: Node
var frame := 0
var phase := 0
var hook_seen: Node = null
var luke: Luke
var got_damaged := false

func _start_spawn_and_contact_test() -> void:
	arena = Node2D.new()
	add_child(arena)
	_make_floor(arena, 600.0)
	spawner = SPAWNER.instantiate()
	spawner.initial_delay = 0.05
	spawner.spawn_interval = 100.0
	spawner.position = Vector2(0, 0)
	arena.add_child(spawner)
	luke = LUKE_SCENE.instantiate()
	luke.position = Vector2(2000, 2000)
	arena.add_child(luke)
	hook_seen = null
	frame = 0
	phase = 1

func _start_floor_despawn_test() -> void:
	arena.queue_free()
	arena = Node2D.new()
	add_child(arena)
	_make_floor(arena, 400.0)
	var hook: Node = HOOK.instantiate()
	hook.position = Vector2(0, 0)
	arena.add_child(hook)
	hook_seen = hook
	frame = 0
	phase = 2

func _ready() -> void:
	_check_speed_matches()
	_start_spawn_and_contact_test()

func _physics_process(_delta: float) -> void:
	frame += 1
	match phase:
		1:
			if hook_seen == null:
				for child in arena.get_children():
					if child is FishHook:
						hook_seen = child
			if frame == 10:
				_check(hook_seen != null, "el spawner larga un anzuelo")
			if hook_seen != null and is_instance_valid(hook_seen) and frame == 15:
				var line: Line2D = hook_seen.get_node("Line2D")
				_check(line.points[1].y < -10.0, "la tanza queda visible conectando hacia arriba (punto=%s)" % line.points[1])
			if hook_seen != null and is_instance_valid(hook_seen) and frame == 40:
				luke.global_position = hook_seen.global_position
				luke.velocity = Vector2.ZERO
				got_damaged = false
				luke.damaged.connect(func(): got_damaged = true)
			if frame == 46:
				_check(got_damaged, "el anzuelo daña a Luke al tocarlo")
				_check(not is_instance_valid(hook_seen), "el anzuelo desaparece al tocar a Luke")
				_start_floor_despawn_test()
		2:
			if frame >= 300:
				_check(not is_instance_valid(hook_seen), "el anzuelo desaparece al tocar el piso (sin tocar a Luke)")
				print("RESULTADO: ", fail_count, " fallos")
				get_tree().quit()

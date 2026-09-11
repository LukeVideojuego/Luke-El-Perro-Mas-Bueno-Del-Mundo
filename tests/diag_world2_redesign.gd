extends Node2D

## Verifica el punto 10 del bloque de correcciones: los 3 niveles de
## "Corazones de Oro" (Mundo 2) cargan sin errores tras la redistribución de
## villanos/pinches, y el nuevo sensor de daño por caída (FallDamageFloor)
## efectivamente le quita una vida a Luke si cae desde una plataforma aérea
## al piso, pero NO si simplemente salta y vuelve a caer en el mismo piso.
## La fase de comportamiento usa una arena sintética (piso + una plataforma,
## sin enemigos) para no depender de dónde cayeron los villanos nuevos, y
## corre sobre ticks reales de física para que move_and_slide()/gravedad/
## is_on_floor() funcionen de verdad.

const LEVELS := [
	"res://scenes/levels/world_2_level_1.tscn",
	"res://scenes/levels/world_2_level_2.tscn",
	"res://scenes/levels/world_2_level_3.tscn",
]
const FALL_ZONE := preload("res://scenes/objects/fall_damage_floor.tscn")
const LUKE_SCENE := preload("res://scenes/player/player.tscn")

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _check_counts() -> void:
	for path in LEVELS:
		var level: Node = load(path).instantiate()
		add_child(level)
		var thieves := 0
		var spikes := 0
		var fall_zones := 0
		for child in level.get_children():
			if child.name.begins_with("Thief"):
				thieves += 1
			if child.name.begins_with("SpikeVisuals"):
				spikes += 1
			if child is FallDamageFloor:
				fall_zones += 1
		print("--- ", path, " ---")
		print("thieves=", thieves, " spike_clusters=", spikes, " fall_zones=", fall_zones)
		_check(thieves >= 16, "%s: al menos 16 villanos (4x)" % path)
		_check(spikes >= 8, "%s: bastantes mas clusters de pinches" % path)
		_check(fall_zones == 1, "%s: tiene el sensor de dano por caida" % path)
		level.queue_free()

func _make_ground(arena: Node2D, y: float, x0: float, x1: float) -> void:
	var ground := StaticBody2D.new()
	ground.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(x1 - x0, 60)
	shape.shape = rect
	ground.add_child(shape)
	ground.position = Vector2((x0 + x1) / 2.0, y)
	arena.add_child(ground)
	var zone: Area2D = FALL_ZONE.instantiate()
	zone.position = Vector2((x0 + x1) / 2.0, y - 40)
	zone.scale = Vector2((x1 - x0) / 100.0, 1)
	arena.add_child(zone)

func _make_platform(arena: Node2D, x: float, y: float, width: float) -> void:
	var plat := StaticBody2D.new()
	plat.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, 50)
	shape.shape = rect
	plat.add_child(shape)
	plat.position = Vector2(x, y)
	arena.add_child(plat)

var arena: Node2D
var luke: Luke
var got_damaged := false
var frame := 0
var phase := 0

func _physics_process(_delta: float) -> void:
	match phase:
		1:
			frame += 1
			if frame == 5:
				luke.velocity.y = luke.jump_velocity
			if frame >= 150:
				_check(not got_damaged, "saltar en el mismo piso NO quita vida (fall_distance=%.1f)" % luke.last_fall_distance)
				arena.queue_free()
				_start_fall_test()
		2:
			frame += 1
			if frame >= 10 and frame <= 55:
				# Ya asentado sobre la plataforma: lo arrastramos hacia el
				# borde (en vez de pelear con la desaceleración sin input)
				# hasta que se cae, como si el jugador se acercara demasiado.
				luke.global_position.x += 6.0
			if frame >= 260:
				_check(got_damaged, "caer de una plataforma al piso SI quita una vida (fall_distance=%.1f)" % luke.last_fall_distance)
				arena.queue_free()
				print("RESULTADO: ", fail_count, " fallos")
				get_tree().quit()

func _start_jump_test() -> void:
	arena = Node2D.new()
	add_child(arena)
	_make_ground(arena, 1000.0, -2000.0, 2000.0)
	luke = LUKE_SCENE.instantiate()
	luke.position = Vector2(0.0, 950.0)
	arena.add_child(luke)
	luke.velocity = Vector2.ZERO
	got_damaged = false
	luke.damaged.connect(func(): got_damaged = true)
	frame = 0
	phase = 1

func _start_fall_test() -> void:
	arena = Node2D.new()
	add_child(arena)
	_make_ground(arena, 1000.0, -2000.0, 2000.0)
	_make_platform(arena, 0.0, 800.0, 400.0)
	luke = LUKE_SCENE.instantiate()
	# Parado sobre el borde de la plataforma, a punto de caer al piso.
	luke.position = Vector2(190.0, 750.0)
	arena.add_child(luke)
	luke.velocity = Vector2.ZERO
	got_damaged = false
	luke.damaged.connect(func(): got_damaged = true)
	frame = 0
	phase = 2

func _ready() -> void:
	_check_counts()
	_start_jump_test()

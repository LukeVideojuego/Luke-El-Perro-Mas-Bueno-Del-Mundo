extends Node2D

## Punto 9: si el jugador no hace nada en el nivel de mar, Luke cae al vacio
## sin encontrar piso. Verifica que Luke efectivamente se detiene sobre
## SeaFloor (o algun StaticBody2D) en varias posiciones X del nivel, sin
## caer indefinidamente.

const LEVEL := preload("res://scenes/levels/world_4_level_2.tscn")

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

var level: Node
var luke: Luke
var frame := 0
var last_y := 0.0
var stable_frames := 0
var start_x := 0.0

func _start(x: float) -> void:
	if level != null:
		level.queue_free()
	level = LEVEL.instantiate()
	add_child(level)
	luke = level.get_node("Luke")
	luke.global_position = Vector2(x, -200.0)
	luke.velocity = Vector2.ZERO
	start_x = x
	frame = 0
	last_y = luke.global_position.y
	stable_frames = 0

var test_xs := [400.0, 2000.0, 4000.0, 6000.0, 8500.0]
var test_index := 0

func _ready() -> void:
	_start(test_xs[0])

func _physics_process(_delta: float) -> void:
	frame += 1
	if absf(luke.global_position.y - last_y) < 0.5:
		stable_frames += 1
	else:
		stable_frames = 0
	last_y = luke.global_position.y
	if stable_frames >= 15:
		_check(luke.global_position.y < 1200.0, "Luke encuentra piso y se detiene en x=%.0f (y final=%.1f, no cae al vacio)" % [start_x, luke.global_position.y])
		test_index += 1
		if test_index >= test_xs.size():
			print("RESULTADO: ", fail_count, " fallos")
			get_tree().quit()
			return
		_start(test_xs[test_index])
	elif frame >= 600:
		_check(false, "Luke encuentra piso en x=%.0f (nunca se estabilizo, ultimo y=%.1f)" % [start_x, luke.global_position.y])
		test_index += 1
		if test_index >= test_xs.size():
			print("RESULTADO: ", fail_count, " fallos")
			get_tree().quit()
			return
		_start(test_xs[test_index])

extends Node2D

const PLATFORM := preload("res://scenes/objects/moving_platform.tscn")
const LUKE_SCENE := preload("res://scenes/player/player.tscn")
var luke: CharacterBody2D
var platform: Node
var frame := 0
var start_x := 0.0
var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	var ground := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(2000, 40)
	shape.shape = rect
	ground.add_child(shape)
	ground.position = Vector2(1000, 1000)
	add_child(ground)

	platform = PLATFORM.instantiate()
	platform.position = Vector2(500, 900)
	platform.travel = Vector2(300, 0)
	platform.speed = 100.0
	add_child(platform)

	luke = LUKE_SCENE.instantiate()
	luke.global_position = Vector2(500, 850)
	add_child(luke)
	start_x = luke.global_position.x

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 5:
		luke.velocity = Vector2.ZERO
	if frame == 120:
		_check(luke.global_position.x > start_x + 20.0, "Luke es arrastrado por la plataforma móvil (x avanzó %.1f)" % (luke.global_position.x - start_x))
		_check(luke.global_position.y < 950.0, "Luke se mantiene parado sobre la plataforma (no cae)")
		print("RESULTADO: ", fail_count, " fallos")
		get_tree().quit()

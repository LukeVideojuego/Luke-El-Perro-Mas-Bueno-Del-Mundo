extends Node2D

const LEVEL := preload("res://scenes/levels/world_1_level_2.tscn")
const BONE_PICKUP := preload("res://scenes/objects/bone_pickup.tscn")

var level: Node
var luke: CharacterBody2D
var thief: Node
var pickup: Area2D
var frame := 0
var fail_count := 0
var saw_throwing := false

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	GameState.bone_throw_unlocked = false
	level = LEVEL.instantiate()
	add_child(level)
	luke = level.get_node("Luke")
	thief = level.get_node("ThiefOne")
	pickup = BONE_PICKUP.instantiate()
	level.add_child(pickup)

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 5:
		pickup.global_position = luke.global_position
	if frame == 8:
		_check(GameState.bone_throw_unlocked, "recoger huesito desbloquea ataque a distancia")
	if frame == 10:
		luke.global_position = thief.global_position - Vector2(220, 0)
		luke.facing_direction = 1
		luke.velocity = Vector2.ZERO
	if frame == 15:
		Input.action_press("attack")
	if frame == 17:
		Input.action_release("attack")
	if frame == 22:
		Input.action_press("attack")
	if frame == 24:
		Input.action_release("attack")
	if frame > 15 and luke.is_throwing:
		saw_throwing = true
	if frame == 45:
		_check(saw_throwing, "doble tap dispara el ataque a distancia (is_throwing)")
	if frame == 60:
		_check(not is_instance_valid(thief) or thief.is_defeated, "el huesito arrojado derrota al enemigo")
	if frame == 65:
		print("RESULTADO: ", fail_count, " fallos")
		get_tree().quit()

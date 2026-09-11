extends Node2D

## Complementa diag_hug_bug.gd: confirma que un abrazo REAL (Luke moviéndose
## activamente hacia una persona) sigue contando, para no romper el
## minijuego al arreglar el bug de "abrazo pasivo" (punto 15).

const PERSON := preload("res://scenes/objects/huggable_person.tscn")
const LUKE_SCENE := preload("res://scenes/player/player.tscn")

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

var arena: Node2D
var person: HuggablePerson
var luke: Luke
var frame := 0

func _ready() -> void:
	arena = Node2D.new()
	add_child(arena)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(2000, 60)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(300, 80)
	arena.add_child(floor_body)
	person = PERSON.instantiate()
	person.position = Vector2(300, 0)
	arena.add_child(person)
	luke = LUKE_SCENE.instantiate()
	luke.position = Vector2(0, 0)
	arena.add_child(luke)

func _physics_process(_delta: float) -> void:
	frame += 1
	Input.action_press("move_right")
	if frame == 200:
		_check(person.is_hugged, "Luke moviendose activamente hacia la persona SI cuenta como abrazo")
		print("RESULTADO: ", fail_count, " fallos")
		get_tree().quit()

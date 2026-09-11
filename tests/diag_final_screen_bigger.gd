extends Node2D

## Punto 16: minijuego final más grande y difícil. Verifica: nivel 1.5x más
## ancho (3000 vs 2000), más plataformas aéreas, gente más rápida que antes,
## y que al menos algunas personas saltan de verdad entre dos alturas de
## plataforma (no solo el rebote cosmético).

const LEVEL := preload("res://scenes/levels/final_screen.tscn")
const OLD_WIDTH := 2000.0
const OLD_SPEEDS := {
	"PersonPurple": 45.0, "Diego": 95.0, "Roma": 55.0, "Lara": 80.0,
	"Izan": 60.0, "Fausto": 100.0, "Bauti": 50.0, "Mathi": 70.0,
	"Zoe": 85.0, "PersonGreen": 65.0, "PersonYellow": 40.0, "PersonPink": 75.0,
}

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

var level: Node
var bauti: HuggablePerson
var zoe: HuggablePerson
var frame := 0
var bauti_min_y := 999999.0
var bauti_max_y := -999999.0

func _ready() -> void:
	level = LEVEL.instantiate()
	add_child(level)

	var ground_shape: RectangleShape2D = level.get_node("Ground/CollisionShape2D").shape
	_check(ground_shape.size.x >= OLD_WIDTH * 1.45, "el piso es ~1.5x mas ancho (%.0f vs %.0f original)" % [ground_shape.size.x, OLD_WIDTH])

	var platform_count := 0
	for child in level.get_children():
		if child.name.begins_with("Platform"):
			platform_count += 1
	_check(platform_count >= 6, "hay bastantes mas plataformas aereas (encontradas: %d, antes 2)" % platform_count)

	var all_faster := true
	for person_name in OLD_SPEEDS:
		var person: HuggablePerson = level.get_node(person_name)
		if person.wander_speed <= OLD_SPEEDS[person_name]:
			all_faster = false
			print("  -> %s no es mas rapido: %.1f vs %.1f antes" % [person_name, person.wander_speed, OLD_SPEEDS[person_name]])
	_check(all_faster, "todas las personas son mas rapidas que antes")

	bauti = level.get_node("Bauti")
	zoe = level.get_node("Zoe")
	_check(bauti.platform_hop_enabled and zoe.platform_hop_enabled, "al menos algunas personas saltan de verdad entre plataformas")

func _physics_process(_delta: float) -> void:
	frame += 1
	bauti_min_y = minf(bauti_min_y, bauti.global_position.y)
	bauti_max_y = maxf(bauti_max_y, bauti.global_position.y)
	if frame >= 500:
		_check(bauti_max_y - bauti_min_y > 100.0, "Bauti efectivamente cambia de altura real al saltar entre plataformas (rango=%.1f)" % (bauti_max_y - bauti_min_y))
		print("RESULTADO: ", fail_count, " fallos")
		get_tree().quit()

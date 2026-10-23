extends Node2D

## F8: inventario + verificacion de ciclo de animacion al desplazarse.
## Confirma con fisica real que cada enemigo de la lista alterna de verdad
## entre su textura quieta y su textura de movimiento (tiburones, medusa
## que nada, aves, y los villanos humanos que ya tenian el ciclo).

const CASES := [
	{"scene": "res://scenes/enemies/fish_blue.tscn", "name": "Tiburon azul"},
	{"scene": "res://scenes/enemies/fish_yellow.tscn", "name": "Tiburon amarillo"},
	{"scene": "res://scenes/enemies/fish_purple.tscn", "name": "Medusa (nada, BOB_VERTICAL)"},
	{"scene": "res://scenes/enemies/bird.tscn", "name": "Ave (aleteo)"},
	{"scene": "res://scenes/enemies/thief.tscn", "name": "Ladron"},
	{"scene": "res://scenes/enemies/carterista.tscn", "name": "Carterista"},
	{"scene": "res://scenes/enemies/corrupt_politician.tscn", "name": "Politico corrupto"},
	{"scene": "res://scenes/enemies/corrupt_lackey.tscn", "name": "Ladron politico (lackey)"},
]

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	for c in CASES:
		await _check_case(c)
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _check_case(c: Dictionary) -> void:
	var enemy: EnemyBase = load(c.scene).instantiate()
	add_child(enemy)
	_check(enemy.walk_texture != null, "%s: tiene walk_texture asignada" % c.name)
	if enemy.walk_texture == null:
		enemy.queue_free()
		await get_tree().process_frame
		return
	var sprite: Sprite2D = enemy.get_node("Sprite2D")
	var seen_idle := false
	var seen_walk := false
	for i in range(120):  # 2s
		await get_tree().physics_frame
		if sprite.texture == enemy.walk_texture:
			seen_walk = true
		else:
			seen_idle = true
	_check(seen_walk, "%s: en algun momento muestra la pose de movimiento mientras se desplaza" % c.name)
	_check(seen_idle, "%s: tambien pasa por la pose quieta (alterna, no queda trabado en una sola)" % c.name)
	enemy.queue_free()
	await get_tree().process_frame

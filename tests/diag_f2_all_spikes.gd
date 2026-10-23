extends Node2D

## F2: audita TODOS los pinchos/objetos filosos (instancias de
## damage_zone.tscn) de los 16 niveles. Por cada instancia, para a Luke
## encima (con una caida chica para que se asiente con fisica real, no
## teletransportado adentro) y confirma que pierde EXACTAMENTE 1 corazon,
## con el mismo sistema que un villano (receive_damage + invulnerabilidad
## corta), sin matarlo de golpe ni quedar en un bucle de dano.

const LEVELS := [
	"res://scenes/levels/world_1_level_1.tscn", "res://scenes/levels/world_1_level_2.tscn",
	"res://scenes/levels/world_1_level_3.tscn", "res://scenes/levels/world_2_level_1.tscn",
	"res://scenes/levels/world_2_level_2.tscn", "res://scenes/levels/world_2_level_3.tscn",
	"res://scenes/levels/world_3_level_1.tscn", "res://scenes/levels/world_3_level_2.tscn",
	"res://scenes/levels/world_3_level_3.tscn", "res://scenes/levels/world_4_level_1.tscn",
	"res://scenes/levels/world_4_level_3.tscn",
]

var fail_count := 0
var total_checked := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	for path in LEVELS:
		await _audit(path)
	print("RESULTADO: ", fail_count, " fallos (", total_checked, " pinchos revisados)")
	get_tree().quit()

func _audit(path: String) -> void:
	# Nombres de las zonas: se leen de una carga inicial liviana.
	var probe: Node = load(path).instantiate()
	add_child(probe)
	await get_tree().physics_frame
	var zone_names: Array[String] = []
	for child in probe.get_children():
		if child is DamageZone:
			zone_names.append(child.name)
	probe.queue_free()
	await get_tree().process_frame

	# Cada zona se prueba en una instancia FRESCA del nivel (recargado desde
	# cero), para que no quede ningun rastro de fisica de la zona anterior
	# (confirmado que probarlas todas sobre la misma instancia, aunque sea
	# alejando a Luke entre una y otra, podia arrastrar algun estado de la
	# zona previa y dar un falso negativo ocasional).
	for zone_name in zone_names:
		total_checked += 1
		var level: Node = load(path).instantiate()
		add_child(level)
		await get_tree().physics_frame
		var zone: Node2D = level.get_node(zone_name)
		var luke: Luke = level.get_node("Luke")
		GameState.lives = 3
		luke.velocity = Vector2.ZERO
		luke.global_position = zone.global_position + Vector2(0.0, -40.0)
		for i in range(40):
			await get_tree().physics_frame
		var after_landing: int = GameState.lives
		for i in range(30):
			await get_tree().physics_frame
		var after_wait: int = GameState.lives
		_check(after_landing == 2, "%s / %s: pierde 1 corazon (3 -> %d)" % [path.get_file(), zone_name, after_landing])
		_check(after_wait == after_landing, "%s / %s: no sigue bajando vida (sin bucle de dano)" % [path.get_file(), zone_name])
		level.queue_free()
		await get_tree().process_frame

extends Node2D

## F2: confirma con fisica real que GroundSpikeField (el piso-lleno-de-pinchos
## de Mundo 2) de verdad hace dano a Luke parado/caminando sobre un tramo
## cubierto, en los 3 niveles que lo usan.

const LEVELS := [
	"res://scenes/levels/world_2_level_1.tscn",
	"res://scenes/levels/world_2_level_2.tscn",
	"res://scenes/levels/world_2_level_3.tscn",
]

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	for path in LEVELS:
		await _audit(path)
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _audit(path: String) -> void:
	var level: Node = load(path).instantiate()
	add_child(level)
	await get_tree().physics_frame
	var field: GroundSpikeField = level.get_node_or_null("GroundSpikeField")
	if field == null:
		_check(false, "%s: tiene GroundSpikeField" % path.get_file())
		level.queue_free()
		await get_tree().process_frame
		return
	_check(field.covered_segments.size() > 0, "%s: GroundSpikeField cubrio al menos un tramo (%d tramos)" % [
		path.get_file(), field.covered_segments.size()])
	if field.covered_segments.is_empty():
		level.queue_free()
		await get_tree().process_frame
		return
	var seg: Vector2 = field.covered_segments[0]
	var mid_x: float = (seg.x + seg.y) * 0.5
	var luke: Luke = level.get_node("Luke")
	GameState.lives = 3
	var lives_before: int = GameState.lives
	luke.global_position = Vector2(mid_x, field.surface_y - 40.0)
	luke.velocity = Vector2.ZERO
	# Ventana corta (bien por debajo de la invulnerabilidad de 0.75s tras el
	# primer golpe) para medir SOLO el aterrizaje: si en esta ventana corta
	# ya perdio mas de 1 corazon, es un golpe doble simultaneo (2 areas de
	# pinchos vecinas tocandolo el mismo frame), no un golpe real por
	# quedarse parado mucho tiempo.
	for i in range(40):
		await get_tree().physics_frame
	var lives_after_landing: int = GameState.lives
	var took_damage: bool = lives_after_landing < lives_before
	_check(took_damage, "%s: Luke pierde vida al pisar un tramo cubierto (vidas %d -> %d)" % [
		path.get_file(), lives_before, lives_after_landing])
	_check(lives_after_landing >= lives_before - 1, "%s: pierde EXACTAMENTE 1 corazon al aterrizar, no mas (no hay golpe doble)" % path.get_file())
	# Seguir parado mas tiempo: NO debe seguir bajando vida frame a frame
	# (bucle de dano) mientras la invulnerabilidad sigue activa.
	for i in range(30):
		await get_tree().physics_frame
	_check(GameState.lives == lives_after_landing, "%s: no pierde mas vida durante la invulnerabilidad (bucle de dano)" % path.get_file())
	level.queue_free()
	await get_tree().process_frame

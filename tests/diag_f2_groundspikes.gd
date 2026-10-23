extends Node2D

## F2 (histórico) + A3: confirma con fisica real que los pinchos de Mundo 2
## siguen haciendo daño a Luke.
##
## A3 suavizo el pico de dificultad de Mundo 2: Nivel 1 y Nivel 2 ya NO
## tienen todo el piso cubierto (GroundSpikeField.extra_safe_zones ahora
## cubre el nivel entero a proposito, asi que covered_segments queda vacio
## -- el peligro de piso vuelve a ser solo los tramos armados a mano,
## bien separados). Nivel 3 queda igual que antes (el usuario pidio
## explicitamente no tocarlo), asi que ahi se sigue probando el tramo
## procedural como siempre.

const LEVELS_UNCHANGED := [
	"res://scenes/levels/world_2_level_3.tscn",
]
## A3: nivel -> nodo de pincho a mano a probar (el conteo total de tramos de
## cada nivel ya lo audita diag_f2_all_spikes.gd por separado).
const LEVELS_MANUAL := {
	"res://scenes/levels/world_2_level_1.tscn": "SpikeHazardOne",
	"res://scenes/levels/world_2_level_2.tscn": "SpikeHazardOne",
}

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	for path in LEVELS_UNCHANGED:
		await _audit_procedural(path)
	for path in LEVELS_MANUAL:
		await _audit_manual(path, String(LEVELS_MANUAL[path]))
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _audit_procedural(path: String) -> void:
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
	await _land_and_check(level, Vector2(mid_x, field.surface_y - 40.0), path.get_file())
	level.queue_free()
	await get_tree().process_frame

## A3: en Nivel 1 y 2, GroundSpikeField ya no cubre nada por diseño (confirma
## el "sin cubrir todo"), y los pinchos reales son los tramos armados a mano
## -- se verifica parandose exactamente en uno de ellos.
func _audit_manual(path: String, hazard_name: String) -> void:
	var level: Node = load(path).instantiate()
	add_child(level)
	await get_tree().physics_frame
	var field: GroundSpikeField = level.get_node_or_null("GroundSpikeField")
	_check(field != null and field.covered_segments.is_empty(),
		"%s: GroundSpikeField NO cubre nada por diseño (A3, suaviza el pico) -- tiene %d tramos" % [
			path.get_file(), field.covered_segments.size() if field != null else -1])
	var hazard: Area2D = level.get_node_or_null(hazard_name)
	_check(hazard != null, "%s: el tramo a mano '%s' existe en la escena" % [path.get_file(), hazard_name])
	if hazard == null:
		level.queue_free()
		await get_tree().process_frame
		return
	await _land_and_check(level, hazard.global_position, path.get_file())
	level.queue_free()
	await get_tree().process_frame

func _land_and_check(level: Node, spot: Vector2, label: String) -> void:
	var luke: Luke = level.get_node("Luke")
	GameState.lives = 3
	var lives_before: int = GameState.lives
	luke.global_position = spot + Vector2(0.0, -40.0)
	luke.velocity = Vector2.ZERO
	for i in range(40):
		await get_tree().physics_frame
	var lives_after_landing: int = GameState.lives
	var took_damage: bool = lives_after_landing < lives_before
	_check(took_damage, "%s: Luke pierde vida al pisar un tramo cubierto (vidas %d -> %d)" % [
		label, lives_before, lives_after_landing])
	_check(lives_after_landing >= lives_before - 1, "%s: pierde EXACTAMENTE 1 corazon al aterrizar, no mas (no hay golpe doble)" % label)
	for i in range(30):
		await get_tree().physics_frame
	_check(GameState.lives == lives_after_landing, "%s: no pierde mas vida durante la invulnerabilidad (bucle de dano)" % label)

extends Node2D

## Verifica, con física real, que ningún jefe se quede "fuera de alcance"
## si Luke se para quieto lejos de él (el exploit reportado: pararse en el
## borde inicial y tirar huesitos a distancia sin que el jefe llegue nunca),
## y que efectivamente sube a las plataformas elevadas de su arena (prueba
## real de verticalidad), no solo que se queda caminando a nivel del piso.

const LEVELS := [
	{"scene": "res://scenes/levels/world_1_boss.tscn", "boss": "ThiefBoss"},
	{"scene": "res://scenes/levels/world_2_boss.tscn", "boss": "WitchBoss"},
	{"scene": "res://scenes/levels/world_3_boss.tscn", "boss": "CorruptBoss"},
	{"scene": "res://scenes/levels/world_4_boss.tscn", "boss": "SerpentBoss"},
]

const TEST_FRAMES := 600 # 10s

var idx := 0
var level: Node
var boss: Node
var luke: Node
var frame := 0
var min_dist := INF
var min_y := INF
var max_y := -INF
var start_y := 0.0
var any_fail := false

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	_start_level()

func _start_level() -> void:
	frame = 0
	min_dist = INF
	min_y = INF
	max_y = -INF
	var data: Dictionary = LEVELS[idx]
	var scene: PackedScene = load(data["scene"])
	level = scene.instantiate()
	add_child(level)
	boss = level.get_node(data["boss"])
	luke = level.get_node("Luke")
	start_y = boss.global_position.y
	# Luke se queda parado quieto lejos del jefe (el exploit reportado).
	luke.set_physics_process(false)

func _physics_process(_delta: float) -> void:
	if level == null:
		return
	frame += 1
	var d: float = boss.global_position.distance_to(luke.global_position)
	min_dist = minf(min_dist, d)
	min_y = minf(min_y, boss.global_position.y)
	max_y = maxf(max_y, boss.global_position.y)
	if frame >= TEST_FRAMES:
		_finish_level()

func _finish_level() -> void:
	var data: Dictionary = LEVELS[idx]
	var chased := min_dist < 250.0
	# F9: la Serpiente ahora arranca parada en la plataforma MAS ALTA de su
	# arena a proposito (pedido explicito), asi que para ella "usar la
	# verticalidad" ya no puede medirse como "subio mas que su punto de
	# partida" (no hay nada mas alto a donde subir) -- se mide al reves,
	# que BAJE de forma real desde ahi. Para los otros 3 jefes (que siguen
	# arrancando cerca del piso) el criterio original no cambia.
	var vertical: bool
	var climbed: float
	if data["boss"] == "SerpentBoss":
		climbed = max_y - start_y
		vertical = climbed > 80.0
	else:
		climbed = start_y - min_y
		vertical = climbed > 80.0
	if not chased:
		any_fail = true
		print("FAIL: ", data["boss"], " nunca persigue a Luke quieto (dist minima=", min_dist, "px tras ", TEST_FRAMES/60.0, "s)")
	else:
		print("PASS: ", data["boss"], " persigue activamente a Luke quieto (dist minima=", min_dist, "px)")
	var verb: String = "baja" if data["boss"] == "SerpentBoss" else "sube"
	if not vertical:
		any_fail = true
		print("FAIL: ", data["boss"], " no usa la verticalidad de la arena (", verb, " solo ", climbed, "px)")
	else:
		print("PASS: ", data["boss"], " usa la verticalidad de la arena (", verb, " ", climbed, "px desde su Y inicial)")
	level.queue_free()
	level = null
	idx += 1
	if idx >= LEVELS.size():
		print("RESULTADO: ", ("hay fallos" if any_fail else "0 fallos"))
		get_tree().quit()
	else:
		call_deferred("_start_level")

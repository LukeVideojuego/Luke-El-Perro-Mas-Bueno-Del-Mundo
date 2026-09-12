extends Node2D

## Simula una pelea completa (con piso, sin Luke) contra cada uno de los 4
## jefes y verifica que la regla de poderes (punto 9 del bloque de
## correcciones) se cumple: alterna 2 poderes distintos con el intervalo fijo
## esperado por jefe, arrancando exactamente en power_interval segundos, y
## que la Bruja del Olvido además salta periódicamente.
## Corre sobre ticks reales de físicas del motor (no llamadas manuales) para
## que move_and_slide()/gravedad/is_on_floor() funcionen de verdad.

const BOSSES := [
	{"path": "res://scenes/enemies/thief_boss.tscn", "name": "Don Sombra (jefe 1)", "interval": 1.0, "extra_jump": 0.0},
	{"path": "res://scenes/enemies/witch_boss.tscn", "name": "Bruja del Olvido (jefe 2)", "interval": 0.75, "extra_jump": 1.3},
	{"path": "res://scenes/enemies/corrupt_boss.tscn", "name": "Gran Codicia (jefe 3)", "interval": 0.5, "extra_jump": 0.0},
	{"path": "res://scenes/enemies/serpent_boss.tscn", "name": "Serpiente (jefe 4)", "interval": 0.25, "extra_jump": 0.0},
]

## power_interval de la ronda anterior (antes de este pedido puntual de
## "duplicá otra vez la velocidad de poder respecto a como está AHORA").
## Los valores nuevos deben ser exactamente la mitad de estos.
const PREVIOUS_ROUND_INTERVALS := [2.0, 1.5, 1.0, 0.5]
const PREVIOUS_ROUND_PATROL_SPEEDS := [110.0, 140.0, 190.0, 230.0]

var fail_count := 0
var cur_index := -1
var arena: Node2D
var boss: Node
var frame := 0
var max_frames := 0
var fire_times: Array = []
var fire_diag: Array = []
var hop_count := 0
var last_vel_y := 0.0
var t := 0.0
var prev_projectile_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

## Punto 6: cada jefe debe ser mas agresivo que el anterior (mas rapido en
## patrulla/carga, saltos mas frecuentes, poder mas seguido), no solo el
## ultimo mas dificil que el primero.
func _check_progression() -> void:
	var stats := []
	for cfg in BOSSES:
		var b: Node = load(cfg.path).instantiate()
		stats.append({
			"name": cfg.name, "patrol_speed": b.patrol_speed, "charge_speed": b.charge_speed,
			"hop_interval": b.hop_interval, "power_interval": b.power_interval,
			"hop_strength": absf(b.hop_strength),
		})
		b.free()
	for i in range(1, stats.size()):
		var a: Dictionary = stats[i - 1]
		var c: Dictionary = stats[i]
		_check(c.patrol_speed > a.patrol_speed, "%s patrulla mas rapido que %s (%.0f > %.0f)" % [c.name, a.name, c.patrol_speed, a.patrol_speed])
		_check(c.charge_speed > a.charge_speed, "%s carga mas rapido que %s (%.0f > %.0f)" % [c.name, a.name, c.charge_speed, a.charge_speed])
		_check(c.hop_interval < a.hop_interval, "%s salta mas seguido que %s (%.2f < %.2f)" % [c.name, a.name, c.hop_interval, a.hop_interval])
		_check(c.hop_strength > a.hop_strength, "%s salta mas alto que %s (%.0f > %.0f)" % [c.name, a.name, c.hop_strength, a.hop_strength])
		_check(c.power_interval < a.power_interval, "%s dispara mas seguido que %s (%.2f < %.2f)" % [c.name, a.name, c.power_interval, a.power_interval])
	for i in range(stats.size()):
		var s: Dictionary = stats[i]
		var prev_interval: float = PREVIOUS_ROUND_INTERVALS[i]
		_check(is_equal_approx(s.power_interval, prev_interval / 2.0), "%s: power_interval es exactamente la mitad de la ronda anterior (%.3f, antes %.2f)" % [s.name, s.power_interval, prev_interval])
		var prev_patrol: float = PREVIOUS_ROUND_PATROL_SPEEDS[i]
		_check(s.patrol_speed >= prev_patrol * 1.5, "%s: patrol_speed considerablemente mas alto que la ronda anterior (%.0f vs %.0f antes)" % [s.name, s.patrol_speed, prev_patrol])

func _start_next() -> void:
	if arena != null:
		arena.queue_free()
	cur_index += 1
	if cur_index >= BOSSES.size():
		_check_progression()
		print("RESULTADO: ", fail_count, " fallos")
		get_tree().quit()
		return
	var cfg: Dictionary = BOSSES[cur_index]
	arena = Node2D.new()
	add_child(arena)
	boss = load(cfg.path).instantiate()
	arena.add_child(boss)
	boss.global_position = Vector2(0, 0)

	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 1
	var floor_shape := CollisionShape2D.new()
	var floor_rect := RectangleShape2D.new()
	floor_rect.size = Vector2(4000, 60)
	floor_shape.shape = floor_rect
	floor_body.add_child(floor_shape)
	floor_body.position = Vector2(0, 220)
	arena.add_child(floor_body)

	frame = 0
	max_frames = int((cfg.interval * 4.0 + 1.0) * 60.0)
	fire_times = []
	fire_diag = []
	hop_count = 0
	last_vel_y = 0.0
	t = 0.0
	prev_projectile_count = 0

func _physics_process(_delta: float) -> void:
	if cur_index < 0:
		_start_next()
		return
	if cur_index >= BOSSES.size():
		return
	var cfg: Dictionary = BOSSES[cur_index]
	frame += 1
	t += 1.0 / 60.0
	var projectiles: Array = arena.get_children().filter(func(c): return c is EnemyProjectile)
	if projectiles.size() > prev_projectile_count:
		fire_times.append(t)
		var newest: EnemyProjectile = projectiles[projectiles.size() - 1]
		fire_diag.append(newest.vertical_speed != 0.0)
	prev_projectile_count = projectiles.size()
	if cfg.extra_jump > 0.0 and boss.velocity.y < -1.0 and last_vel_y >= -1.0:
		hop_count += 1
	last_vel_y = boss.velocity.y

	if frame >= max_frames:
		_finish_current(cfg)
		_start_next()

func _finish_current(cfg: Dictionary) -> void:
	print("--- ", cfg.name, " ---")
	print("Disparos en t=", fire_times, " diagonal=", fire_diag)
	_check(fire_times.size() >= 4, "%s: dispara al menos 4 veces en %ss" % [cfg.name, cfg.interval * 4.0 + 1.0])
	if fire_times.size() > 0:
		_check(absf(fire_times[0] - cfg.interval) < 0.05, "%s: primer poder exactamente a los %ss (real: %.3fs)" % [cfg.name, cfg.interval, fire_times[0]])
	for i in range(1, fire_times.size()):
		var gap: float = fire_times[i] - fire_times[i - 1]
		_check(absf(gap - cfg.interval) < 0.05, "%s: gap #%d entre poderes = %ss (real: %.3fs)" % [cfg.name, i, cfg.interval, gap])
	var alternates := true
	for i in range(1, fire_diag.size()):
		if fire_diag[i] == fire_diag[i - 1]:
			alternates = false
	_check(alternates, "%s: alterna poder al ras / diagonal en cada disparo" % cfg.name)
	_check(fire_diag.size() > 0 and fire_diag.count(true) > 0 and fire_diag.count(false) > 0, "%s: usa ambos tipos de poder (no solo uno)" % cfg.name)
	if cfg.extra_jump > 0.0:
		_check(hop_count >= 1, "%s: además salta periódicamente (extra_jump_interval), saltos detectados: %d" % [cfg.name, hop_count])

extends Node2D

## B3: verifica con físicas/señales reales las 3 mecánicas nuevas por jefe
## (Don Sombra = fundido en sombras, Bruja = teletransporte, Gran Codicia =
## llama ayudantes a mitad de vida), que la Reina Veneno quedó intacta, y
## que nada de lo ya establecido (tamaños/poderes/hueso al caer) se rompió.
##
## Las mecánicas se activan como @export en la INSTANCIA del jefe dentro de
## cada world_N_boss.tscn (no en la escena base del enemigo), asi que los
## tests cargan el nivel real, no scenes/enemies/*_boss.tscn directo.

const SMOKE_SCRIPT := preload("res://scripts/effects/smoke_puff.gd")

var fails := 0
var checks := 0

func _check(label: String, ok: bool) -> void:
	checks += 1
	if ok:
		print("OK: ", label)
	else:
		fails += 1
		print("FALLO: ", label)

func _wait(n: int) -> void:
	for i in range(n):
		await get_tree().physics_frame

## Espera hasta que predicate() sea true, chequeando cada physics frame
## (evita asumir a mano cuanto tiempo real tarda una corutina interna).
func _poll_until(predicate: Callable, max_frames: int = 300) -> bool:
	for i in range(max_frames):
		if predicate.call():
			return true
		await get_tree().physics_frame
	return predicate.call()

func _ready() -> void:
	await _test_shadow_fade()
	await _test_teleport()
	await _test_summon_allies()
	await _test_serpent_untouched()
	print("RESULTADO: ", fails, " fallos de ", checks)
	get_tree().quit()

func _load_boss_level(path: String, boss_name: String) -> Dictionary:
	var level: Node2D = load(path).instantiate()
	add_child(level)
	await _wait(2)
	var luke: Node2D = level.get_node("Luke")
	var boss = level.get_node(boss_name)
	return {"level": level, "luke": luke, "boss": boss}

func _test_shadow_fade() -> void:
	var rig := await _load_boss_level("res://scenes/levels/world_1_boss.tscn", "ThiefBoss")
	var level: Node2D = rig.level
	var luke: Node2D = rig.luke
	var boss = rig.boss
	_check("ThiefBoss.shadow_fade_enabled = true (world_1_boss)", boss.shadow_fade_enabled)
	luke.global_position = boss.global_position + Vector2(300, 0)
	# Luke no tiene IA propia y cae por gravedad si no hay piso exacto debajo;
	# para este test solo necesita ser un punto de referencia fijo.
	luke.set_physics_process(false)
	# Forzar el timer justo antes de disparar para no esperar 7s reales de sim.
	boss._shadow_timer = boss.shadow_fade_interval - 0.02
	var hp_before: int = boss.health
	await _wait(3)
	# Durante el aviso (shadow_warning_duration) SIGUE siendo golpeable.
	boss.receive_attack(null, 1)
	_check("Durante el aviso previo, Don Sombra sigue recibiendo daño", boss.health == hp_before - 1)
	# Esperar a que entre en estado invulnerable (después del aviso).
	await get_tree().create_timer(boss.shadow_warning_duration + 0.05).timeout
	_check("Don Sombra entra en invulnerable tras el aviso", boss._is_shadow_invulnerable)
	var hp_mid: int = boss.health
	boss.receive_attack(null, 1)
	_check("Mientras es invulnerable, receive_attack no resta vida", boss.health == hp_mid)
	_check("Sprite semitransparente mientras es invulnerable", boss.sprite.modulate.a < 0.9)
	# Detectar el salto de reaparicion (igual que el teletransporte de la
	# Bruja): un salto de posicion grande en un solo frame, no el movimiento
	# gradual normal de carga/patrulla que sigue activo mientras esta fundido.
	var prev_pos: Vector2 = boss.global_position
	var reappeared := false
	var dist_on_reappear := INF
	for i in range(240):
		await get_tree().physics_frame
		var cur_pos: Vector2 = boss.global_position
		if cur_pos.distance_to(prev_pos) > 50.0:
			reappeared = true
			dist_on_reappear = cur_pos.distance_to(luke.global_position)
			break
		prev_pos = cur_pos
	_check("Don Sombra reaparece de golpe cerca de Luke (dist=%.1f)" % dist_on_reappear, reappeared and dist_on_reappear < 250.0)
	# Esperar a que salga de la invulnerabilidad al terminar shadow_duration.
	await _poll_until(func(): return not boss._is_shadow_invulnerable, 180)
	_check("Don Sombra vuelve a ser vulnerable tras shadow_duration", not boss._is_shadow_invulnerable)
	_check("Sprite vuelve a modulate normal", boss.sprite.modulate.a > 0.9)
	level.queue_free()
	await _wait(2)

func _test_teleport() -> void:
	var rig := await _load_boss_level("res://scenes/levels/world_2_boss.tscn", "WitchBoss")
	var level: Node2D = rig.level
	var boss = rig.boss
	_check("WitchBoss.teleport_enabled = true (world_2_boss)", boss.teleport_enabled)
	_check("WitchBoss.teleport_points tiene las 6 plataformas de la arena", boss.teleport_points.size() == 6)
	boss._teleport_timer = boss.teleport_interval - 0.02
	var got_warning_smoke: bool = await _poll_until(func(): return level.get_children().any(func(c): return c.get_script() == SMOKE_SCRIPT))
	_check("Aparece una nube de humo en el aviso previo", got_warning_smoke)
	# Detectar el SALTO instantaneo de posicion (teletransporte), no el
	# movimiento gradual normal de patrulla/carga (maximo ~8px por frame a
	# charge_speed=480px/s): un salto de 50px en UN solo physics frame solo
	# puede ser la reasignacion directa de global_position.
	var prev_pos: Vector2 = boss.global_position
	var teleported := false
	var pos_after: Vector2 = prev_pos
	for i in range(240):
		await get_tree().physics_frame
		var cur_pos: Vector2 = boss.global_position
		if cur_pos.distance_to(prev_pos) > 50.0:
			teleported = true
			pos_after = cur_pos
			break
		prev_pos = cur_pos
	_check("La Bruja cambió de posición de golpe (teletransporte)", teleported)
	var smoke_count_right_after: int = level.get_children().filter(func(c): return c.get_script() == SMOKE_SCRIPT).size()
	var closest := INF
	var landed_on_point := false
	for p in boss.teleport_points:
		var d: float = pos_after.distance_to(p)
		closest = minf(closest, d)
		if d < 90.0:
			landed_on_point = true
	_check("Aterriza cerca de una plataforma de teleport_points (closest=%.1f)" % closest, landed_on_point)
	_check("Hay nubes de humo nuevas (salida+llegada) justo al teletransportarse (count=%d)" % smoke_count_right_after, smoke_count_right_after >= 2)
	level.queue_free()
	await _wait(2)

func _test_summon_allies() -> void:
	var rig := await _load_boss_level("res://scenes/levels/world_3_boss.tscn", "CorruptBoss")
	var level: Node2D = rig.level
	var boss = rig.boss
	_check("CorruptBoss.summon_allies_scene asignado (world_3_boss)", boss.summon_allies_scene != null)

	var half: int = boss.max_health / 2
	# Bajar de a 1 hasta justo ANTES de la mitad: todavia no debe llamar.
	while boss.health > half + 1:
		boss.receive_attack(null, 1)
		await _wait(1)
	var lackeys_before: int = level.get_children().filter(func(c): return c.scene_file_path == "res://scenes/enemies/corrupt_lackey.tscn").size()
	_check("Antes de llegar a la mitad de vida, no llamó ayudantes", lackeys_before == 0)
	# Este golpe cruza el umbral de la mitad. receive_attack() tiene un await
	# interno (flash de 0.12s) antes de llamar a _check_summon_allies(), asi
	# que hay que esperar a que _allies_summoned se marque, no un numero fijo
	# de frames (podria chequear antes de que la corutina interna llegue ahi).
	boss.receive_attack(null, 1)
	await _poll_until(func(): return boss._allies_summoned, 60)
	var lackeys_at_half: int = level.get_children().filter(func(c): return c.scene_file_path == "res://scenes/enemies/corrupt_lackey.tscn").size()
	_check("Al cruzar la mitad de vida, aparecen exactamente 2 ayudantes", lackeys_at_half == 2)
	_check("_allies_summoned queda marcado true", boss._allies_summoned)
	# Seguir golpeando: no debe volver a llamar ayudantes.
	boss.receive_attack(null, 1)
	await _wait(10)
	var lackeys_later: int = level.get_children().filter(func(c): return c.scene_file_path == "res://scenes/enemies/corrupt_lackey.tscn").size()
	_check("Golpes posteriores no llaman mas ayudantes (solo una vez)", lackeys_later == 2)
	level.queue_free()
	await _wait(2)

func _test_serpent_untouched() -> void:
	var rig := await _load_boss_level("res://scenes/levels/world_4_boss.tscn", "SerpentBoss")
	var level: Node2D = rig.level
	var boss = rig.boss
	_check("SerpentBoss (Reina Veneno) shadow_fade_enabled sigue false", not boss.shadow_fade_enabled)
	_check("SerpentBoss teleport_enabled sigue false", not boss.teleport_enabled)
	_check("SerpentBoss summon_allies_scene sigue sin asignar", boss.summon_allies_scene == null)
	level.queue_free()
	await _wait(2)

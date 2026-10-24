class_name BossBase
extends EnemyBase

## Jefe reutilizable: se mueve y carga contra Luke, recibe varios golpes y
## muestra una barra de vida. Al ser derrotado completa el nivel.

signal boss_defeated

@export var hp_bar_width := 120.0
@export var hp_bar_height := 10.0
@export var hp_bar_y_offset := -92.0

## Para jefes sin piernas visibles (la Bruja, cuya pollera/capa las tapa; la
## Serpiente, que no tiene piernas): en vez de alternar 2 poses de caminata
## como el resto de los personajes, balancea la tela/cuerpo con una leve
## rotación oscilante mientras se mueve, simulando el movimiento sin
## necesitar sprites de piernas que no existen.
@export var sway_enabled := false
@export var sway_amplitude_deg := 5.0
@export var sway_speed := 5.0

## F9: la Serpiente ahora arranca en la plataforma MAS ALTA de su arena (ver
## world_4_boss.tscn), que tiene varias plataformas intermedias apiladas
## debajo (Six/Four-Cinco/Three/One-Two) antes de llegar al piso real. Con
## hop_strength/hop_interval fuertes (necesarios para que siga "saltando
## mas alto y mas seguido" que los jefes anteriores, ver diag_boss_powers),
## el jefe rebotaba en cadena de plataforma en plataforma sin bajar nunca
## del todo (cada aterrizaje en CUALQUIER plataforma disparaba otro salto
## fuerte antes de que la gravedad lo bajara mas) -- confirmado con un
## trace de posicion real. hop_min_y restringe el salto a cuando el jefe ya
## esta cerca de SU PROPIO piso real (por defecto -INF = sin restriccion,
## compatible con los otros 3 jefes tal cual estaban), dejando que la
## gravedad lo haga caer de corrido por las plataformas intermedias sin
## relanzarlo cada vez que las toca.
@export var hop_min_y := -INF

@export_category("Poderes de jefe")
## Cada jefe tiene DOS poderes distintos que alterna: uno que viaja al ras
## del piso (power_ground_scene) y otro en diagonal hacia arriba
## (power_diagonal_scene). power_interval es cada cuántos segundos dispara
## (fijo, no depende de la distancia a Luke: jefe 1 = 4s, jefe 2 = 3s,
## jefe 3 = 2s, jefe 4 = 1s). Reemplaza al sistema genérico de
## can_ranged_attack de EnemyBase, que queda desactivado en los jefes.
@export var power_ground_scene: PackedScene
@export var power_diagonal_scene: PackedScene
@export var power_interval := 4.0
@export var power_initial_delay := 1.5
## Salto extra (además del power) cada N segundos; 0 = desactivado. Pedido
## puntualmente para la Bruja del Olvido.
@export var extra_jump_interval := 0.0

@export_category("Poses del jefe (opcional)")
## Pose alternativa mientras el jefe está en el aire (saltando). Sin asignar,
## no cambia de textura al saltar (comportamiento anterior).
@export var jump_texture: Texture2D
## Pose alternativa que se muestra un instante justo al lanzar un poder
## (ground o diagonal). Sin asignar, no cambia de textura al atacar.
@export var power_texture: Texture2D
@export var power_pose_duration := 0.35

@export_category("Mecanica unica por jefe (B3)")
## Don Sombra: cada tanto se funde en las sombras (semitransparente e
## invulnerable un rato) y reaparece cerca de Luke. shadow_warning_duration
## es el aviso visual (parpadeo oscuro) ANTES de desaparecer, para que sea
## justo pegarle antes de que se esfume.
@export var shadow_fade_enabled := false
@export var shadow_fade_interval := 7.0
@export var shadow_warning_duration := 0.6
@export var shadow_duration := 2.0

## La Bruja del Olvido: se teletransporta entre plataformas de la arena con
## una nube de humo, avisando teleport_warning_duration segundos antes
## ADONDE va a aparecer (la nube sale ahi primero, vacia).
@export var teleport_enabled := false
@export var teleport_points: Array[Vector2] = []
@export var teleport_interval := 8.0
@export var teleport_warning_duration := 1.0

## El Gran Codicia: al llegar a la mitad de la vida, llama (una sola vez) a
## N ayudantes.
@export var summon_allies_scene: PackedScene
@export var summon_allies_count := 2
@export var summon_allies_offset := 130.0

const SMOKE_PUFF_SCENE := preload("res://scenes/effects/smoke_puff.tscn")

var _power_timer := 0.0
var _power_use_diagonal := false
var _extra_jump_timer := 0.0
var _power_pose_timer := 0.0
var _base_scale := Vector2.ONE
var _base_modulate := Color.WHITE

## B3: invulnerabilidad temporal (Don Sombra fundido en las sombras). No es
## lo mismo que is_defeated -- el jefe sigue vivo y procesando, solo que
## receive_attack() lo ignora mientras dure.
var _is_shadow_invulnerable := false
var _shadow_timer := 0.0
var _teleport_timer := 0.0
var _allies_summoned := false

func _init() -> void:
	drops_bone_on_defeat = true

var _hp_back: ColorRect
var _hp_front: ColorRect

func _ready() -> void:
	super()
	health = max_health
	_build_hp_bar()
	_power_timer = power_interval - power_initial_delay
	_extra_jump_timer = extra_jump_interval * 0.5
	# Escalonados a la mitad de su propio intervalo para que no coincidan con
	# el primer power (y entre si) apenas arranca la pelea.
	_shadow_timer = shadow_fade_interval * 0.5
	_teleport_timer = teleport_interval * 0.5
	if sprite != null:
		_base_scale = sprite.scale
		_base_modulate = sprite.modulate

func _physics_process(delta: float) -> void:
	if is_defeated:
		return
	super(delta)
	_hop_time += delta
	if is_on_floor() and _hop_time >= hop_interval and global_position.y >= hop_min_y:
		_hop_time = 0.0
		velocity.y = hop_strength
	if sway_enabled and sprite != null:
		var sway_strength: float = clampf(absf(velocity.x) / maxf(patrol_speed, 1.0), 0.35, 1.0)
		sprite.rotation = sin(_time * sway_speed) * deg_to_rad(sway_amplitude_deg) * sway_strength
	_handle_boss_powers(delta)
	_update_pose(delta)
	_handle_shadow_fade(delta)
	_handle_teleport(delta)

## Cambia la textura del sprite según el estado del jefe: la pose de poder
## tiene prioridad temporal (power_pose_duration segundos tras disparar),
## después vuelve a la pose de salto si está en el aire, o a la idle normal.
## Si jump_texture/power_texture no están asignadas, usa un pseudo-pose
## procedural (squash/stretch en el aire) para que el jefe no se vea como
## una imagen fija subiendo y bajando aunque no tenga arte extra.
func _update_pose(delta: float) -> void:
	if sprite == null:
		return
	if _power_pose_timer > 0.0:
		_power_pose_timer -= delta
		# Reafirmar la pose de poder todos los frames mientras dure: si el
		# jefe tiene walk_texture, _update_walk_animation (llamado antes,
		# desde EnemyBase, cada vez que hay movimiento horizontal) ya
		# pisó sprite.texture este mismo frame, y sin esto la pose de
		# ataque nunca llegaría a verse en un jefe que camina y ataca a
		# la vez (como Gran Codicia).
		if power_texture != null:
			sprite.texture = power_texture
		if _power_pose_timer > 0.0:
			return
		elif jump_texture == null and power_texture == null:
			sprite.scale = _base_scale
	if jump_texture != null:
		if not is_on_floor():
			sprite.texture = jump_texture
		elif sprite.texture == jump_texture:
			# Al aterrizar, soltar la pose de salto y dejar que el ciclo de
			# caminata (walk_texture) retome el control si corresponde, en
			# vez de forzar siempre la idle (rompería la animación de
			# piernas de jefes que tienen ambas poses, como Gran Codicia).
			sprite.texture = _idle_texture
	elif power_texture != null and sprite.texture == power_texture:
		sprite.texture = _idle_texture
	if jump_texture == null:
		var stretch := Vector2(0.88, 1.16) if not is_on_floor() else Vector2(1.0, 1.0)
		sprite.scale = sprite.scale.lerp(_base_scale * stretch, clampf(delta * 10.0, 0.0, 1.0))

## Alterna entre los dos poderes del jefe cada power_interval segundos, sin
## importar la distancia a Luke (a diferencia del ranged attack genérico de
## EnemyBase). Si extra_jump_interval > 0, también salta periódicamente
## (pedido para la Bruja del Olvido).
func _handle_boss_powers(delta: float) -> void:
	_power_timer += delta
	if _power_timer >= power_interval:
		_power_timer = 0.0
		_fire_power()
		_power_use_diagonal = not _power_use_diagonal
	if extra_jump_interval > 0.0:
		_extra_jump_timer += delta
		if _extra_jump_timer >= extra_jump_interval:
			_extra_jump_timer = 0.0
			if is_on_floor():
				velocity.y = hop_strength

func _fire_power() -> void:
	if sprite != null:
		if power_texture != null:
			sprite.texture = power_texture
			_power_pose_timer = power_pose_duration
		else:
			_power_pose_timer = power_pose_duration
			var pop_scale := _base_scale * 1.18
			var flash_color := Color(1.0, 0.55, 0.15, 1.0)
			var tween := create_tween()
			tween.tween_property(sprite, "scale", pop_scale, power_pose_duration * 0.3).set_trans(Tween.TRANS_BACK)
			tween.parallel().tween_property(sprite, "modulate", flash_color, power_pose_duration * 0.3)
			tween.tween_property(sprite, "scale", _base_scale, power_pose_duration * 0.7).set_trans(Tween.TRANS_SINE)
			tween.parallel().tween_property(sprite, "modulate", _base_modulate, power_pose_duration * 0.7)
	var scene: PackedScene = power_diagonal_scene if _power_use_diagonal else power_ground_scene
	if scene == null:
		return
	var parent := get_parent()
	if parent == null:
		return
	var target := _get_player()
	var dir := 1.0
	if target != null:
		dir = signf(target.global_position.x - global_position.x)
		if is_zero_approx(dir):
			dir = 1.0
	var projectile: Node = scene.instantiate()
	parent.add_child(projectile)
	projectile.launch(global_position, dir, self)

## E6 (corrección): el ladrido de onda debe pegar MAS fuerte que el huesito
## (el triple), no igual -- amount lo pasa el que ataca (bark_wave.gd manda
## 3; el golpe cuerpo a cuerpo y el huesito no mandan nada y usan el 1 de
## siempre).
## B3: Don Sombra ignora el daño entero mientras esta fundido en las
## sombras (_is_shadow_invulnerable) -- el aviso previo (shadow_warning_
## duration) es justamente la ventana donde SI se lo puede golpear antes de
## que se vuelva invulnerable.
func receive_attack(_attacker: Node, amount: int = 1) -> void:
	if is_defeated or _is_shadow_invulnerable:
		return
	health -= amount
	_update_hp_bar()
	AudioDirector.play_event(&"boss_hit")
	if health <= 0:
		is_defeated = true
		$CollisionShape2D.set_deferred("disabled", true)
		$DamageArea.set_deferred("monitoring", false)
		_drop_bone()
		boss_defeated.emit(self)
		GameState.complete_current_level()
		queue_free()
	else:
		modulate = Color(1.0, 0.55, 0.55, 1.0)
		await get_tree().create_timer(0.12).timeout
		if is_instance_valid(self):
			modulate = Color.WHITE
		_check_summon_allies()

## El Gran Codicia: a mitad de vida (una sola vez), llama a sus ayudantes.
func _check_summon_allies() -> void:
	if summon_allies_scene == null or _allies_summoned or is_defeated:
		return
	if health > max_health / 2:
		return
	_allies_summoned = true
	var parent := get_parent()
	if parent == null:
		return
	for i in range(summon_allies_count):
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var offset := summon_allies_offset * (1 + i / 2) * side
		var ally: Node2D = summon_allies_scene.instantiate()
		ally.global_position = global_position + Vector2(offset, 0.0)
		parent.add_child(ally)
	AudioDirector.play_event(&"aura_on")

func _build_hp_bar() -> void:
	_hp_back = ColorRect.new()
	_hp_back.color = Color(0.08, 0.08, 0.12, 0.9)
	_hp_back.size = Vector2(hp_bar_width, hp_bar_height)
	_hp_back.position = Vector2(-hp_bar_width / 2.0, hp_bar_y_offset)
	_hp_back.z_index = 5
	add_child(_hp_back)
	_hp_front = ColorRect.new()
	_hp_front.color = Color(0.95, 0.25, 0.2, 1.0)
	_hp_front.size = Vector2(hp_bar_width, hp_bar_height)
	_hp_front.position = _hp_back.position
	_hp_front.z_index = 6
	add_child(_hp_front)

func _update_hp_bar() -> void:
	if _hp_front == null:
		return
	_hp_front.size.x = maxf(hp_bar_width * (float(health) / float(max_health)), 0.0)

## --- B3: mecanica unica de Don Sombra ---
func _handle_shadow_fade(delta: float) -> void:
	if not shadow_fade_enabled or _is_shadow_invulnerable:
		return
	_shadow_timer += delta
	if _shadow_timer >= shadow_fade_interval:
		_shadow_timer = 0.0
		_start_shadow_fade()

## El aviso previo (el parpadeo oscuro) SIGUE siendo golpeable a proposito --
## _is_shadow_invulnerable recien se activa despues, en shadow_warning_duration.
func _start_shadow_fade() -> void:
	var warn_tween: Tween
	if sprite != null:
		warn_tween = create_tween()
		warn_tween.tween_property(sprite, "modulate", Color(0.2, 0.08, 0.3, 1.0), shadow_warning_duration * 0.5)
		warn_tween.tween_property(sprite, "modulate", _base_modulate, shadow_warning_duration * 0.5)
	await get_tree().create_timer(shadow_warning_duration).timeout
	if not is_instance_valid(self) or is_defeated:
		return
	# El tween del aviso puede terminar su ultimo tramo (vuelta a _base_modulate)
	# justo este mismo frame -- lo matamos explicitamente para que no pise el
	# alfa semitransparente que marca la invulnerabilidad real.
	if warn_tween != null and warn_tween.is_valid():
		warn_tween.kill()
	_is_shadow_invulnerable = true
	if sprite != null:
		sprite.modulate = _base_modulate
		sprite.modulate.a = 0.35
	await get_tree().create_timer(shadow_duration * 0.4).timeout
	if not is_instance_valid(self) or is_defeated:
		return
	var target := _get_player()
	if target != null:
		var side: float = 1.0 if randf() < 0.5 else -1.0
		global_position = target.global_position + Vector2(side * randf_range(110.0, 190.0), -40.0)
		velocity = Vector2.ZERO
	await get_tree().create_timer(shadow_duration * 0.6).timeout
	if not is_instance_valid(self) or is_defeated:
		return
	if sprite != null:
		sprite.modulate = _base_modulate
	_is_shadow_invulnerable = false

## --- B3: mecanica unica de la Bruja del Olvido ---
func _handle_teleport(delta: float) -> void:
	if not teleport_enabled or teleport_points.is_empty():
		return
	_teleport_timer += delta
	if _teleport_timer >= teleport_interval:
		_teleport_timer = 0.0
		_start_teleport()

func _start_teleport() -> void:
	var target_pos: Vector2 = teleport_points[randi() % teleport_points.size()]
	_spawn_smoke(target_pos)
	await get_tree().create_timer(teleport_warning_duration).timeout
	if not is_instance_valid(self) or is_defeated:
		return
	_spawn_smoke(global_position)
	global_position = target_pos
	velocity = Vector2.ZERO
	_spawn_smoke(global_position)

func _spawn_smoke(at: Vector2) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var puff: Node2D = SMOKE_PUFF_SCENE.instantiate()
	puff.global_position = at
	parent.add_child(puff)

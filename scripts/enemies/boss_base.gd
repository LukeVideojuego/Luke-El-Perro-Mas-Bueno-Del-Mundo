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

var _power_timer := 0.0
var _power_use_diagonal := false
var _extra_jump_timer := 0.0
var _power_pose_timer := 0.0
var _base_scale := Vector2.ONE
var _base_modulate := Color.WHITE

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
	if sprite != null:
		_base_scale = sprite.scale
		_base_modulate = sprite.modulate

func _physics_process(delta: float) -> void:
	if is_defeated:
		return
	super(delta)
	_hop_time += delta
	if is_on_floor() and _hop_time >= hop_interval:
		_hop_time = 0.0
		velocity.y = hop_strength
	if sway_enabled and sprite != null:
		var sway_strength: float = clampf(absf(velocity.x) / maxf(patrol_speed, 1.0), 0.35, 1.0)
		sprite.rotation = sin(_time * sway_speed) * deg_to_rad(sway_amplitude_deg) * sway_strength
	_handle_boss_powers(delta)
	_update_pose(delta)

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

func receive_attack(_attacker: Node) -> void:
	if is_defeated:
		return
	health -= 1
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

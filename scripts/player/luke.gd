class_name Luke
extends CharacterBody2D

## Controlador reutilizable de Luke. No depende de un nivel concreto.
@export_category("Movement")
@export var walk_speed := 320.0
@export var run_speed := 510.0
@export var ground_acceleration := 2600.0
@export var ground_deceleration := 3000.0
@export var air_acceleration := 1500.0
@export var gravity := 1900.0
@export var jump_velocity := -720.0
@export var double_jump_velocity := -650.0
@export var max_fall_speed := 1200.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var attack_visual: Polygon2D = $AttackVisual
@onready var aura_visual: Polygon2D = $AuraVisual
@onready var hat_sprite: Sprite2D = $Hat
@onready var cape_sprite: Sprite2D = $Cape
@onready var suit_sprite: Sprite2D = $Suit

@export_category("Power-ups")
@export var speed_boost_multiplier := 1.5
@export var speed_boost_duration := 6.0
@export var invincibility_duration := 6.0

@export_category("Ataque a distancia")
## Ventana para detectar doble tap del botón de ataque (huesito a distancia).
@export var double_tap_window := 0.28
@export var throw_offset := Vector2(46.0, -6.0)

const THROWN_BONE_SCENE := preload("res://scenes/objects/thrown_bone.tscn")
const BARK_WAVE_SCENE := preload("res://scenes/objects/bark_wave.tscn")

@export_category("Cosmeticos de la tienda (C3)")
## Sombreros comprables. Se dibujan sobre la cabeza en TODAS las animaciones:
## el ancla de cada pose se midio sobre el arte real de Luke (tope de la
## cabeza y centro de las orejas en cada textura).
const HAT_TEXTURES := {
	"hat_beanie": preload("res://assets/items/Shop/hat_beanie.png"),
	"hat_explorer": preload("res://assets/items/Shop/hat_explorer.png"),
	"hat_tophat": preload("res://assets/items/Shop/hat_tophat.png"),
	"hat_crown": preload("res://assets/items/Shop/hat_crown.png"),
}
const CAPE_FOLDED := preload("res://assets/items/Shop/cape_folded.png")
const CAPE_OPEN := preload("res://assets/items/Shop/cape_open.png")
const SUIT_BODY := preload("res://assets/items/Shop/suit_body.png")
## Posicion del sombrero (borde inferior, centrado) por animacion, en
## coordenadas locales de Luke.
const HAT_ANCHOR := {
	"idle": Vector2(16.6, -44.9),
	"walk": Vector2(18.5, -44.9),
	"jump": Vector2(17.2, -50.4),
	"attack": Vector2(14.1, -27.1),
}
const CAPE_ANCHOR := {
	"idle": Vector2(-16.0, 2.0),
	"walk": Vector2(-17.0, -3.0),
	"jump": Vector2(-18.0, 3.0),
	"attack": Vector2(-20.0, -10.0),
}
## Medido sobre el lomo real de Luke (borde superior opaco de la mitad
## trasera del sprite en cada pose).
const SUIT_ANCHOR := {
	"idle": Vector2(-25.8, 12.0),
	"walk": Vector2(-27.1, 7.0),
	"jump": Vector2(-27.7, 14.0),
	"attack": Vector2(-25.2, 0.0),
}

@export_category("Bajo el agua")
## Activado por instancia en los niveles acuáticos: agrega burbujas al
## moverse y una animación de flote sutil en el idle (puramente visual,
## no afecta la física; la velocidad/gravedad se ajustan aparte con los
## export de Movement de esta misma instancia).
@export var underwater_mode := false
@export var bubble_interval := 0.45
@export var idle_bob_amplitude := 4.0
@export var idle_bob_speed := 2.2

const RISING_BUBBLE_SCENE := preload("res://scenes/objects/rising_bubble.tscn")
var _bubble_timer := 0.0
var _idle_time := 0.0
var _sprite_base_y := 0.0

signal attack_started
signal damaged
signal defeated
signal aura_changed(is_active: bool)
signal speed_boost_changed(is_active: bool)
signal invincibility_changed(is_active: bool)

var facing_direction := 1
var jumps_used := 0
var is_attacking := false
var is_throwing := false
var has_protective_aura := false
var can_receive_damage := true
var has_speed_boost := false
var has_invincibility := false

var _speed_boost_token := 0
var _invincibility_token := 0
var _attack_tap_timer := 0.0
var _attack_query := PhysicsShapeQueryParameters2D.new()
var _hit_this_swing: Array[int] = []

## Altura neta caída en el último aterrizaje (posición Y de aterrizaje menos
## la posición Y de la última vez que estuvo en el piso antes de despegar).
## Saltar y volver a caer en el mismo piso da ~0 (no penaliza el salto
## normal); solo cae en un valor grande cuando aterriza en un piso más bajo
## que el que pisaba antes (p. ej. una plataforma aérea). Usado por
## fall_damage_floor.gd para el riesgo de "Corazones de Oro" (Mundo 2).
var last_fall_distance := 0.0
var _air_start_y := 0.0

func _ready() -> void:
	# Consulta reutilizable para el golpe cuerpo a cuerpo (ver _apply_melee_hits).
	_attack_query.shape = attack_shape.shape
	_attack_query.collision_mask = attack_area.collision_mask
	# collide_with_areas: la caja receptora de los jefes (B7) es un Area2D.
	_attack_query.collide_with_areas = true
	_attack_query.collide_with_bodies = true
	# Evita un falso "caída enorme" en el primer frame: sin esto,
	# _air_start_y arrancaba en 0.0 y cualquier spawn con Luke unos pocos
	# píxeles por encima del piso (lo normal en casi todos los niveles) se
	# leía como una caída desde y=0, activando fall_damage_floor.gd de pedo.
	_air_start_y = global_position.y

func _physics_process(delta: float) -> void:
	var was_on_floor := is_on_floor()
	if was_on_floor:
		_air_start_y = global_position.y
	_apply_gravity(delta)
	_handle_movement(delta)
	_handle_jump(was_on_floor)
	_handle_attack(delta)
	move_and_slide()
	if is_on_floor():
		if not was_on_floor:
			last_fall_distance = global_position.y - _air_start_y
		jumps_used = 0
	_update_animation()
	if underwater_mode:
		_handle_underwater_effects(delta)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)

func _handle_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var target_speed := run_speed if Input.is_action_pressed("run") else walk_speed
	if has_speed_boost:
		target_speed *= speed_boost_multiplier
	if not is_zero_approx(direction):
		var acceleration := ground_acceleration if is_on_floor() else air_acceleration
		velocity.x = move_toward(velocity.x, direction * target_speed, acceleration * delta)
		facing_direction = 1 if direction > 0.0 else -1
	else:
		velocity.x = move_toward(velocity.x, 0.0, ground_deceleration * delta)

func _handle_jump(was_on_floor: bool) -> void:
	if not Input.is_action_just_pressed("jump"):
		return
	if was_on_floor or jumps_used == 0:
		velocity.y = jump_velocity
		jumps_used = 1
		AudioDirector.play_event(&"jump")
	elif jumps_used == 1:
		velocity.y = double_jump_velocity
		jumps_used = 2
		AudioDirector.play_event(&"jump")

## B5 (lag del golpe): antes, con el huesito desbloqueado, CADA toque simple
## esperaba los 0.28s enteros de la ventana de doble tap antes de pegar, para
## recien ahi "confirmarse" como golpe simple. Eso son ~17 frames de retraso
## en absolutamente todos los golpes del juego, que es exactamente el lag que
## se sentia.
##
## Ahora el golpe sale SIEMPRE en el mismo frame en que se aprieta la tecla, y
## la ventana de doble tap solo decide si un SEGUNDO toque rapido agrega
## ademas el huesito a distancia. El doble tap sigue funcionando igual y ya no
## le cuesta nada al golpe normal.
func _handle_attack(delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		if GameState.bone_throw_unlocked and _attack_tap_timer > 0.0:
			_attack_tap_timer = 0.0
			if not is_throwing:
				_start_ranged_attack()
		else:
			_attack_tap_timer = double_tap_window
			if not is_attacking:
				_start_attack()
	elif _attack_tap_timer > 0.0:
		_attack_tap_timer = maxf(0.0, _attack_tap_timer - delta)
	if is_attacking:
		_apply_melee_hits()

## Deteccion de impacto del golpe cuerpo a cuerpo.
##
## No se usa get_overlapping_bodies() del Area2D porque habilitar su forma va
## por set_deferred(), asi que en el primer frame del golpe el area todavia no
## existe para el motor y se perdia un frame mas. Una consulta directa al
## espacio fisico con la misma forma y en la misma posicion pega ya en el
## frame cero.
##
## B7: la consulta devuelve TODOS los cuerpos solapados (no solo el primero) y
## los jefes tienen su hurtbox cubriendo toda la silueta, asi que cuenta el
## impacto en cualquier parte del cuerpo.
func _apply_melee_hits() -> void:
	if _attack_query.shape == null:
		return
	_attack_query.transform = Transform2D(0.0, global_position + Vector2(58.0 * facing_direction, 0.0))
	for hit in get_world_2d().direct_space_state.intersect_shape(_attack_query, 16):
		var body: Object = hit.get("collider")
		if body == null or not body.has_method("receive_attack"):
			continue
		# Un golpe = un impacto por objetivo. El hitbox queda activo ~11
		# frames y antes se llamaba receive_attack() en cada uno de ellos:
		# con la hurtbox de jefe nueva (que cubre toda la silueta) eso
		# significaria vaciarle la vida de una sola tecla. Deduplicar
		# mantiene el dano por golpe exactamente como estaba pensado (1).
		var id: int = body.get_instance_id()
		if _hit_this_swing.has(id):
			continue
		_hit_this_swing.append(id)
		body.receive_attack(self)

## C3: el doble tap lanza el ladrido de onda expansiva si quedan cargas
## compradas en la tienda (es mas rapido y atraviesa), y si no, el huesito de
## siempre, que es municion infinita.
func _start_ranged_attack() -> void:
	is_throwing = true
	attack_visual.visible = true
	attack_visual.scale.x = facing_direction
	attack_started.emit()
	AudioDirector.play_event(&"attack")
	var use_bark: bool = GameState.consume_bark()
	var projectile: Node2D = (BARK_WAVE_SCENE if use_bark else THROWN_BONE_SCENE).instantiate()
	var parent := get_parent()
	if parent != null:
		parent.add_child(projectile)
		projectile.launch(global_position + throw_offset * Vector2(facing_direction, 1.0), float(facing_direction), self)
	await get_tree().create_timer(0.15).timeout
	attack_visual.visible = false
	is_throwing = false

func _start_attack() -> void:
	is_attacking = true
	_hit_this_swing.clear()
	attack_visual.visible = true
	attack_visual.scale.x = facing_direction
	attack_shape.position.x = 58.0 * facing_direction
	attack_shape.set_deferred("disabled", false)
	attack_started.emit()
	AudioDirector.play_event(&"attack")
	await get_tree().create_timer(0.18).timeout
	attack_shape.set_deferred("disabled", true)
	attack_visual.visible = false
	is_attacking = false

func _on_attack_area_body_entered(body: Node2D) -> void:
	if is_attacking and body.has_method("receive_attack"):
		body.receive_attack(self)

func receive_damage(_source: Node2D = null) -> void:
	if has_invincibility or not can_receive_damage:
		return
	can_receive_damage = false
	damaged.emit()
	AudioDirector.play_event(&"damage")
	if has_protective_aura:
		set_protective_aura(false)
	else:
		defeated.emit()
	await get_tree().create_timer(0.75).timeout
	can_receive_damage = true

func set_protective_aura(active: bool) -> void:
	if has_protective_aura == active:
		return
	has_protective_aura = active
	aura_visual.visible = active
	GameState.set_aura(active)
	aura_changed.emit(active)
	AudioDirector.play_event(&"aura_on" if active else &"aura_lost")

## Duración limitada: cada pickup reinicia el cronómetro en vez de sumarse,
## así que agarrar varios seguidos extiende el efecto sin acumular velocidad.
func grant_speed_boost() -> void:
	_speed_boost_token += 1
	var my_token := _speed_boost_token
	if not has_speed_boost:
		has_speed_boost = true
		speed_boost_changed.emit(true)
		GameState.set_speed_boost(true)
	await get_tree().create_timer(speed_boost_duration).timeout
	if my_token == _speed_boost_token:
		has_speed_boost = false
		speed_boost_changed.emit(false)
		GameState.set_speed_boost(false)

## duration_override: la estrella de la tienda (C3) dura mas que el power-up
## suelto del nivel.
func grant_invincibility(duration_override: float = -1.0) -> void:
	_invincibility_token += 1
	var my_token := _invincibility_token
	if not has_invincibility:
		has_invincibility = true
		invincibility_changed.emit(true)
		GameState.set_invincibility(true)
	var duration: float = invincibility_duration if duration_override <= 0.0 else duration_override
	await get_tree().create_timer(duration).timeout
	if my_token == _invincibility_token:
		has_invincibility = false
		invincibility_changed.emit(false)
		GameState.set_invincibility(false)

func respawn(respawn_position: Vector2) -> void:
	velocity = Vector2.ZERO
	global_position = respawn_position
	set_physics_process(true)

func _update_animation() -> void:
	animated_sprite.flip_h = facing_direction < 0
	if has_invincibility:
		var blink: float = sin(Time.get_ticks_msec() / 60.0)
		animated_sprite.modulate = Color(1.0, 0.85, 0.2, 1.0) if blink > 0.0 else Color(1.0, 1.0, 1.0, 0.55)
	elif has_speed_boost:
		animated_sprite.modulate = Color(0.6, 0.85, 1.0, 1.0)
	else:
		animated_sprite.modulate = Color(1, 1, 1, 1)
	if is_attacking or is_throwing:
		animated_sprite.play("attack")
	elif not is_on_floor():
		animated_sprite.play("jump")
	elif absf(velocity.x) > 25.0:
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")
	if underwater_mode and not is_attacking and not is_throwing and absf(velocity.x) <= 25.0:
		animated_sprite.position.y = _sprite_base_y + sin(_idle_time * idle_bob_speed) * idle_bob_amplitude
	else:
		animated_sprite.position.y = _sprite_base_y
	_update_cosmetics()

## C3: dibuja lo comprado en la tienda encima de Luke. El sombrero acompana
## la cabeza en las 4 animaciones y la capa se despliega cuando esta en el
## aire (es decir, cada vez que salta).
func _update_cosmetics() -> void:
	var anim := String(animated_sprite.animation)
	var flipped := facing_direction < 0
	var bob: float = animated_sprite.position.y - _sprite_base_y

	var hat_id: String = GameState.equipped_hat
	var has_hat: bool = HAT_TEXTURES.has(hat_id)
	hat_sprite.visible = has_hat
	if has_hat:
		var tex: Texture2D = HAT_TEXTURES[hat_id]
		var anchor: Vector2 = HAT_ANCHOR.get(anim, HAT_ANCHOR["idle"])
		hat_sprite.texture = tex
		hat_sprite.offset = Vector2(0.0, -tex.get_height() * 0.5 + 12.0)
		hat_sprite.position = Vector2(anchor.x * facing_direction, anchor.y + bob)
		hat_sprite.flip_h = flipped
		hat_sprite.modulate = animated_sprite.modulate

	var wears_suit: bool = GameState.suit_equipped
	suit_sprite.visible = wears_suit
	cape_sprite.visible = wears_suit
	if wears_suit:
		var suit_anchor: Vector2 = SUIT_ANCHOR.get(anim, SUIT_ANCHOR["idle"])
		suit_sprite.texture = SUIT_BODY
		suit_sprite.position = Vector2(suit_anchor.x * facing_direction, suit_anchor.y + bob)
		suit_sprite.flip_h = flipped
		suit_sprite.modulate = animated_sprite.modulate
		var cape_tex: Texture2D = CAPE_OPEN if not is_on_floor() else CAPE_FOLDED
		var cape_anchor: Vector2 = CAPE_ANCHOR.get(anim, CAPE_ANCHOR["idle"])
		cape_sprite.texture = cape_tex
		cape_sprite.offset = Vector2(0.0, cape_tex.get_height() * 0.5)
		cape_sprite.position = Vector2(cape_anchor.x * facing_direction, cape_anchor.y + bob)
		cape_sprite.flip_h = flipped
		cape_sprite.modulate = animated_sprite.modulate

func _handle_underwater_effects(delta: float) -> void:
	_idle_time += delta
	_bubble_timer -= delta
	if _bubble_timer <= 0.0:
		_bubble_timer = bubble_interval
		_spawn_trail_bubble()

func _spawn_trail_bubble() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var bubble := RISING_BUBBLE_SCENE.instantiate()
	parent.add_child(bubble)
	var offset := Vector2(randf_range(-16.0, 16.0), randf_range(-10.0, 10.0))
	bubble.global_position = global_position + offset + Vector2(0.0, -20.0)

class_name EnemyBase
extends CharacterBody2D

## Base común para enemigos terrestres, voladores, acuáticos y jefes.
## El modo de movimiento se elige por instancia para reutilizar la misma
## lógica de combate y contacto sin duplicar código.

enum MovementMode {
	GROUND_PATROL,
	FLY_HORIZONTAL,
	BOB_VERTICAL,
	CHARGE,
	HOP,
}

## Animación cosmética al tocar a Luke, elegida por tipo de personaje:
## BITE (mordida, tiburones), STING (picadura, insectos/medusa/serpiente),
## STEAL (el ladrón "roba" el chaleco de Luke y se lo devuelve), FINE (el
## político le entrega una multa), GENERIC (sacudida simple).
enum ContactAnim { GENERIC, BITE, STING, STEAL, FINE }

signal defeated(enemy: EnemyBase)

@export_category("Combat")
@export var contact_damage := 1
@export var max_health := 1
## Si true, este enemigo suelta un huesito coleccionable al ser derrotado.
@export var drops_bone_on_defeat := false
@export var contact_anim: ContactAnim = ContactAnim.GENERIC
@export_category("Movement")
@export var patrol_speed := 95.0
@export var gravity := 1800.0
@export var patrol_distance := 150.0
@export var movement_mode: MovementMode = MovementMode.GROUND_PATROL
@export var bob_amplitude := 20.0
@export var bob_frequency := 2.0
@export var charge_speed := 240.0
@export var charge_duration := 0.7
@export var charge_cooldown := 1.6
@export var detect_range := 360.0
@export var hop_strength := -360.0
@export var hop_interval := 1.1

@export_category("Ataque a distancia")
## Si true, este enemigo lanza proyectiles a Luke cuando está dentro de
## ranged_detect_range, con una cadencia de ranged_cooldown segundos.
@export var can_ranged_attack := false
@export var ranged_projectile_scene: PackedScene
@export var ranged_detect_range := 420.0
@export var ranged_cooldown := 2.2
## Retraso inicial antes del primer disparo (evita que dispare apenas spawnea).
@export var ranged_initial_delay := 0.6

var _ranged_cooldown_time := 0.0

var health := 1
var spawn_x := 0.0
var base_y := 0.0
var patrol_direction := -1.0
var is_defeated := false

var _time := 0.0
var _is_charging := false
var _charge_time := 0.0
var _cooldown_time := 0.0
var _charge_dir := -1.0
var _hop_time := 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	health = max_health
	spawn_x = global_position.x
	base_y = global_position.y
	_ranged_cooldown_time = ranged_initial_delay

func _physics_process(delta: float) -> void:
	if is_defeated:
		return
	_time += delta
	match movement_mode:
		MovementMode.GROUND_PATROL:
			_handle_ground_patrol(delta)
		MovementMode.FLY_HORIZONTAL:
			_handle_fly_horizontal()
		MovementMode.BOB_VERTICAL:
			_handle_bob_vertical()
		MovementMode.CHARGE:
			_handle_charge(delta)
		MovementMode.HOP:
			_handle_hop(delta)
	_handle_ranged_attack(delta)
	move_and_slide()
	if sprite != null:
		sprite.flip_h = patrol_direction > 0.0

## Solo invierte la dirección cuando el enemigo se está alejando del punto
## de spawn más allá del límite; si ya está volviendo, nunca vuelve a
## activarse aunque la distancia absoluta siga siendo >= patrol_distance
## por un frame más (evita que quede oscilando/trabado justo en el borde).
func _past_patrol_edge() -> bool:
	var offset := global_position.x - spawn_x
	return (patrol_direction > 0.0 and offset >= patrol_distance) \
		or (patrol_direction < 0.0 and offset <= -patrol_distance)

func _handle_ground_patrol(delta: float) -> void:
	velocity.y = minf(velocity.y + gravity * delta, 1100.0)
	velocity.x = patrol_direction * patrol_speed
	if _past_patrol_edge() or is_on_wall():
		patrol_direction *= -1.0

func _handle_fly_horizontal() -> void:
	velocity.x = patrol_direction * patrol_speed
	velocity.y = 0.0
	if _past_patrol_edge():
		patrol_direction *= -1.0
	if bob_amplitude > 0.0:
		global_position.y = base_y + sin(_time * bob_frequency * TAU) * bob_amplitude

func _handle_bob_vertical() -> void:
	velocity = Vector2.ZERO
	global_position.y = base_y + sin(_time * bob_frequency * TAU) * bob_amplitude

func _handle_charge(delta: float) -> void:
	velocity.y = minf(velocity.y + gravity * delta, 1200.0)
	if _is_charging:
		velocity.x = _charge_dir * charge_speed
		_charge_time += delta
		if _charge_time >= charge_duration:
			_is_charging = false
			_cooldown_time = charge_cooldown
	elif _cooldown_time > 0.0:
		_cooldown_time -= delta
		velocity.x = 0.0
	else:
		var target := _get_player()
		if target != null and target.global_position.distance_to(global_position) < detect_range:
			_is_charging = true
			_charge_time = 0.0
			_charge_dir = signf(target.global_position.x - global_position.x)
			if is_zero_approx(_charge_dir):
				_charge_dir = 1.0
			patrol_direction = _charge_dir
		else:
			velocity.x = 0.0

func _handle_hop(delta: float) -> void:
	velocity.y = minf(velocity.y + gravity * delta, 1100.0)
	velocity.x = patrol_direction * patrol_speed
	if _past_patrol_edge() or is_on_wall():
		patrol_direction *= -1.0
	_hop_time += delta
	if is_on_floor() and _hop_time >= hop_interval:
		_hop_time = 0.0
		velocity.y = hop_strength

func _handle_ranged_attack(delta: float) -> void:
	if not can_ranged_attack or ranged_projectile_scene == null:
		return
	if _ranged_cooldown_time > 0.0:
		_ranged_cooldown_time -= delta
		return
	var target := _get_player()
	if target == null:
		return
	if global_position.distance_to(target.global_position) > ranged_detect_range:
		return
	_fire_projectile(target)
	_ranged_cooldown_time = ranged_cooldown

func _fire_projectile(target: Luke) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var dir := signf(target.global_position.x - global_position.x)
	if is_zero_approx(dir):
		dir = 1.0
	var projectile: Node = ranged_projectile_scene.instantiate()
	parent.add_child(projectile)
	projectile.launch(global_position, dir, self)

func _get_player() -> Luke:
	var parent := get_parent()
	if parent == null:
		return null
	return parent.get_node_or_null("Luke")

func receive_attack(_attacker: Node) -> void:
	if is_defeated:
		return
	health -= 1
	if health <= 0:
		is_defeated = true
		$CollisionShape2D.set_deferred("disabled", true)
		$DamageArea.set_deferred("monitoring", false)
		_drop_bone()
		defeated.emit(self)
		queue_free()

const BONE_PICKUP_SCENE := preload("res://scenes/objects/bone_pickup.tscn")

func _drop_bone() -> void:
	if not drops_bone_on_defeat:
		return
	var parent := get_parent()
	if parent == null:
		return
	var bone := BONE_PICKUP_SCENE.instantiate()
	bone.global_position = global_position
	parent.call_deferred("add_child", bone)

const VEST_ICON := preload("res://assets/ui/icon_chaleco.png")
const FINE_ICON := preload("res://assets/ui/icon_multa.png")

func _on_damage_area_body_entered(body: Node2D) -> void:
	if not is_defeated and body is Luke:
		_play_contact_animation(body)
		body.receive_damage(self)

## Animación puramente cosmética en el instante del contacto; no afecta el
## daño (ya resuelto por Luke.receive_damage). Cada rama usa un Tween corto
## para no bloquear el resto de la lógica del enemigo.
func _play_contact_animation(luke: Luke) -> void:
	if sprite == null:
		return
	match contact_anim:
		ContactAnim.BITE:
			_anim_snap()
		ContactAnim.STING:
			_anim_jab(Color(1, 1, 1, 1))
		ContactAnim.STEAL:
			_anim_steal(luke)
		ContactAnim.FINE:
			_anim_fine(luke)
		_:
			_anim_wobble()

## Mordida: el sprite se agranda de golpe y vuelve, simulando un mordisco.
func _anim_snap() -> void:
	var base_scale := sprite.scale
	var tween := create_tween()
	tween.tween_property(sprite, "scale", base_scale * 1.35, 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "scale", base_scale, 0.14).set_trans(Tween.TRANS_SINE)

## Picadura: el sprite se lanza hacia adelante (hacia Luke) y vuelve rápido.
func _anim_jab(tint: Color) -> void:
	var base_pos := sprite.position
	var dir := 1.0 if not sprite.flip_h else -1.0
	var jab_offset := Vector2(14.0 * dir, 0.0)
	var base_modulate := sprite.modulate
	var tween := create_tween()
	tween.tween_property(sprite, "position", base_pos + jab_offset, 0.06).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "modulate", tint, 0.06)
	tween.tween_property(sprite, "position", base_pos, 0.12).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "modulate", base_modulate, 0.12)

## Sacudida genérica (enemigos sin animación temática específica).
func _anim_wobble() -> void:
	var base_rotation := sprite.rotation
	var tween := create_tween()
	tween.tween_property(sprite, "rotation", base_rotation + 0.25, 0.06)
	tween.tween_property(sprite, "rotation", base_rotation - 0.2, 0.08)
	tween.tween_property(sprite, "rotation", base_rotation, 0.08)

## El ladrón "roba" el chaleco de Luke: un ícono vuela de Luke al ladrón,
## espera un instante y vuelve a Luke, que recupera su apariencia normal.
func _anim_steal(luke: Luke) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var icon := Sprite2D.new()
	icon.texture = VEST_ICON
	icon.scale = Vector2(0.8, 0.8)
	icon.z_index = 10
	icon.global_position = luke.global_position + Vector2(0, -60)
	parent.call_deferred("add_child", icon)
	var to_thief := global_position + Vector2(0, -50)
	var tween := create_tween()
	tween.tween_property(icon, "global_position", to_thief, 0.25).set_trans(Tween.TRANS_QUAD)
	tween.tween_interval(0.35)
	tween.tween_property(icon, "global_position", luke.global_position + Vector2(0, -60), 0.3).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(icon.queue_free)

## El político le entrega una multa a Luke: el ícono aparece sobre Luke y
## se desvanece.
func _anim_fine(luke: Luke) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var icon := Sprite2D.new()
	icon.texture = FINE_ICON
	icon.scale = Vector2(0.8, 0.8)
	icon.z_index = 10
	icon.global_position = global_position + Vector2(0, -60)
	parent.call_deferred("add_child", icon)
	var target := luke.global_position + Vector2(0, -70)
	var tween := create_tween()
	tween.tween_property(icon, "global_position", target, 0.25).set_trans(Tween.TRANS_QUAD)
	tween.tween_interval(0.4)
	tween.tween_property(icon, "modulate:a", 0.0, 0.3)
	tween.tween_callback(icon.queue_free)

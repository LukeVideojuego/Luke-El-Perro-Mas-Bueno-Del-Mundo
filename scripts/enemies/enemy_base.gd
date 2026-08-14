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

signal defeated(enemy: EnemyBase)

@export_category("Combat")
@export var contact_damage := 1
@export var max_health := 1
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
	move_and_slide()
	if sprite != null:
		sprite.flip_h = patrol_direction > 0.0

func _handle_ground_patrol(delta: float) -> void:
	velocity.y = minf(velocity.y + gravity * delta, 1100.0)
	velocity.x = patrol_direction * patrol_speed
	if absf(global_position.x - spawn_x) >= patrol_distance or is_on_wall():
		patrol_direction *= -1.0

func _handle_fly_horizontal() -> void:
	velocity.x = patrol_direction * patrol_speed
	velocity.y = 0.0
	if absf(global_position.x - spawn_x) >= patrol_distance:
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
	if absf(global_position.x - spawn_x) >= patrol_distance or is_on_wall():
		patrol_direction *= -1.0
	_hop_time += delta
	if is_on_floor() and _hop_time >= hop_interval:
		_hop_time = 0.0
		velocity.y = hop_strength

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
		defeated.emit(self)
		queue_free()

func _on_damage_area_body_entered(body: Node2D) -> void:
	if not is_defeated and body is Luke:
		body.receive_damage(self)

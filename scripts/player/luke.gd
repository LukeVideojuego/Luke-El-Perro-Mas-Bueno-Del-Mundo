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

@export_category("Power-ups")
@export var speed_boost_multiplier := 1.5
@export var speed_boost_duration := 6.0
@export var invincibility_duration := 6.0

signal attack_started
signal damaged
signal defeated
signal aura_changed(is_active: bool)
signal speed_boost_changed(is_active: bool)
signal invincibility_changed(is_active: bool)

var facing_direction := 1
var jumps_used := 0
var is_attacking := false
var has_protective_aura := false
var can_receive_damage := true
var has_speed_boost := false
var has_invincibility := false

var _speed_boost_token := 0
var _invincibility_token := 0

func _physics_process(delta: float) -> void:
	var was_on_floor := is_on_floor()
	_apply_gravity(delta)
	_handle_movement(delta)
	_handle_jump(was_on_floor)
	_handle_attack()
	move_and_slide()
	if is_on_floor():
		jumps_used = 0
	_update_animation()

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

func _handle_attack() -> void:
	if Input.is_action_just_pressed("attack") and not is_attacking:
		_start_attack()
	elif is_attacking:
		for body in attack_area.get_overlapping_bodies():
			if body.has_method("receive_attack"):
				body.receive_attack(self)

func _start_attack() -> void:
	is_attacking = true
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

func grant_invincibility() -> void:
	_invincibility_token += 1
	var my_token := _invincibility_token
	if not has_invincibility:
		has_invincibility = true
		invincibility_changed.emit(true)
		GameState.set_invincibility(true)
	await get_tree().create_timer(invincibility_duration).timeout
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
	if is_attacking:
		animated_sprite.play("attack")
	elif not is_on_floor():
		animated_sprite.play("jump")
	elif absf(velocity.x) > 25.0:
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")

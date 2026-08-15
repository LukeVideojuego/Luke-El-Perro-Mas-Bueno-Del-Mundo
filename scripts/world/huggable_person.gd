class_name HuggablePerson
extends Area2D

## Persona a la que Luke puede abrazar en el minijuego final. Al contacto,
## cambia a una pose feliz y muestra un corazón flotante; no vuelve a
## reaccionar (cada persona cuenta una sola vez).
##
## Cuando wander_enabled está activo, la persona deambula por una zona
## alrededor de su posición inicial y salta ocasionalmente, para que cueste
## más alcanzarla (referencia: panel "La Fiesta del Amor" de
## imagen-referencias-personajes-fondos-pantallas.png).

signal hugged(person: HuggablePerson)

@export var happy_texture: Texture2D

@export_category("Deambular (minijuego final)")
@export var wander_enabled := false
@export var wander_radius := 200.0
@export var wander_speed := 70.0
@export var jump_interval_min := 1.6
@export var jump_interval_max := 3.2
@export var jump_height := 26.0
@export var jump_duration := 0.35

@onready var sprite: Sprite2D = $Sprite2D
@onready var heart: Label = $Heart

var is_hugged := false

var _base_x := 0.0
var _target_x := 0.0
var _jump_timer := 0.0
var _visual_y := 0.0

func _ready() -> void:
	_base_x = global_position.x
	_visual_y = sprite.position.y
	if wander_enabled:
		_pick_new_target()
		_jump_timer = randf_range(jump_interval_min, jump_interval_max)

func _process(delta: float) -> void:
	if not wander_enabled or is_hugged:
		return
	_handle_wander(delta)
	_handle_jump(delta)

func _handle_wander(delta: float) -> void:
	var dir := signf(_target_x - global_position.x)
	if absf(_target_x - global_position.x) <= 4.0:
		_pick_new_target()
		return
	global_position.x += dir * wander_speed * delta
	sprite.flip_h = dir < 0.0

func _pick_new_target() -> void:
	_target_x = _base_x + randf_range(-wander_radius, wander_radius)

func _handle_jump(delta: float) -> void:
	_jump_timer -= delta
	if _jump_timer <= 0.0:
		_jump_timer = randf_range(jump_interval_min, jump_interval_max)
		_do_jump()

func _do_jump() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "position:y", _visual_y - jump_height, jump_duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position:y", _visual_y, jump_duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _on_body_entered(body: Node2D) -> void:
	if is_hugged or not body is Luke:
		return
	is_hugged = true
	if happy_texture != null:
		sprite.texture = happy_texture
	heart.visible = true
	var tween := create_tween()
	sprite.scale *= 1.0
	tween.tween_property(sprite, "scale", sprite.scale * 1.25, 0.12)
	tween.tween_property(sprite, "scale", sprite.scale, 0.12)
	AudioDirector.play_event(&"hug")
	hugged.emit(self)

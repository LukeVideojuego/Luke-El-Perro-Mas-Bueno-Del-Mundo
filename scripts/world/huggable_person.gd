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

## Segunda pose (piernas separadas) para el ciclo de caminata mientras
## deambula; sin asignar, no anima piernas (queda con la pose fija).
@export var walk_texture: Texture2D
@export var walk_frame_time := 0.22

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
var _idle_texture: Texture2D
var _walk_cycle_time := 0.0
var _walk_frame_on := false

func _ready() -> void:
	_base_x = global_position.x
	_visual_y = sprite.position.y
	_idle_texture = sprite.texture
	if wander_enabled:
		_pick_new_target()
		_jump_timer = randf_range(jump_interval_min, jump_interval_max)

func _process(delta: float) -> void:
	if not wander_enabled or is_hugged:
		return
	_handle_wander(delta)
	_handle_jump(delta)

## Por debajo de esta velocidad, Luke se considera "quieto": si una persona
## que deambula (wander_enabled) camina y choca contra un Luke inmóvil, NO
## cuenta como abrazo por sí solo. Se revisa en cada frame de físicas
## mientras se solapan (no solo en el instante de contacto) para que, si
## Luke arranca a moverse mientras siguen tocándose, el abrazo sí cuente en
## cuanto supere el umbral. Sin esto, el objetivo del minijuego podía darse
## por cumplido sin que el jugador hiciera nada (bug reportado: el cartel de
## nivel completado aparecía igual aunque Luke no se moviera).
const MIN_LUKE_SPEED_TO_HUG := 20.0

func _physics_process(_delta: float) -> void:
	if is_hugged:
		return
	for body in get_overlapping_bodies():
		if body is Luke and body.velocity.length() >= MIN_LUKE_SPEED_TO_HUG:
			_do_hug(body)
			return

func _handle_wander(delta: float) -> void:
	var dir := signf(_target_x - global_position.x)
	if absf(_target_x - global_position.x) <= 4.0:
		_pick_new_target()
		_update_walk_animation(0.0, false)
		return
	global_position.x += dir * wander_speed * delta
	sprite.flip_h = dir < 0.0
	_update_walk_animation(delta, true)

## Mismo ciclo de 2 poses que enemy_base.gd, adaptado a la deambulación
## (una sola velocidad wander_speed, sin patrol_speed variable).
func _update_walk_animation(delta: float, moving: bool) -> void:
	if walk_texture == null:
		return
	if not moving:
		_walk_cycle_time = 0.0
		_walk_frame_on = false
		sprite.texture = _idle_texture
		return
	_walk_cycle_time += delta
	if _walk_cycle_time >= walk_frame_time:
		_walk_cycle_time = 0.0
		_walk_frame_on = not _walk_frame_on
		sprite.texture = walk_texture if _walk_frame_on else _idle_texture

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

func _do_hug(_body: Node2D) -> void:
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

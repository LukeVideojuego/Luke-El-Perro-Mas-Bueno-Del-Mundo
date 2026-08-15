class_name MovingPlatform
extends AnimatableBody2D

## Plataforma móvil que Luke puede pisar. Se mueve en vaivén entre su
## posición inicial y start_position + travel, a lo largo del eje elegido.

@export var travel := Vector2(220.0, 0.0)
@export var speed := 90.0

var _start_position := Vector2.ZERO
var _direction := 1.0
var _distance_traveled := 0.0

func _ready() -> void:
	sync_to_physics = true
	_start_position = position

func _physics_process(delta: float) -> void:
	var total_distance := travel.length()
	if total_distance <= 0.0:
		return
	var step := speed * delta
	_distance_traveled += step * _direction
	if _distance_traveled >= total_distance:
		_distance_traveled = total_distance
		_direction = -1.0
	elif _distance_traveled <= 0.0:
		_distance_traveled = 0.0
		_direction = 1.0
	var t := _distance_traveled / total_distance
	position = _start_position + travel * t

class_name BirdPoop
extends Area2D

## Caca que un ave suelta en pleno vuelo: cae recto hacia abajo y desaparece
## al tocar el suelo, expirar su tiempo de vida, o golpear a Luke.

@export var fall_speed := 240.0
@export var lifetime := 3.0

var _time_alive := 0.0
var _thrower: Node = null

func launch(from_position: Vector2, thrower: Node) -> void:
	global_position = from_position
	_thrower = thrower

func _physics_process(delta: float) -> void:
	position.y += fall_speed * delta
	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Luke:
		var source: Node2D = _thrower if is_instance_valid(_thrower) else null
		body.receive_damage(source)
		queue_free()
	elif body is StaticBody2D:
		queue_free()

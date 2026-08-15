class_name ThrownBone
extends Area2D

## Proyectil de munición ilimitada que Luke lanza al desbloquear los
## huesitos. Recorre una distancia máxima y derrota al primer enemigo
## que impacte, igual que el ataque cuerpo a cuerpo.

@export var speed := 620.0
@export var lifetime := 1.8

var direction := 1.0
var _thrower: Node = null
var _time_alive := 0.0

func launch(from_position: Vector2, dir: float, thrower: Node) -> void:
	global_position = from_position
	direction = dir
	_thrower = thrower
	scale.x = direction
	rotation = 0.0

func _physics_process(delta: float) -> void:
	position.x += speed * direction * delta
	rotation += 14.0 * delta * direction
	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("receive_attack"):
		body.receive_attack(_thrower)
		queue_free()

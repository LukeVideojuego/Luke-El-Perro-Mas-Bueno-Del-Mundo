class_name EnemyProjectile
extends Area2D

## Proyectil genérico reutilizado por varios enemigos (piedra, maletín,
## aguijón, etc.), solo cambia el sprite/tamaño por escena. Daña a Luke
## al impactar y desaparece tras un tiempo de vida o al chocar con el
## entorno.

@export var speed := 340.0
@export var lifetime := 2.2

var direction := 1.0
var _thrower: Node = null
var _time_alive := 0.0

func launch(from_position: Vector2, dir: float, thrower: Node) -> void:
	global_position = from_position
	direction = dir
	_thrower = thrower
	scale.x = absf(scale.x) * direction

func _physics_process(delta: float) -> void:
	position.x += speed * direction * delta
	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Luke:
		# El enemigo que lo lanzó puede haber sido derrotado (queue_free) antes
		# de que el proyectil llegue a destino; en ese caso no pasar la
		# referencia inválida.
		var source: Node2D = _thrower if is_instance_valid(_thrower) else null
		body.receive_damage(source)
		queue_free()
	elif body is StaticBody2D:
		queue_free()

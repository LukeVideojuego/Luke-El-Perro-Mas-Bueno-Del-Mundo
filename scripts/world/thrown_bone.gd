class_name ThrownBone
extends Area2D

## Proyectil de munición ilimitada que Luke lanza al desbloquear los
## huesitos. Recorre una distancia máxima y derrota al primer enemigo
## que impacte, igual que el ataque cuerpo a cuerpo.

@export var speed := 620.0
@export var lifetime := 1.8

## A2: antes esto quedaba implicito (no se pasaba "amount", asi que
## receive_attack() caia en su default=1). Lo hacemos un numero con nombre
## para que bark_wave.gd pueda definir su propio daño COMO multiplo de este
## en vez de un "3" suelto que coincide con el valor del huesito de pura
## casualidad -- si este numero cambia algun dia, el ladrido lo sigue
## automaticamente.
const DAMAGE := 1

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
	_try_hit(body)

## B7: la caja receptora de los jefes es un Area2D (no un cuerpo), porque el
## cuerpo fisico del jefe es chico y esta abajo de todo. Sin esto el huesito
## solo le pegaba al jefe en las piernas.
func _on_area_entered(area: Area2D) -> void:
	_try_hit(area)

func _try_hit(target: Node) -> void:
	if target != null and target.has_method("receive_attack"):
		target.receive_attack(_thrower, DAMAGE)
		queue_free()

class_name BarkWave
extends Area2D

## C3: "Ladrido de onda expansiva", el poder de ataque nuevo que se compra en
## la tienda. Comparado con el huesito: va mucho mas rapido (980 contra 620),
## atraviesa en vez de desaparecer con el primer impacto, y pega a todo lo que
## toca en el camino (incluidas las cajas y la hurtbox de los jefes).
##
## Tiene municion limitada: cada disparo gasta una carga comprada, y cuando se
## acaban Luke vuelve a tirar huesitos.

@export var speed := 980.0
@export var lifetime := 0.85
## Crece mientras avanza, como una onda que se expande.
@export var growth := 1.6

var direction := 1.0
var _thrower: Node = null
var _time_alive := 0.0
## Un objetivo recibe un solo impacto por onda, aunque la atraviese entera.
var _already_hit: Array[int] = []

func launch(from_position: Vector2, dir: float, thrower: Node) -> void:
	global_position = from_position
	direction = dir
	_thrower = thrower
	scale = Vector2(direction, 1.0)

func _physics_process(delta: float) -> void:
	position.x += speed * direction * delta
	_time_alive += delta
	var t: float = clampf(_time_alive / lifetime, 0.0, 1.0)
	scale = Vector2(direction * (1.0 + growth * t), 1.0 + growth * t)
	modulate.a = 1.0 - t * 0.6
	if _time_alive >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	_try_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_try_hit(area)

func _try_hit(target: Node) -> void:
	if target == null or not target.has_method("receive_attack"):
		return
	var id: int = target.get_instance_id()
	if _already_hit.has(id):
		return
	_already_hit.append(id)
	target.receive_attack(_thrower)

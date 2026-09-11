class_name FishHook
extends Area2D

## Anzuelo del nivel de mar (Mundo 4, nivel del mar): baja en línea recta
## desde arriba de la pantalla hasta el piso, a la misma velocidad de caída
## que la caca de las aves (ver bird_poop.gd fall_speed). Reemplaza a las
## aves en este nivel específico, ya que no tiene sentido que haya aves bajo
## el agua. Tiene una tanza visible (Line2D) que lo conecta con el punto
## donde "entró" al agua, y desaparece al tocar el piso, a Luke, o vencer su
## tiempo de vida.

@export var fall_speed := 240.0
@export var lifetime := 6.0

@onready var line: Line2D = $Line2D

var _spawn_y := 0.0
var _time_alive := 0.0

func _ready() -> void:
	_spawn_y = global_position.y

func _physics_process(delta: float) -> void:
	position.y += fall_speed * delta
	line.set_point_position(1, Vector2(0, _spawn_y - global_position.y))
	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Luke:
		body.receive_damage(self)
		queue_free()
	elif body is StaticBody2D:
		queue_free()

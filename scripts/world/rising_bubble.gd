extends Node2D

## Burbuja cosmética que sube y se desvanece; usada como estela detrás de
## Luke en los niveles subacuáticos y por cualquier otro emisor decorativo.

@export var rise_speed := 55.0
@export var wobble_amplitude := 6.0
@export var wobble_speed := 3.0
@export var lifetime := 1.6

var _time := 0.0
var _start_x := 0.0

func _ready() -> void:
	_start_x = position.x

func _process(delta: float) -> void:
	_time += delta
	position.y -= rise_speed * delta
	position.x = _start_x + sin(_time * wobble_speed) * wobble_amplitude
	var t := _time / lifetime
	modulate.a = clampf(1.0 - t, 0.0, 1.0)
	if _time >= lifetime:
		queue_free()

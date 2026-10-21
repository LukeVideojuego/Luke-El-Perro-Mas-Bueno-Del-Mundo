class_name CapeRibbon
extends Node2D

## E3: capa roja de la tienda con movimiento REAL (no 2 poses fijas).
##
## Es una cadena de puntos simulada con integracion de Verlet (la misma
## tecnica clasica para telas/cuerdas): el primer punto queda CLAVADO al
## lomo de Luke (se actualiza cada frame siguiendo su posicion/orientacion
## real), y el resto de los puntos cuelga de el con inercia propia. Eso
## solo, sin "poses" a mano, ya da los 4 comportamientos pedidos como
## consecuencia natural de la fisica:
##  - Quieto: la cadena cae recta por gravedad.
##  - Corriendo: la inercia hace que los puntos de atras se queden
##    rezagados respecto al anclaje que se mueve rapido -> flamea hacia
##    atras.
##  - Subiendo en un salto: el anclaje sube rapido, la cadena se queda
##    rezagada ABAJO Y ATRAS -> se estira hacia atras y arriba relativo a
##    Luke, que es como se ve una capa en un salto.
##  - Cayendo: el cambio de velocidad (de subir a caer) sacude la cadena,
##    que ondula unos frames hasta reacomodarse.
##
## Se dibuja como una tira angosta (triangulos) en vez de un sprite fijo,
## con el mismo paleta rojo/dorado del resto del arte de la tienda.

const SEGMENTS := 5
const SEGMENT_LEN := 9.0
## Cercano a la gravedad real de Luke (1900, ver luke.gd) a proposito: si la
## gravedad local de la capa es mucho mas chica que la de Luke, la capa queda
## "atras" (relativamente arriba) de forma indefinida en CUALQUIER caida
## sostenida (no solo en el instante del salto), porque Luke acelera hacia
## abajo mas rapido de lo que la capa puede seguir -- eso hacia que "subiendo"
## y "cayendo" se vieran identicos (la capa siempre estirada hacia arriba).
## Con un valor cercano al de Luke, la capa SOLO se atrasa (estira) durante el
## pico brusco del salto (aceleracion relativa grande y breve) y despues, en
## una caida sostenida, se reacomoda y cuelga/ondula detras como corresponde.
const GRAVITY := 1650.0
## La inercia pura (sin esto) hace que la capa SIEMPRE quede "atrasada" en
## contra del sentido en que acelera Luke -- al saltar (acelera hacia
## arriba) la capa se atrasa hacia ABAJO, y al caer mucho tiempo a velocidad
## sostenida, se atrasa hacia ARRIBA (ver comentario de GRAVITY). Fisicamente
## correcto, pero es el ESPEJO de lo que se pidio (atras-y-arriba al saltar,
## ondulando al caer): el look de "capa de heroe" que se busca es una
## estilizacion deliberada, no fisica real de un trapo pasivo. Para lograrlo
## sin tirar la simulacion de Verlet (que sigue dando bien el flameo al
## correr y el colgado recto en reposo), se suma una fuerza extra sobre la
## gravedad local proporcional a la velocidad vertical REAL de Luke: cuando
## sube rapido (velocity.y bien negativo) la gravedad efectiva de la capa
## baja (hasta hacerse ascendente), empujando la cola hacia arriba y atras;
## cuando cae rapido y sostenido, la gravedad efectiva sube mucho, así la
## cola es arrastrada hacia abajo en vez de quedar "pegada" apuntando para
## arriba indefinidamente.
const VERTICAL_LIFT := 20.0
const DRAG := 0.09
## Mas iteraciones = la cadena sigue el ancla con menos "atraso" cuando el
## ancla se mueve a velocidad CONSTANTE (como una caida ya a velocidad
## terminal) -- con pocas iteraciones, cada punto queda permanentemente
## unos frames "atras" de para donde se movio el ancla, y en una caida
## sostenida eso se acumula como si la capa siguiera flameando hacia arriba
## para siempre. Con mas iteraciones se reacomoda rapido a velocidad
## constante, pero un cambio BRUSCO de velocidad (el arranque del salto)
## sigue produciendo un latigazo de 1-2 frames porque ninguna cantidad de
## iteraciones puede anular una aceleracion instantanea grande.
const CONSTRAINT_ITER := 14
## Ancho de la capa en cada punto de la cadena (se angosta hacia la punta).
const WIDTHS := [22.0, 20.0, 16.0, 12.0, 7.0, 2.0]

const CAPE_COLOR := Color(0.808, 0.188, 0.220, 1.0)
const CAPE_COLOR_DARK := Color(0.600, 0.110, 0.157, 1.0)
const CAPE_TRIM := Color(0.969, 0.796, 0.243, 1.0)

var _points: Array[Vector2] = []
var _prev_points: Array[Vector2] = []
var _anchor_offset := Vector2(-46.0, -2.0)
var _initialized := false

func _ready() -> void:
	top_level = true
	z_index = -1

func _physics_process(delta: float) -> void:
	var luke := get_parent()
	if luke == null or not (luke is Node2D):
		return
	var facing: float = luke.facing_direction if "facing_direction" in luke else 1.0
	var anchor: Vector2 = luke.global_position + Vector2(_anchor_offset.x * facing, _anchor_offset.y)
	var luke_vspeed: float = luke.velocity.y if "velocity" in luke else 0.0
	var effective_gravity: float = GRAVITY + VERTICAL_LIFT * luke_vspeed

	if not _initialized:
		_points.clear()
		_prev_points.clear()
		for i in range(SEGMENTS + 1):
			var p: Vector2 = anchor + Vector2(0.0, SEGMENT_LEN * i)
			_points.append(p)
			_prev_points.append(p)
		_initialized = true

	_points[0] = anchor

	# Verlet: cada punto sigue con su propia inercia (posicion - posicion
	# anterior), mas gravedad, mas un arrastre leve para que no oscile para
	# siempre.
	for i in range(1, _points.size()):
		var current: Vector2 = _points[i]
		var velocity: Vector2 = (current - _prev_points[i]) * (1.0 - DRAG)
		var next: Vector2 = current + velocity + Vector2(0.0, effective_gravity * delta * delta)
		_prev_points[i] = current
		_points[i] = next

	# Restriccion de distancia: mantiene cada segmento a SEGMENT_LEN del
	# anterior (el punto 0 esta clavado, nunca se mueve en este paso).
	for _iter in range(CONSTRAINT_ITER):
		for i in range(1, _points.size()):
			var a: Vector2 = _points[i - 1]
			var b: Vector2 = _points[i]
			var delta_v: Vector2 = b - a
			var dist: float = maxf(delta_v.length(), 0.001)
			var diff: float = (dist - SEGMENT_LEN) / dist
			if i == 1:
				_points[i] = b - delta_v * diff
			else:
				_points[i - 1] = a + delta_v * diff * 0.5
				_points[i] = b - delta_v * diff * 0.5

	queue_redraw()

func _draw() -> void:
	if _points.size() < 2:
		return
	for i in range(_points.size() - 1):
		var a: Vector2 = to_local(_points[i])
		var b: Vector2 = to_local(_points[i + 1])
		var wa: float = WIDTHS[mini(i, WIDTHS.size() - 1)] * 0.5
		var wb: float = WIDTHS[mini(i + 1, WIDTHS.size() - 1)] * 0.5
		var dir: Vector2 = (b - a).normalized() if a != b else Vector2.DOWN
		var normal := Vector2(-dir.y, dir.x)
		var quad := PackedVector2Array([a - normal * wa, a + normal * wa, b + normal * wb, b - normal * wb])
		var col: Color = CAPE_COLOR if i % 2 == 0 else CAPE_COLOR_DARK
		draw_colored_polygon(quad, col)
		if i == 0:
			# Ribete dorado del cuello, siempre en el primer segmento.
			var trim := PackedVector2Array([a - normal * wa, a + normal * wa,
				a + dir * 4.0 + normal * wa, a + dir * 4.0 - normal * wa])
			draw_colored_polygon(trim, CAPE_TRIM)

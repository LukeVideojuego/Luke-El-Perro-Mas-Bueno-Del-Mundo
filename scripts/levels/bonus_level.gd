class_name BonusLevel
extends Node2D

## B1/B2: controlador compartido de los niveles bonus (4 de B1 + el
## minijuego final de B2 reusa el mismo patron de barras/premios, aunque no
## este script en particular). main.gd reparenta al Luke real ac adentro
## (mismas estadisticas/cosmeticos, no una copia), lo posiciona en
## LukeStart, y escucha "finished" para devolverlo al nivel real.
##
## Caer (tocar FallBoundary) termina el bonus SIN penalidad (no pierde
## vida); si hay FinishMarker, llegar hasta el tambien lo termina (ya con
## todos los premios del camino juntados).

signal finished

@export var wind_force := Vector2.ZERO

@onready var luke_start: Marker2D = $LukeStart
@onready var fall_boundary: Area2D = $FallBoundary
@onready var finish_marker: Area2D = get_node_or_null("FinishMarker")
@onready var camera: Camera2D = $Camera2D

var luke: Luke = null
var _finished := false

func _ready() -> void:
	fall_boundary.body_entered.connect(_on_fall)
	if finish_marker != null:
		finish_marker.body_entered.connect(_on_finish)

## Llamado por main.gd justo despues de reparentar a Luke adentro.
func start(luke_node: Luke) -> void:
	luke = luke_node
	luke.global_position = luke_start.global_position
	luke.velocity = Vector2.ZERO
	luke.jumps_used = 0
	camera.global_position = luke.global_position
	camera.make_current()

func _physics_process(_delta: float) -> void:
	if luke == null or _finished:
		return
	# Camara simple: sigue a Luke, sin limites (los niveles bonus son cortos
	# y van siempre hacia adelante).
	camera.global_position = camera.global_position.lerp(luke.global_position, 0.12)
	if wind_force != Vector2.ZERO:
		luke.velocity += wind_force * _delta

func _on_fall(body: Node2D) -> void:
	if body is Luke and not _finished:
		_finish()

func _on_finish(body: Node2D) -> void:
	if body is Luke and not _finished:
		_finish()

func _finish() -> void:
	_finished = true
	finished.emit()

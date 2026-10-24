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
	_apply_camera_limits()

func _physics_process(_delta: float) -> void:
	if luke == null or _finished:
		return
	# B1: la camara sigue a Luke libremente en X (los niveles bonus van
	# siempre hacia adelante), pero en Y queda limitada al fondo real
	# (_apply_camera_limits) para que un salto alto o una caida no saquen
	# a la camara de la zona que el fondo cubre y se vea gris.
	camera.global_position = camera.global_position.lerp(luke.global_position, 0.12)
	if wind_force != Vector2.ZERO:
		luke.velocity += wind_force * _delta

## B1: antes la camara no tenia limites -- un salto alto o una caida
## dejaban ver mas alla de donde llega el fondo (zona gris). Mismo
## criterio que level_base.gd._apply_camera_limits(): la camara nunca
## puede mostrar nada fuera del rectangulo real del fondo.
func _apply_camera_limits() -> void:
	var background := _compute_background_rect()
	if background.size.y <= 0.0:
		return
	camera.limit_top = int(background.position.y)
	camera.limit_bottom = int(background.position.y + background.size.y)
	camera.limit_left = int(background.position.x)
	camera.limit_right = int(background.position.x + background.size.x)

func _compute_background_rect() -> Rect2:
	var tiles: Array[Sprite2D] = []
	for child in get_children():
		if child is Sprite2D and String(child.name).begins_with("Background"):
			tiles.append(child)
	if tiles.is_empty():
		return Rect2()
	var result := Rect2()
	var first := true
	for tile in tiles:
		if tile.texture == null:
			continue
		var size: Vector2 = tile.texture.get_size() * tile.global_scale
		var origin: Vector2 = tile.global_position
		if tile.centered:
			origin -= size * 0.5
		var rect := Rect2(origin, size)
		result = rect if first else result.merge(rect)
		first = false
	return result

func _on_fall(body: Node2D) -> void:
	if body is Luke and not _finished:
		_finish()

func _on_finish(body: Node2D) -> void:
	if body is Luke and not _finished:
		_finish()

func _finish() -> void:
	_finished = true
	finished.emit()

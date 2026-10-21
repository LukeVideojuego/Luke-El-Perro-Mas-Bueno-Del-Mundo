class_name WoodPost
extends Node2D

## B1: prolonga el poste de madera de carteles, banderas de meta, carteles de
## salida y checkpoints HASTA EL PISO REAL, con una base/terminacion.
##
## El arte original (sign.png, flag_green_a.png, flag_off.png...) son tiles de
## 64x64 pensados para apilarse: traen solo un muncon de poste que termina
## seco en el borde inferior del tile. Puestos sueltos en un nivel se ven
## como "un cartel de madera flotando del que solo se ve la parte de arriba,
## sin terminacion", que es exactamente lo que el usuario venia reportando.
##
## En vez de hardcodear un largo por nivel (que se desincroniza en cuanto se
## mueve algo), el poste se mide en runtime con un raycast hacia abajo contra
## la geometria solida: funciona igual en un piso a y=905 que arriba de una
## isla a y=810.

## Donde arranca el poste, en y local. Conviene solapar unos pixeles con el
## muncon del sprite para que no se vea la union.
@export var post_top := 24.0
## Ancho de la madera (sin contar el contorno).
@export var post_width := 16.0
## Desplazamiento horizontal del poste respecto al origen del nodo.
@export var post_offset_x := 0.0
@export var max_length := 900.0
@export var base_width := 44.0
@export var base_height := 14.0

const WOOD := Color(0.776, 0.416, 0.243)
const WOOD_LIGHT := Color(0.871, 0.494, 0.310)
const WOOD_DARK := Color(0.596, 0.302, 0.169)
const OUTLINE := Color(0.208, 0.208, 0.255)
const OUTLINE_PX := 4.0

var measured_length := 0.0

func _ready() -> void:
	z_index = -1
	# El espacio fisico no esta listo durante el _ready() del arbol, asi que
	# el raycast se hace en el primer frame de fisica.
	await get_tree().physics_frame
	_build()

func _build() -> void:
	var scale_y: float = maxf(0.001, global_scale.y)
	var start := global_position + Vector2(post_offset_x * global_scale.x, post_top * scale_y)
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(start, start + Vector2(0.0, max_length * scale_y))
	query.collision_mask = 1
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		push_warning("WoodPost en %s: no encontre piso debajo, no dibujo el poste" % str(global_position))
		return
	measured_length = (hit.position.y - start.y) / scale_y
	if measured_length <= 2.0:
		return
	var bottom := post_top + measured_length
	var half := post_width * 0.5
	var half_out := half + OUTLINE_PX
	_rect(post_offset_x - half_out, post_top, half_out * 2.0, measured_length, OUTLINE)
	_rect(post_offset_x - half, post_top, post_width, measured_length, WOOD)
	_rect(post_offset_x - half, post_top, 4.0, measured_length, WOOD_LIGHT)
	_rect(post_offset_x + half - 4.0, post_top, 4.0, measured_length, WOOD_DARK)
	# Terminacion: una base apoyada en el piso para que no corte en seco.
	var bhalf := base_width * 0.5
	_rect(post_offset_x - bhalf - OUTLINE_PX, bottom - base_height - OUTLINE_PX,
		(bhalf + OUTLINE_PX) * 2.0, base_height + OUTLINE_PX * 2.0, OUTLINE)
	_rect(post_offset_x - bhalf, bottom - base_height, base_width, base_height, WOOD)
	_rect(post_offset_x - bhalf, bottom - base_height, base_width, 4.0, WOOD_LIGHT)

func _rect(x: float, y: float, w: float, h: float, color: Color) -> void:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h)])
	poly.color = color
	add_child(poly)

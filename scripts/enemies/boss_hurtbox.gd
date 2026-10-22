class_name BossHurtbox
extends Area2D

## B7: caja receptora de golpes de los jefes.
##
## Problema: el CollisionShape2D del CharacterBody2D de cada jefe es su cuerpo
## FISICO (lo que apoya en el piso), y por eso es chiquito y esta abajo de
## todo: 32x51 en Don Sombra para un sprite de ~230px de alto. Como el ataque
## de Luke detectaba contra ese cuerpo, solo contaba si el golpe llegaba a la
## parte de abajo del jefe. Agrandar el cuerpo fisico no sirve: cambiaria como
## el jefe pisa el piso y como choca contra las plataformas (ya hubo un bug de
## jefes trabados por exactamente eso).
##
## Solucion: una caja receptora aparte que cubre TODA la silueta visible del
## sprite y le reenvia el golpe al jefe. Se re-ajusta en cada frame de fisica
## al rectangulo opaco real de la textura que el jefe este mostrando, asi
## acompana automaticamente las poses (quieto, caminando, saltando, atacando),
## que tienen tamanos y encuadres distintos.
##
## E6: el CharacterBody2D del jefe (su cuerpo FISICO) tenia collision_layer=4
## igual que esta hurtbox, que es la misma layer que escuchan el golpe
## cuerpo a cuerpo, el huesito y el ladrido de onda. Eso hacia que un solo
## golpe cuerpo a cuerpo contara 3 VECES contra el mismo jefe: una por la
## señal body_entered del AttackArea de Luke contra el cuerpo fisico, y dos
## mas porque intersect_shape() (collide_with_bodies Y collide_with_areas)
## encontraba AMBOS colisionadores (cuerpo fisico + esta hurtbox) en la
## misma consulta -- cada uno con su propio instance_id, asi que el
## deduplicado de Luke (uno por id) no los agarraba como repetidos. Medido:
## 15 de vida -> 12 con UN solo golpe. El huesito no tenia el bug (se
## autodestruye en el primer impacto). Fix: el cuerpo fisico del jefe ya NO
## esta en layer 4 (ver cada escena de jefe) -- SOLO esta hurtbox lo esta,
## asi que cualquier ataque pega una unica vez por golpe, como corresponde.

@export var sprite_path: NodePath = ^"../Sprite2D"
## Margen extra alrededor de la silueta, en pixeles de pantalla.
@export var padding := 6.0

var _sprite: Sprite2D
var _shape_node: CollisionShape2D
var _rect: RectangleShape2D
## Rect opaco de cada textura ya calculado (get_image() es caro para hacerlo
## en cada frame, pero las poses son 2 o 4 por jefe).
var _used_rects := {}

func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	monitoring = false
	monitorable = true
	_sprite = get_node_or_null(sprite_path) as Sprite2D
	_rect = RectangleShape2D.new()
	_rect.size = Vector2(40.0, 40.0)
	_shape_node = CollisionShape2D.new()
	_shape_node.shape = _rect
	add_child(_shape_node)
	_fit_to_sprite()

func _physics_process(_delta: float) -> void:
	_fit_to_sprite()

## Reenvia el golpe al jefe. Luke, el huesito y el ladrido de onda llaman
## receive_attack() sobre lo que impactan sin preguntar de que tipo es, asi
## que alcanza con tener el metodo aca. amount se reenvia tal cual (el
## ladrido manda 3, el resto no manda nada y cae en el 1 default).
func receive_attack(attacker: Node = null, amount: int = 1) -> void:
	var boss := get_parent()
	if boss != null and boss.has_method("receive_attack"):
		boss.receive_attack(attacker, amount)

func _fit_to_sprite() -> void:
	if _sprite == null or _sprite.texture == null or _rect == null:
		return
	var tex_size: Vector2 = _sprite.texture.get_size()
	var used: Rect2 = _opaque_rect(_sprite.texture)
	if _sprite.flip_h:
		used.position.x = tex_size.x - used.position.x - used.size.x
	if _sprite.flip_v:
		used.position.y = tex_size.y - used.position.y - used.size.y
	var spr_scale := Vector2(absf(_sprite.scale.x), absf(_sprite.scale.y))
	# Sprite2D centrado: el centro de la textura cae en position + offset*scale.
	var tex_center: Vector2 = _sprite.position + _sprite.offset * _sprite.scale
	if not _sprite.centered:
		tex_center += tex_size * _sprite.scale * 0.5
	var top_left: Vector2 = tex_center - tex_size * spr_scale * 0.5
	var size: Vector2 = used.size * spr_scale + Vector2(padding, padding) * 2.0
	var center: Vector2 = top_left + (used.position + used.size * 0.5) * spr_scale
	_rect.size = size
	_shape_node.position = center

func _opaque_rect(texture: Texture2D) -> Rect2:
	if _used_rects.has(texture):
		return _used_rects[texture]
	var result := Rect2(Vector2.ZERO, texture.get_size())
	var image := texture.get_image()
	if image != null:
		var used := image.get_used_rect()
		if used.size.x > 0 and used.size.y > 0:
			result = Rect2(used.position, used.size)
	_used_rects[texture] = result
	return result

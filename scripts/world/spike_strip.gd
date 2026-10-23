class_name SpikeStrip
extends Area2D

## Tramo de pinchos: un solo nodo que genera A LA VEZ los pinchos visibles y
## el area que hace dano, con exactamente el mismo ancho. Nacio del pedido
## "que no quede ninguna zona letal sin diseno visual" (Mundo 2): antes los
## pinchos (Sprite2D sueltos) y el dano (Area2D aparte) se escribian a mano
## en el .tscn y era facil que quedaran desalineados, o peor, que hubiera
## dano sin pinchos. Aca es imposible que se desincronicen.
##
## Convencion de posicion: el origen del nodo va EXACTAMENTE sobre la
## superficie del piso. Los pinchos se dibujan apenas por encima y el area
## letal arranca en la superficie, igual que el damage_zone.tscn original.

const SPIKE_TEXTURE := preload("res://assets/Tiles/Default/spikes.png")

@export var strip_width := 150.0
@export var spike_spacing := 50.0
@export var spike_scale := Vector2(1.5, 1.0)
## Alto del area letal medido hacia abajo desde la superficie del piso.
@export var hazard_height := 30.0
## Franja oscura de fondo para que los pinchos se lean contra cualquier piso.
@export var draw_backing := true

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	_build()
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

## F2: el area letal y los pinchos visibles se dibujaban hacia ABAJO desde el
## origen (pensado como "la superficie del piso"), es decir, HACIA ADENTRO
## del piso solido. Luke, parado o caminando, apoya los pies EXACTAMENTE en
## la superficie (nunca la atraviesa, el piso solido se lo impide), asi que
## el area letal y el origen quedaban tocandose en el borde sin solaparse
## nunca de verdad -- confirmado con fisica real (tests/diag_f2_spike_probe.
## gd): Luke se quedaba parado sobre pinchos sin perder vida nunca. Ahora
## todo el dibujo (pinchos, fondo oscuro, area letal) se espeja hacia
## ARRIBA desde la superficie, para que la punta del pincho entre de verdad
## en el espacio que ocupan los pies de Luke al pisarlo.
func _build() -> void:
	var half := strip_width * 0.5
	if draw_backing:
		var backing := Polygon2D.new()
		backing.polygon = PackedVector2Array([
			Vector2(-half, -2.0), Vector2(half, -2.0),
			Vector2(half, -hazard_height), Vector2(-half, -hazard_height)])
		backing.color = Color(0.15, 0.13, 0.13, 1.0)
		backing.z_index = -1
		add_child(backing)
	var count := maxi(1, int(round(strip_width / spike_spacing)))
	var step := strip_width / float(count)
	for i in range(count):
		var spike := Sprite2D.new()
		spike.texture = SPIKE_TEXTURE
		spike.scale = spike_scale
		spike.position = Vector2(-half + step * (float(i) + 0.5), -23.0)
		add_child(spike)
	var shape_node := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(strip_width, hazard_height)
	shape_node.shape = rect
	shape_node.position = Vector2(0.0, -hazard_height * 0.5)
	add_child(shape_node)

func _on_body_entered(body: Node2D) -> void:
	if body is Luke:
		body.receive_damage(self)

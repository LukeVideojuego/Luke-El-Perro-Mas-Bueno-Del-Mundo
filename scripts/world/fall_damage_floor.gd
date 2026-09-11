class_name FallDamageFloor
extends Area2D

## Franja invisible pegada al camino de piso de un nivel: si Luke la toca
## habiendo caído una distancia considerable desde donde estaba parado antes
## (p. ej. una plataforma aérea), pierde una vida. Saltar y volver a caer en
## el mismo piso no cuenta (last_fall_distance da ~0 en ese caso). Pedido
## puntualmente para "Corazones de Oro" (Mundo 2): el camino de arriba debe
## ser más seguro que el de abajo.
##
## Se revisa en _physics_process (en vez de solo en el signal body_entered)
## porque last_fall_distance recién queda actualizado dentro del propio
## _physics_process de Luke ese mismo frame; comprobarlo únicamente al
## entrar corre el riesgo de leer el valor todavía viejo según el orden de
## procesamiento del motor. receive_damage() ya tiene su propio cooldown de
## invulnerabilidad, así que revisar en cada frame mientras se solapan no
## dispara daño repetido.

@export var min_fall_height := 90.0

func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body is Luke and body.last_fall_distance >= min_fall_height:
			body.receive_damage(self)

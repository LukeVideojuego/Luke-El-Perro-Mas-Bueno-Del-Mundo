class_name BarkPickup
extends Area2D

## E6: caja escondida en la arena del jefe final que da municion del "ladrido
## de onda" (el poder de ataque de la tienda, C3) aunque no se haya comprado
## en la tienda -- asi la pelea sigue siendo dura incluso usandolo, porque
## son solo AMOUNT cargas y el daño por golpe es el mismo que el huesito (no
## hay atajo para bajar de las 10 pegadas minimas si se pelea solo con
## huesito, ver GRUPO B7 / boss_hurtbox.gd).

signal collected

@export var amount := 5

var is_collected := false

func _on_body_entered(body: Node2D) -> void:
	if is_collected or not body is Luke:
		return
	is_collected = true
	GameState.bark_ammo += amount
	AudioDirector.play_event(&"coin_pickup")
	collected.emit()
	queue_free()

class_name MeatPowerUp
extends Area2D

signal collected(player: Luke)

var is_collected := false

func _on_body_entered(body: Node2D) -> void:
	if is_collected or not body is Luke:
		return
	is_collected = true
	body.set_protective_aura(true)
	AudioDirector.play_event(&"meat_pickup")
	collected.emit(body)
	queue_free()

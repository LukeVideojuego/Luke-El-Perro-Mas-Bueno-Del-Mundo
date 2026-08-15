class_name SpeedPowerUp
extends Area2D

signal collected(player: Luke)

var is_collected := false

func _on_body_entered(body: Node2D) -> void:
	if is_collected or not body is Luke:
		return
	is_collected = true
	body.grant_speed_boost()
	AudioDirector.play_event(&"powerup_speed")
	collected.emit(body)
	queue_free()

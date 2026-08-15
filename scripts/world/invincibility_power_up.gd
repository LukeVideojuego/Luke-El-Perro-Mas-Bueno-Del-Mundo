class_name InvincibilityPowerUp
extends Area2D

signal collected(player: Luke)

var is_collected := false

func _on_body_entered(body: Node2D) -> void:
	if is_collected or not body is Luke:
		return
	is_collected = true
	body.grant_invincibility()
	AudioDirector.play_event(&"powerup_invincibility")
	collected.emit(body)
	queue_free()

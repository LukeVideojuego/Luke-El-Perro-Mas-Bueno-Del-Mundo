class_name BonePickup
extends Area2D

signal collected

var is_collected := false

func _on_body_entered(body: Node2D) -> void:
	if is_collected or not body is Luke:
		return
	is_collected = true
	GameState.unlock_bone_throw()
	AudioDirector.play_event(&"coin_pickup")
	collected.emit()
	queue_free()

class_name LevelCheckpoint
extends Area2D

@export var checkpoint_id := "checkpoint"
var is_activated := false

func _on_body_entered(body: Node2D) -> void:
	if is_activated or not body is Luke:
		return
	is_activated = true
	GameState.set_checkpoint(checkpoint_id, global_position + Vector2(0, -70))
	$Flag.modulate = Color(1.0, 1.0, 1.0, 1.0)

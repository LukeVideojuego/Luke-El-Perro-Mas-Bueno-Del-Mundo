class_name LevelCheckpoint
extends Area2D

## La bandera arranca apagada (grisada) y al tocarla se enciende y cambia a
## la segunda pose de tela, para que se lea claramente que es un checkpoint
## y que ya quedo activado.
const FLAG_ON := preload("res://assets/Tiles/Default/flag_blue_b.png")

@export var checkpoint_id := "checkpoint"
var is_activated := false

func _on_body_entered(body: Node2D) -> void:
	if is_activated or not body is Luke:
		return
	is_activated = true
	GameState.set_checkpoint(checkpoint_id, global_position + Vector2(0, -70))
	$Flag.texture = FLAG_ON
	$Flag.modulate = Color(1.0, 1.0, 1.0, 1.0)

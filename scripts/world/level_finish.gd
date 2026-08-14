class_name LevelFinish
extends Area2D

signal reached(player: Luke)

func _on_body_entered(body: Node2D) -> void:
	if not body is Luke or GameState.is_level_complete:
		return
	body.set_physics_process(false)
	AudioDirector.play_event(&"level_complete")
	GameState.complete_current_level()
	reached.emit(body)

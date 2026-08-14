extends CanvasLayer

## Menú inicial mínimo: comienza la aventura y muestra los controles.

signal start_requested

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		start_requested.emit()
		set_process_unhandled_input(false)

extends CanvasLayer

@onready var overlay: ColorRect = $Overlay
@onready var title_label: Label = $Overlay/Center/Title
@onready var detail_label: Label = $Overlay/Center/Detail

func play_completion(next_level_id: String) -> void:
	overlay.visible = true
	if next_level_id.is_empty():
		title_label.text = "¡JUEGO COMPLETADO!"
		detail_label.text = "Luke conquistó el corazón de toda la humanidad."
	else:
		title_label.text = "¡NIVEL COMPLETADO!"
		detail_label.text = "Preparando el siguiente rescate..." if not next_level_id.is_empty() else "Próximo desafío en preparación"
	overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.45)
	await tween.finished
	await get_tree().create_timer(1.25).timeout

func fade_out() -> void:
	if not overlay.visible:
		return
	overlay.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 0.4)
	await tween.finished
	overlay.visible = false

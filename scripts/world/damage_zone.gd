class_name DamageZone
extends Area2D

## Riesgo ambiental temporal: reutilizable para trampas y peligros futuros.
func _on_body_entered(body: Node2D) -> void:
	if body is Luke:
		body.receive_damage(self)

class_name GoldenPaw
extends Area2D

## A7: huella dorada coleccionable. Hay 3 por nivel regular (36 en total),
## cada una identificada por level_id + paw_index (0,1,2) para poder
## guardar cuales ya se encontraron y que no reaparezcan al reentrar al
## nivel. El progreso y los premios (10 monedas por completar las 3 de un
## nivel, el collar dorado gratis al juntar las 36) los maneja GameState.

signal collected

@export var level_id := ""
@export var paw_index := 0

func _ready() -> void:
	if GameState.has_paw(level_id, paw_index):
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if not body is Luke:
		return
	GameState.collect_paw(level_id, paw_index)
	AudioDirector.play_event(&"coin_pickup")
	collected.emit()
	queue_free()

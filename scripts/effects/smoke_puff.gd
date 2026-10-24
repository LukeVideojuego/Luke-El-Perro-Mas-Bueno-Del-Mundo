extends Node2D

## B3: nube de humo reusable para los efectos de jefe (fundido en sombras de
## Don Sombra, teletransporte de la Bruja del Olvido). Crece y se desvanece
## sola, despues se destruye.

@export var grow_to := 1.6
@export var duration := 0.5

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	sprite.scale = Vector2(0.6, 0.6)
	sprite.modulate.a = 0.9
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(grow_to, grow_to), duration)
	tween.tween_property(sprite, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(queue_free)

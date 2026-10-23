class_name DisappearingBar
extends StaticBody2D

## B1 (variante Mundo 3): la barra desaparece un instante despues de que
## Luke la pisa, y vuelve a aparecer un rato despues (por si Luke se cae y
## tiene que reintentar el mismo tramo).

@export var disappear_delay := 0.35
@export var respawn_delay := 1.6

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var detector: Area2D = $StepDetector

var _triggered := false

func _ready() -> void:
	detector.body_entered.connect(_on_stepped_on)

func _on_stepped_on(body: Node2D) -> void:
	if not body is Luke or _triggered:
		return
	_triggered = true
	await get_tree().create_timer(disappear_delay).timeout
	sprite.visible = false
	collision.set_deferred("disabled", true)
	await get_tree().create_timer(respawn_delay).timeout
	sprite.visible = true
	collision.set_deferred("disabled", false)
	_triggered = false

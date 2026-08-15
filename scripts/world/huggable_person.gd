class_name HuggablePerson
extends Area2D

## Persona a la que Luke puede abrazar en el minijuego final. Al contacto,
## cambia a una pose feliz y muestra un corazón flotante; no vuelve a
## reaccionar (cada persona cuenta una sola vez).

signal hugged(person: HuggablePerson)

@export var happy_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var heart: Label = $Heart

var is_hugged := false

func _on_body_entered(body: Node2D) -> void:
	if is_hugged or not body is Luke:
		return
	is_hugged = true
	if happy_texture != null:
		sprite.texture = happy_texture
	heart.visible = true
	var tween := create_tween()
	sprite.scale *= 1.0
	tween.tween_property(sprite, "scale", sprite.scale * 1.25, 0.12)
	tween.tween_property(sprite, "scale", sprite.scale, 0.12)
	AudioDirector.play_event(&"hug")
	hugged.emit(self)

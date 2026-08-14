class_name Interactable
extends Area2D

## Base para carteles, civiles y objetivos de misión interactuables.
signal interacted(player: Luke)
@export_multiline var interaction_text := ""

var nearby_player: Luke

@onready var hint_label: Label = get_node_or_null("HintLabel")

func _ready() -> void:
	if hint_label != null and not interaction_text.is_empty():
		hint_label.text = interaction_text

func _process(_delta: float) -> void:
	if nearby_player != null and Input.is_action_just_pressed("interact"):
		interacted.emit(nearby_player)

func _on_body_entered(body: Node2D) -> void:
	if body is Luke:
		nearby_player = body
		if hint_label != null:
			hint_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body == nearby_player:
		nearby_player = null
		if hint_label != null:
			hint_label.visible = false

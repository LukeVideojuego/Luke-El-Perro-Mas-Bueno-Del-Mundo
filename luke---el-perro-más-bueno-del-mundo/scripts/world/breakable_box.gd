class_name BreakableBox
extends StaticBody2D

## Caja rompible compatible con el hitbox de Luke y futuros ataques de enemigos.
@export var contents: PackedScene
@export var contents_offset := Vector2(0, -64)

var is_broken := false

func receive_attack(_attacker: Node) -> void:
	if is_broken:
		return
	is_broken = true
	$CollisionShape2D.set_deferred("disabled", true)
	$Sprite2D.visible = false
	if contents != null:
		var item := contents.instantiate()
		item.position = position + contents_offset
		get_parent().call_deferred("add_child", item)
	queue_free()

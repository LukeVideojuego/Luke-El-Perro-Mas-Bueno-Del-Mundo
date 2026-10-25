class_name SyringeProjectile
extends EnemyProjectile

## B3: la jeringa del veterinario malvado. No usa el daño generico de
## EnemyProjectile (que le saca un corazon a Luke) -- en vez de eso aplica
## el efecto "gordo" (ver Luke.apply_fat_effect): no quita vidas, pero lo
## hace caminar mas lento y no poder correr durante unos segundos.

func _on_body_entered(body: Node2D) -> void:
	if body is Luke:
		body.apply_fat_effect()
		queue_free()
	elif body is StaticBody2D:
		queue_free()

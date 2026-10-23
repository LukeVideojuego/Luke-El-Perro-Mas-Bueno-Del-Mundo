extends Node2D

## F2 (investigacion): confirma si Luke puede tocar de verdad el area de
## dano de los "pinchos de piso" (SpikeHazardOne etc, instancias de
## damage_zone.tscn) parado/caminando normalmente, o si el piso solido
## por encima se lo impide (hazard "enterrado" bajo el piso caminable).

const LEVEL := preload("res://scenes/levels/world_2_level_2.tscn")

func _ready() -> void:
	var level: Node = LEVEL.instantiate()
	add_child(level)
	await get_tree().physics_frame
	var luke: Luke = level.get_node("Luke")
	var hazard: Node2D = level.get_node("SpikeHazardOne")
	print("SpikeHazardOne global_position=", hazard.global_position)
	var hazard_shape: CollisionShape2D = hazard.get_node("CollisionShape2D")
	print("hazard shape rect (local)=", hazard_shape.position, " size=", hazard_shape.shape.size)
	print("  -> area letal en MUNDO: y=[",
		hazard.global_position.y + hazard_shape.position.y - hazard_shape.shape.size.y / 2.0, ",",
		hazard.global_position.y + hazard_shape.position.y + hazard_shape.shape.size.y / 2.0, "]")

	# Caminar a Luke hasta pararse justo arriba del hazard, con fisica real
	# (gravedad normal), y ver si choca contra algo solido ANTES de llegar
	# a la altura del area de dano.
	luke.global_position = Vector2(hazard.global_position.x, 400.0)
	luke.velocity = Vector2.ZERO
	print("vidas ANTES=", GameState.lives)
	for i in range(180):
		await get_tree().physics_frame
		if i % 20 == 0:
			print("  t=", i, " y=", luke.global_position.y, " on_floor=", luke.is_on_floor(),
				" vidas=", GameState.lives, " can_receive_damage=", luke.can_receive_damage)
	print("Luke se asento en y=", luke.global_position.y, " on_floor=", luke.is_on_floor(),
		" vidas DESPUES=", GameState.lives)
	print("  (si Luke quedo MAS ARRIBA que el area letal, el piso solido se la tapa)")
	get_tree().quit()

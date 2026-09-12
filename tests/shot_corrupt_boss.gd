extends Node2D

const LEVEL := preload("res://scenes/levels/world_3_boss.tscn")
var level: Node
var boss: Node
var sprite: Sprite2D
var frame := 0
var cam: Camera2D

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	level = LEVEL.instantiate()
	add_child(level)
	boss = level.get_node("CorruptBoss")
	sprite = boss.get_node("Sprite2D")
	cam = Camera2D.new()
	cam.zoom = Vector2(1.0, 1.0)
	add_child(cam)
	cam.make_current()

func _physics_process(_delta: float) -> void:
	frame += 1
	cam.position = boss.global_position + Vector2(0, -150)
	if frame == 10:
		# IDLE: forzar reposo total.
		boss.velocity = Vector2.ZERO
		sprite.texture = boss._idle_texture
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shot_corrupt_idle.png")
		print("SAVED idle")
	if frame == 20:
		# CAMINATA: forzar pose de caminata.
		sprite.texture = boss.walk_texture
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shot_corrupt_walk.png")
		print("SAVED walk")
	if frame == 30:
		# SALTO: forzar pose de salto.
		sprite.texture = boss.jump_texture
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shot_corrupt_jump.png")
		print("SAVED jump")
	if frame == 40:
		# ATAQUE: disparar de verdad el poder al ras del piso (billetes) y
		# capturar la pose + el proyectil ya en vuelo en el mismo instante.
		boss._power_use_diagonal = false
		boss._fire_power()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shot_corrupt_power.png")
		print("SAVED power pose tex=", sprite.texture.resource_path)
	if frame == 45:
		var found := false
		for c in level.get_children():
			if c.name.begins_with("BillsProjectile"):
				found = true
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shot_corrupt_bills.png")
		print("SAVED bills projectile shot, found_in_tree=", found)
	if frame >= 50:
		get_tree().quit()

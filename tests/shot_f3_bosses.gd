extends Node2D

## F3: captura real (no-headless) de los 4 jefes uno al lado del otro, con
## Luke de referencia de escala, para confirmar que son visual y
## mecanicamente distintos (sprite, tamano) y medir su altura real en
## pantalla contra la regla pedida (2.5 / 3.5 / 4.5 / 5.5 m, Luke=1m).

const LUKE_SCENE := preload("res://scenes/player/player.tscn")
const BOSSES := [
	{"name": "Don Sombra (Mundo 1)", "path": "res://scenes/enemies/thief_boss.tscn", "target_m": 2.5},
	{"name": "La Bruja del Olvido (Mundo 2)", "path": "res://scenes/enemies/witch_boss.tscn", "target_m": 3.5},
	{"name": "El Gran Codicia (Mundo 3)", "path": "res://scenes/enemies/corrupt_boss.tscn", "target_m": 4.5},
	{"name": "La Serpiente (Mundo 4)", "path": "res://scenes/enemies/serpent_boss.tscn", "target_m": 5.5},
]
const FLOOR_Y := 900.0
const METER_PX := 94.7

func _ready() -> void:
	get_window().size = Vector2i(1700, 750)
	var ground := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(3200, 80)
	shape.shape = rect
	ground.add_child(shape)
	ground.position = Vector2(850, FLOOR_Y + 40)
	ground.collision_layer = 1
	add_child(ground)

	var xs := [150, 550, 950, 1350]
	for i in range(BOSSES.size()):
		var info = BOSSES[i]
		var boss: Node2D = load(info.path).instantiate()
		boss.position = Vector2(xs[i], FLOOR_Y - 200)
		add_child(boss)
		await get_tree().physics_frame
		boss.set_physics_process(false)
		boss.velocity = Vector2.ZERO
		var body_shape: CollisionShape2D = boss.get_node_or_null("CollisionShape2D")
		if body_shape != null and body_shape.shape is RectangleShape2D:
			boss.global_position.y = FLOOR_Y - (body_shape.position.y + body_shape.shape.size.y * 0.5)
		for i2 in range(4):
			await get_tree().physics_frame
		var hurtbox: Area2D = boss.get_node_or_null("HurtBox")
		var measured_px := 0.0
		if hurtbox != null:
			for child in hurtbox.get_children():
				if child is CollisionShape2D and child.shape is RectangleShape2D:
					measured_px = child.shape.size.y
		var measured_m: float = measured_px / METER_PX
		print("%s: altura medida=%.0fpx (%.2fm) objetivo=%.1fm sprite=%s" % [
			info.name, measured_px, measured_m, info.target_m, boss.get_node("Sprite2D").texture.resource_path])

	var luke: Luke = LUKE_SCENE.instantiate()
	luke.gravity = 0.0
	luke.position = Vector2(950, FLOOR_Y - 50)
	add_child(luke)

	var cam := Camera2D.new()
	cam.position = Vector2(850, FLOOR_Y - 250)
	cam.zoom = Vector2(0.62, 0.62)
	add_child(cam)
	cam.make_current()

	for i3 in range(20):
		await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../shotF3_bosses.png")
	get_tree().quit()

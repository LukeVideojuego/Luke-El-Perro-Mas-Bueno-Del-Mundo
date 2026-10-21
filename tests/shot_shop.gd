extends Node2D

## Capturas reales de la tienda y de los cosmeticos puestos sobre Luke.
const SHOP := preload("res://scenes/ui/shop_screen.tscn")
const LUKE_SCENE := preload("res://scenes/player/player.tscn")

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	await _shot_shop()
	await _shot_luke()
	get_tree().quit()

func _save(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../" + path)
	print("GUARDADA ", path)

func _shot_shop() -> void:
	GameState.coins = 120
	GameState.owned_items = ["hat_beanie"]
	GameState.equipped_hat = "hat_beanie"
	GameState.bark_ammo = 3
	var shop := SHOP.instantiate()
	add_child(shop)
	shop.setup("world_2_level_1")
	for i in range(20):
		await get_tree().process_frame
	await _save("shotC3_tienda.png")
	shop.queue_free()
	await get_tree().process_frame

func _shot_luke() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(2200, 1200)
	bg.position = Vector2(-100, -100)
	bg.color = Color(0.35, 0.45, 0.58)
	# z muy atras: la capa de Luke usa z_index -1 y si no quedaba tapada.
	bg.z_index = -20
	add_child(bg)
	var cam := Camera2D.new()
	cam.position = Vector2(640, 360)
	cam.zoom = Vector2(2.0, 2.0)
	add_child(cam)
	cam.make_current()
	var hats := ["hat_beanie", "hat_explorer", "hat_tophat", "hat_crown"]
	var anims := ["idle", "walk", "jump", "attack"]
	var lukes: Array[Luke] = []
	for i in range(4):
		var luke: Luke = LUKE_SCENE.instantiate()
		luke.gravity = 0.0
		luke.position = Vector2(400.0 + i * 160.0, 380.0)
		add_child(luke)
		lukes.append(luke)
	await get_tree().physics_frame
	for i in range(4):
		GameState.equipped_hat = hats[i]
		GameState.suit_equipped = i >= 2
		lukes[i].set_physics_process(false)
		lukes[i].animated_sprite.animation = anims[i]
		lukes[i].facing_direction = 1
		lukes[i]._update_cosmetics()
		# congelar el estado de cada uno con su sombrero
		lukes[i].set_meta("hat", hats[i])
	# Como GameState es global, se saca una captura por sombrero.
	for i in range(4):
		for j in range(4):
			lukes[j].visible = j == i
		GameState.equipped_hat = hats[i]
		GameState.suit_equipped = i >= 2
		lukes[i].animated_sprite.animation = anims[i]
		lukes[i]._update_cosmetics()
		cam.position = lukes[i].position
		for k in range(4):
			await get_tree().process_frame
		await _save("shotC3_luke_%s_%s.png" % [hats[i], anims[i]])

extends Node2D

## F4: captura real (no-headless) de la tienda con el boton GUARDAR PARTIDA
## nuevo, y del mensaje "Partida guardada" despues de apretarlo.

const SHOP_SCENE := preload("res://scenes/ui/shop_screen.tscn")

var shop
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(900, 700)
	GameState.reset_for_new_game()
	GameState.coins = 85
	shop = SHOP_SCENE.instantiate()
	add_child(shop)
	shop.setup("world_2_level_1")

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 10:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotF4_shop_before.png")
	if frame == 15:
		shop.get_node("Panel/Footer/SaveButton").pressed.emit()
	if frame == 20:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotF4_shop_saved.png")
		get_tree().quit()

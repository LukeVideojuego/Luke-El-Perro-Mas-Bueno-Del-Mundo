extends Node2D

## Auditoria comercial: capturas reales (no-headless) del menu, la tienda,
## y el inicio + mitad de los 12 niveles regulares (no jefes).
## Guarda todo directo en res://auditoria/.

const MAIN_SCENE := preload("res://scenes/main.tscn")
const SHOP := preload("res://scenes/ui/shop_screen.tscn")

const LEVELS := [
	{"id": "world_1_level_1", "label": "mundo1_nivel1", "start_x": 280, "mid_x": 3200},
	{"id": "world_1_level_2", "label": "mundo1_nivel2", "start_x": 180, "mid_x": 4200},
	{"id": "world_1_level_3", "label": "mundo1_nivel3", "start_x": 180, "mid_x": 4900},
	{"id": "world_2_level_1", "label": "mundo2_nivel1", "start_x": 180, "mid_x": 4200},
	{"id": "world_2_level_2", "label": "mundo2_nivel2", "start_x": 180, "mid_x": 4700},
	{"id": "world_2_level_3", "label": "mundo2_nivel3", "start_x": 180, "mid_x": 4600},
	{"id": "world_3_level_1", "label": "mundo3_nivel1", "start_x": 180, "mid_x": 4200},
	{"id": "world_3_level_2", "label": "mundo3_nivel2", "start_x": 180, "mid_x": 4700},
	{"id": "world_3_level_3", "label": "mundo3_nivel3", "start_x": 180, "mid_x": 4600},
	{"id": "world_4_level_1", "label": "mundo4_nivel1", "start_x": 180, "mid_x": 4700},
	{"id": "world_4_level_2", "label": "mundo4_nivel2", "start_x": 400, "mid_x": 4600},
	{"id": "world_4_level_3", "label": "mundo4_nivel3", "start_x": 180, "mid_x": 4400},
]

var level: Node
var cam: Camera2D
var frame := 0
var idx := -1
var sub := 0 # 0 = inicio, 1 = mitad

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	_shot_menu()

func _shot_menu() -> void:
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame
	for i in range(10):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://auditoria/00_menu_principal.png")
	print("GUARDADA 00_menu_principal")
	main.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	_shot_shop()

func _shot_shop() -> void:
	GameState.coins = 85
	GameState.owned_items = ["hat_explorer"]
	GameState.equipped_hat = "hat_explorer"
	GameState.bark_ammo = 2
	var shop := SHOP.instantiate()
	add_child(shop)
	shop.setup("world_2_level_1")
	for i in range(20):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://auditoria/00_tienda.png")
	print("GUARDADA 00_tienda")
	shop.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	_next_level()

func _next_level() -> void:
	if level != null:
		level.queue_free()
		level = null
	if cam != null:
		cam.queue_free()
		cam = null
	idx += 1
	if idx >= LEVELS.size():
		print("LISTO: capturas de niveles terminadas")
		get_tree().quit()
		return
	var data: Dictionary = LEVELS[idx]
	level = load("res://scenes/levels/%s.tscn" % data.id).instantiate()
	add_child(level)
	cam = Camera2D.new()
	cam.zoom = Vector2(1.0, 1.0)
	add_child(cam)
	cam.make_current()
	sub = 0
	frame = 0

func _physics_process(_delta: float) -> void:
	if idx < 0 or idx >= LEVELS.size() or level == null:
		return
	frame += 1
	var data: Dictionary = LEVELS[idx]
	var x: float = float(data.start_x) if sub == 0 else float(data.mid_x)
	cam.position = Vector2(x, 540.0)
	if frame == 12:
		await RenderingServer.frame_post_draw
		var suffix := "inicio" if sub == 0 else "mitad"
		var out_path := "res://auditoria/%s_%s.png" % [data.label, suffix]
		get_viewport().get_texture().get_image().save_png(out_path)
		print("GUARDADA ", data.label, "_", suffix)
		if sub == 0:
			sub = 1
			frame = 0
		else:
			_next_level()

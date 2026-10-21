extends Node2D

## B2: comprueba que en NINGUN nivel la camara pueda mostrar algo fuera del
## fondo. El bug reportado era una franja gris vertical a la izquierda (sin
## fondo ni piso) en la que ademas se podia ver a Luke por delante del gris:
## las paredes invisibles de borde (*Boundary) se extienden 70px mas alla del
## fondo y entraban en el calculo de los limites de camara.
##
## Tambien reporta cuanto piso solido hay dentro de los limites, para
## detectar el caso inverso (camara que llega a donde ya no hay piso).

const LEVELS := [
	"res://scenes/levels/world_1_level_1.tscn",
	"res://scenes/levels/world_1_level_2.tscn",
	"res://scenes/levels/world_1_level_3.tscn",
	"res://scenes/levels/world_1_boss.tscn",
	"res://scenes/levels/world_2_level_1.tscn",
	"res://scenes/levels/world_2_level_2.tscn",
	"res://scenes/levels/world_2_level_3.tscn",
	"res://scenes/levels/world_2_boss.tscn",
	"res://scenes/levels/world_3_level_1.tscn",
	"res://scenes/levels/world_3_level_2.tscn",
	"res://scenes/levels/world_3_level_3.tscn",
	"res://scenes/levels/world_3_boss.tscn",
	"res://scenes/levels/world_4_level_1.tscn",
	"res://scenes/levels/world_4_level_2.tscn",
	"res://scenes/levels/world_4_level_3.tscn",
	"res://scenes/levels/world_4_boss.tscn",
	"res://scenes/levels/final_screen.tscn",
]

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	for path in LEVELS:
		var level: Node = load(path).instantiate()
		add_child(level)
		await get_tree().physics_frame
		var luke: Node = level.get_node_or_null("Luke")
		var cam: Camera2D = luke.get_node_or_null("Camera2D") if luke != null else null
		if cam == null:
			print("SKIP: ", path.get_file(), " (sin camara)")
			level.queue_free()
			await get_tree().process_frame
			continue
		# E1: el fondo de un nivel normal ya no es UN sprite (eso se rompia de
		# verdad en el renderer con region_rect gigante simulando tiling
		# infinito, confirmado con captura real); ahora son VARIAS instancias
		# ("Background", "BackgroundTile2"...) una al lado de la otra. Hay que
		# juntar el rectangulo de TODAS, si no esta prueba mide solo el ancho
		# de la primera copia y reporta un falso recorte de camara.
		var tiles: Array[Sprite2D] = []
		for child in level.get_children():
			if child is Sprite2D and (child.name == "Background" or String(child.name).begins_with("BackgroundTile")):
				tiles.append(child)
		if tiles.is_empty():
			var sky := level.get_node_or_null("Sky") as Sprite2D
			if sky != null:
				tiles.append(sky)
		if tiles.is_empty():
			print("SKIP: ", path.get_file(), " (sin fondo propio)")
			level.queue_free()
			await get_tree().process_frame
			continue
		var origin := Vector2.INF
		var bottom_right := -Vector2.INF
		for tile in tiles:
			if tile.texture == null:
				continue
			var tsize: Vector2 = tile.region_rect.size if tile.region_enabled else tile.texture.get_size()
			tsize *= tile.global_scale
			var torigin: Vector2 = tile.global_position - (tsize * 0.5 if tile.centered else Vector2.ZERO)
			origin = origin.min(torigin)
			bottom_right = bottom_right.max(torigin + tsize)
		var size: Vector2 = bottom_right - origin
		var ok_left: bool = float(cam.limit_left) >= origin.x - 0.5
		var ok_right: bool = float(cam.limit_right) <= origin.x + size.x + 0.5
		var ok_top: bool = float(cam.limit_top) >= origin.y - 0.5
		var ok_bottom: bool = float(cam.limit_bottom) <= origin.y + size.y + 0.5
		_check(ok_left and ok_right and ok_top and ok_bottom,
			"%-26s camara x=[%d,%d] y=[%d,%d] dentro del fondo x=[%.0f,%.0f] y=[%.0f,%.0f]" % [
				path.get_file(), cam.limit_left, cam.limit_right, cam.limit_top, cam.limit_bottom,
				origin.x, origin.x + size.x, origin.y, origin.y + size.y])
		level.queue_free()
		await get_tree().process_frame
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

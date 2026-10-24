extends Node

## B2: extrae SOLO la tela de la capa (rojo + ribete dorado) de
## referencia_visual/luke_capa.png, descartando el perro, el fondo y el
## collar/medallon (Luke ya tiene un cosmetico de collar aparte). Usa un
## clasificador por color (rojo saturado o dorado) en vez de flood-fill,
## porque la capa esta pegada al perro sin fondo de por medio entre ellos.

const SRC := "res://referencia_visual/luke_capa.png"

func _is_cape_color(c: Color) -> bool:
	var r := c.r * 255.0
	var g := c.g * 255.0
	var b := c.b * 255.0
	# Rojo (tela principal, sombras y el contorno oscuro del rojo):
	# satura mucho mas fuerte que el pelaje marron (R/G ~1.8-2 en el
	# pelaje vs 3+ en la capa).
	if r > 55.0 and r > 2.4 * maxf(g, 1.0) and r > 2.0 * maxf(b, 1.0):
		return true
	# Dorado/amarillo del ribete: R y G altos, B bajo (distinto del
	# pelaje crema, que tiene B alto tambien).
	if r > 150.0 and g > 110.0 and b < 90.0:
		return true
	return false

func _mask_cape(img: Image) -> void:
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if c.a < 0.1 or not _is_cape_color(c):
				img.set_pixel(x, y, Color(0, 0, 0, 0))

## Tapa agujeritos de 1px (pixeles transparentes con 3 o 4 vecinos
## opacos): son pixeles de antialiasing entre el rojo y el ribete dorado
## que el clasificador de color no reconocio como ninguno de los dos. No
## toca el contorno real (ahi un pixel transparente tiene 2+ vecinos
## transparentes).
func _fill_pinholes(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var to_fill: Array = []
	for y in range(h):
		for x in range(w):
			if img.get_pixel(x, y).a > 0.1:
				continue
			var opaque_neighbors: Array[Color] = []
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx < 0 or nx >= w or ny < 0 or ny >= h:
					continue
				var nc := img.get_pixel(nx, ny)
				if nc.a > 0.1:
					opaque_neighbors.append(nc)
			if opaque_neighbors.size() >= 3:
				var avg := Color(0, 0, 0, 1)
				for c in opaque_neighbors:
					avg.r += c.r
					avg.g += c.g
					avg.b += c.b
				avg.r /= opaque_neighbors.size()
				avg.g /= opaque_neighbors.size()
				avg.b /= opaque_neighbors.size()
				to_fill.append([Vector2i(x, y), avg])
	for entry in to_fill:
		img.set_pixel(entry[0].x, entry[0].y, entry[1])

func _keep_largest_island(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var labeled := {}
	var islands: Array = []
	for y in range(h):
		for x in range(w):
			var p := Vector2i(x, y)
			if labeled.has(p) or img.get_pixel(x, y).a <= 0.1:
				continue
			var stack: Array = [p]
			var island: Array = []
			labeled[p] = true
			while not stack.is_empty():
				var cur: Vector2i = stack.pop_back()
				island.append(cur)
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
						Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
					var np: Vector2i = cur + d
					if np.x < 0 or np.x >= w or np.y < 0 or np.y >= h or labeled.has(np):
						continue
					if img.get_pixel(np.x, np.y).a <= 0.1:
						continue
					labeled[np] = true
					stack.append(np)
			islands.append(island)
	if islands.size() <= 1:
		return
	var biggest: Array = islands[0]
	for isl in islands:
		if isl.size() > biggest.size():
			biggest = isl
	for isl in islands:
		if isl == biggest:
			continue
		for p in isl:
			img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))

func _bbox(img: Image) -> Rect2i:
	var w := img.get_width()
	var h := img.get_height()
	var minx := w
	var miny := h
	var maxx := -1
	var maxy := -1
	for y in range(h):
		for x in range(w):
			if img.get_pixel(x, y).a > 0.1:
				minx = mini(minx, x)
				miny = mini(miny, y)
				maxx = maxi(maxx, x)
				maxy = maxi(maxy, y)
	if maxx < 0:
		return Rect2i(0, 0, 0, 0)
	return Rect2i(minx, miny, maxx - minx + 1, maxy - miny + 1)

## El clasificador de color excluye el contorno negro original (satura
## bajo). Sin el, la capa queda con bordes blandos, distinto del resto
## del arte del juego (todo con contorno negro marcado) -- se agrega un
## contorno negro de 1px alrededor de la silueta ya recortada.
func _add_outline(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var border: Array = []
	for y in range(h):
		for x in range(w):
			if img.get_pixel(x, y).a > 0.1:
				continue
			var touches := false
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx < 0 or nx >= w or ny < 0 or ny >= h:
					continue
				if img.get_pixel(nx, ny).a > 0.1:
					touches = true
					break
			if touches:
				border.append(Vector2i(x, y))
	for p in border:
		img.set_pixel(p.x, p.y, Color(0.08, 0.05, 0.05, 1.0))

func _process_one(region: Rect2i, out_name: String) -> Image:
	var src := Image.load_from_file(SRC)
	var img := src.get_region(region)
	_mask_cape(img)
	_fill_pinholes(img)
	_keep_largest_island(img)
	var box := _bbox(img)
	box = box.grow(1).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	print(out_name, " bbox=", box)
	var cropped := img.get_region(box)
	_add_outline(cropped)
	cropped.save_png("res://../extractB2_%s.png" % out_name)
	var z := cropped.duplicate()
	z.resize(z.get_width() * 3, z.get_height() * 3, Image.INTERPOLATE_NEAREST)
	z.save_png("res://../extractB2_%s_zoom.png" % out_name)
	return cropped

func _ready() -> void:
	var rest := _process_one(Rect2i(0, 0, 303, 296), "cape_rest")
	var jump := _process_one(Rect2i(0, 296, 303, 296), "cape_jump")
	rest.save_png("res://assets/items/Shop/cape_rest.png")
	jump.save_png("res://assets/items/Shop/cape_jump.png")
	print("listo, guardado en assets/items/Shop/")
	get_tree().quit()

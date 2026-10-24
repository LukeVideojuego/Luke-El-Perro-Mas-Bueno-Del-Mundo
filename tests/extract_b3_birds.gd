extends Node

## B3: extrae los 2 pajaros (pinzon, reposo+aleteo) de referencia_visual/
## aves.png, les saca el fondo con flood-fill (umbral por distancia de
## color entre vecinos, para tolerar el degrade de la textura de madera
## pero detenerse seco en el contorno negro del pajaro) y los recorta a su
## bounding box real.

const SRC := "res://referencia_visual/aves.png"

func _flood_remove_bg(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var visited := {}
	var queue := []
	for x in range(w):
		queue.append(Vector2i(x, 0))
		queue.append(Vector2i(x, h - 1))
	for y in range(h):
		queue.append(Vector2i(0, y))
		queue.append(Vector2i(w - 1, y))
	var to_clear: Array = []
	while not queue.is_empty():
		var p: Vector2i = queue.pop_back()
		if p.x < 0 or p.x >= w or p.y < 0 or p.y >= h:
			continue
		if visited.has(p):
			continue
		visited[p] = true
		var c := img.get_pixel(p.x, p.y)
		to_clear.append(p)
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var np: Vector2i = p + d
			if np.x < 0 or np.x >= w or np.y < 0 or np.y >= h or visited.has(np):
				continue
			var nc := img.get_pixel(np.x, np.y)
			var dist: float = absf(c.r - nc.r) + absf(c.g - nc.g) + absf(c.b - nc.b)
			if dist < 0.12:
				queue.append(np)
	for p in to_clear:
		img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))

## Despues del flood-fill de fondo, puede quedar algun otro objeto
## desconectado dentro del recorte (p.ej. un cartelito del marco de
## referencia). Se queda solo con la isla opaca mas grande (el pajaro).
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
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
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

func _process_one(region: Rect2i, out_name: String) -> Image:
	var src := Image.load_from_file(SRC)
	var img := src.get_region(region)
	_flood_remove_bg(img)
	_keep_largest_island(img)
	var box := _bbox(img)
	print(out_name, " bbox=", box)
	return img.get_region(box)

const CANVAS := Vector2i(80, 70)

func _center_on_canvas(img: Image) -> Image:
	var canvas := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	var off := Vector2i((CANVAS.x - img.get_width()) / 2, (CANVAS.y - img.get_height()) / 2)
	canvas.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), off)
	return canvas

func _ready() -> void:
	var rest := _center_on_canvas(_process_one(Rect2i(645, 177, 150, 120), "pinzon_rest"))
	var flap := _center_on_canvas(_process_one(Rect2i(795, 177, 170, 120), "pinzon_flap"))
	rest.save_png("res://assets/Enemies/Reference/bird.png")
	flap.save_png("res://assets/Enemies/Reference/bird_walk.png")
	var rz := rest.duplicate()
	rz.resize(rz.get_width() * 6, rz.get_height() * 6, Image.INTERPOLATE_NEAREST)
	rz.save_png("res://../extractB3_final_rest_zoom.png")
	var fz := flap.duplicate()
	fz.resize(fz.get_width() * 6, fz.get_height() * 6, Image.INTERPOLATE_NEAREST)
	fz.save_png("res://../extractB3_final_flap_zoom.png")
	print("listo, guardado en assets/Enemies/Reference/")
	get_tree().quit()

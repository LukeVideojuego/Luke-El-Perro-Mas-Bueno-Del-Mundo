extends Node

## A8: Fausto no tenia pelo dibujado -- la cabeza era piel lisa hasta el
## borde superior (confirmado con zoom real, tests/shot_a8_fausto_zoom.gd).
## Pinta un gorro de pelo corto oscuro (como en la referencia
## referencia_visual/fausto-6-years.png) sobre la silueta YA existente de
## la cabeza (misma forma/alpha, solo cambia el color a pelo en la franja
## superior), igual que el resto de los chicos (ver bauti.png). Usa la
## silueta de fausto.png (sin el remolino de brazo del caminar) para saber,
## columna por columna, donde arranca la cabeza, y aplica el mismo rango
## de filas a fausto_walk.png para no agarrar ese remolino por error.

const HAIR_DARK := Color8(45, 28, 20, 255)
const HAIR_LIGHT := Color8(72, 46, 32, 255)
const MIN_DEPTH := 7
const MAX_DEPTH := 11

func _head_top_rows(img: Image) -> Array:
	var w := img.get_width()
	var h := img.get_height()
	var tops := []
	tops.resize(w)
	for x in range(w):
		var top := -1
		for y in range(h):
			if img.get_pixel(x, y).a > 0.5:
				top = y
				break
		tops[x] = top
	return tops

func _paint_hair(path: String, tops: Array) -> void:
	var img: Image = load(path).get_image()
	img.decompress()
	var w := img.get_width()
	for x in range(w):
		var top: int = tops[x]
		if top < 0:
			continue
		var depth: int = MIN_DEPTH + (x % (MAX_DEPTH - MIN_DEPTH + 1))
		for y in range(top, top + depth):
			if y < 0 or y >= img.get_height():
				continue
			if img.get_pixel(x, y).a <= 0.5:
				continue
			var c: Color = HAIR_LIGHT if ((x + y) % 3 == 0) else HAIR_DARK
			img.set_pixel(x, y, c)
	img.save_png(path)
	print("Guardado ", path)

func _ready() -> void:
	var ref_img: Image = load("res://assets/characters/Kids/EndOfWorld1/fausto.png").get_image()
	ref_img.decompress()
	var tops := _head_top_rows(ref_img)
	_paint_hair("res://assets/characters/Kids/EndOfWorld1/fausto.png", tops)
	_paint_hair("res://assets/characters/Kids/EndOfWorld1/fausto_walk.png", tops)
	get_tree().quit()

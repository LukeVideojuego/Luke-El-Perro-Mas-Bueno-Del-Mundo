extends Node

## B1: fondos nuevos para los 4 bonus + el minijuego final, generados a
## partir de la paleta/estetica de cada referencia (referencia_visual/
## bonus_*.png) pero SIN a Luke dibujado y con altura real de pantalla
## completa (nada de tiras panoramicas de 190px que dejan zonas grises).
## Generados por codigo (gradiente + formas simples) en vez de editar los
## pixeles de la referencia, porque esta tiene a Luke y al cartel/iconos
## de UI entreverados con el fondo real, imposibles de separar limpio.

const W := 683
const H := 900

func _lerp_color(a: Color, b: Color, t: float) -> Color:
	return Color(lerpf(a.r, b.r, t), lerpf(a.g, b.g, t), lerpf(a.b, b.b, t), 1.0)

func _vgrad(img: Image, top: Color, bottom: Color, y0: int, y1: int) -> void:
	for y in range(y0, y1):
		var t: float = float(y - y0) / float(maxi(y1 - y0 - 1, 1))
		var c := _lerp_color(top, bottom, t)
		img.fill_rect(Rect2i(0, y, img.get_width(), 1), c)

func _circle(img: Image, cx: float, cy: float, r: float, c: Color, soft: float = 0.0) -> void:
	var x0 := maxi(0, int(cx - r - soft))
	var x1 := mini(img.get_width(), int(cx + r + soft))
	var y0 := maxi(0, int(cy - r - soft))
	var y1 := mini(img.get_height(), int(cy + r + soft))
	for y in range(y0, y1):
		for x in range(x0, x1):
			var d: float = Vector2(x - cx, y - cy).length()
			if d <= r:
				img.set_pixel(x, y, c)
			elif soft > 0.0 and d <= r + soft:
				var t: float = 1.0 - (d - r) / soft
				var existing := img.get_pixel(x, y)
				img.set_pixel(x, y, _lerp_color(existing, c, t * c.a))

func _star(img: Image, cx: int, cy: int, c: Color) -> void:
	if cx < 0 or cx >= img.get_width() or cy < 0 or cy >= img.get_height():
		return
	img.set_pixel(cx, cy, c)
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var p: Vector2i = Vector2i(cx, cy) + d
		if p.x >= 0 and p.x < img.get_width() and p.y >= 0 and p.y < img.get_height():
			var existing := img.get_pixel(p.x, p.y)
			img.set_pixel(p.x, p.y, _lerp_color(existing, c, 0.4))

## Siluetas de montaña: un poligono simple relleno, dibujado por scanline.
func _mountain(img: Image, base_y: int, peak_x: float, peak_y: float, half_w: float, c: Color) -> void:
	var x0 := maxi(0, int(peak_x - half_w))
	var x1 := mini(img.get_width(), int(peak_x + half_w))
	for x in range(x0, x1):
		var t: float = 1.0 - absf(x - peak_x) / half_w
		var top_y: int = int(lerpf(base_y, peak_y, t))
		for y in range(maxi(0, top_y), mini(img.get_height(), base_y)):
			img.set_pixel(x, y, c)

func _blob(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	var x0 := maxi(0, int(cx - rx))
	var x1 := mini(img.get_width(), int(cx + rx))
	var y0 := maxi(0, int(cy - ry))
	var y1 := mini(img.get_height(), int(cy + ry))
	for y in range(y0, y1):
		for x in range(x0, x1):
			var nx: float = (x - cx) / rx
			var ny: float = (y - cy) / ry
			if nx * nx + ny * ny <= 1.0:
				img.set_pixel(x, y, c)

var _rng := RandomNumberGenerator.new()

func _gen_sky() -> Image:
	# Referencia: "Cielo Estelar" -- noche azul profunda con luna y
	# estrellas, nubes suaves abajo.
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	_vgrad(img, Color8(4, 6, 40), Color8(70, 70, 190), 0, H)
	_circle(img, W * 0.78, H * 0.18, 55.0, Color8(245, 240, 225), 25.0)
	_rng.seed = 9
	for i in range(70):
		var sx := _rng.randi_range(0, W - 1)
		var sy := _rng.randi_range(0, int(H * 0.55))
		_star(img, sx, sy, Color8(255, 255, 255, 220))
	for i in range(4):
		var bx: float = _rng.randf_range(0.0, W)
		var by: float = H * 0.72 + _rng.randf_range(-20, 20)
		_blob(img, bx, by, 120.0, 30.0, Color8(230, 232, 245, 140))
	return img

func _gen_beach() -> Image:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var horizon := int(H * 0.42)
	_vgrad(img, Color8(120, 200, 253), Color8(200, 235, 253), 0, horizon)
	_vgrad(img, Color8(10, 110, 200), Color8(0, 60, 140), horizon, H)
	_circle(img, W * 0.18, H * 0.14, 46.0, Color8(255, 236, 150), 30.0)
	_rng.seed = 11
	for i in range(5):
		var bx: float = _rng.randf_range(0.0, W)
		var by: float = H * 0.2 + _rng.randf_range(-20, 30)
		_blob(img, bx, by, 70.0, 18.0, Color8(255, 255, 255, 210))
		_blob(img, bx + 40.0, by + 4.0, 50.0, 14.0, Color8(255, 255, 255, 210))
	for i in range(30):
		var sx := _rng.randf_range(0.0, W)
		var sy: float = horizon + _rng.randf_range(0.0, H - horizon)
		var shade: float = _rng.randf_range(0.0, 1.0)
		var c := _lerp_color(Color8(20, 140, 220), Color8(230, 245, 255), shade * 0.3)
		_blob(img, sx, sy, _rng.randf_range(20, 60), 3.0, Color(c.r, c.g, c.b, 0.25))
	return img

func _gen_snow() -> Image:
	# Referencia: "Aurora Boreal" -- cielo nocturno helado con aurora
	# verde/violeta y montanas nevadas.
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	_vgrad(img, Color8(4, 8, 30), Color8(30, 55, 90), 0, H)
	_rng.seed = 13
	for i in range(60):
		var sx := _rng.randi_range(0, W - 1)
		var sy := _rng.randi_range(0, int(H * 0.4))
		_star(img, sx, sy, Color8(255, 255, 255, 200))
	# Cintas de aurora: bandas horizontales onduladas semitransparentes.
	for band in range(3):
		var base_y: float = H * (0.16 + band * 0.07)
		var col: Color = Color8(60, 220, 150, 70) if band % 2 == 0 else Color8(140, 90, 220, 70)
		for x in range(W):
			var wave: float = sin(x * 0.02 + band * 2.0) * 22.0
			var y := int(base_y + wave)
			for dy in range(-10, 10):
				var yy := y + dy
				if yy >= 0 and yy < H:
					var existing := img.get_pixel(x, yy)
					var t: float = 1.0 - absf(dy) / 10.0
					img.set_pixel(x, yy, _lerp_color(existing, col, t * 0.55))
	# Montanas nevadas (varias, superpuestas, de atras hacia adelante).
	var base: int = int(H * 0.78)
	_mountain(img, base, W * 0.2, H * 0.52, 220.0, Color8(150, 175, 205))
	_mountain(img, base, W * 0.55, H * 0.46, 260.0, Color8(130, 155, 190))
	_mountain(img, base + 20, W * 0.85, H * 0.58, 230.0, Color8(170, 195, 220))
	_mountain(img, base + 40, W * 0.4, H * 0.62, 300.0, Color8(210, 225, 240))
	# nieve (parte blanca de las puntas)
	_mountain(img, int(H * 0.56), W * 0.2, H * 0.52, 70.0, Color8(240, 248, 255))
	_mountain(img, int(H * 0.5), W * 0.55, H * 0.46, 80.0, Color8(240, 248, 255))
	_mountain(img, int(H * 0.68), W * 0.4, H * 0.62, 90.0, Color8(240, 248, 255))
	return img

func _gen_volcano() -> Image:
	# Referencia: "Cuevas de Lava" -- cueva oscura con cascadas de lava
	# brillante.
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	_vgrad(img, Color8(10, 2, 8), Color8(35, 8, 10), 0, H)
	var base: int = int(H * 0.8)
	_mountain(img, base, W * 0.25, H * 0.3, 260.0, Color8(30, 10, 12))
	_mountain(img, base, W * 0.65, H * 0.22, 280.0, Color8(22, 6, 8))
	_mountain(img, base + 10, W * 0.45, H * 0.4, 320.0, Color8(40, 14, 14))
	_rng.seed = 17
	for i in range(3):
		var lx: float = _rng.randf_range(W * 0.1, W * 0.9)
		_vgrad_strip(img, lx, 60.0, int(H * 0.1), base + 10)
	for i in range(40):
		var ex := _rng.randf_range(0.0, W)
		var ey := _rng.randf_range(H * 0.3, H * 0.9)
		_circle(img, ex, ey, _rng.randf_range(2.0, 5.0), Color8(255, 150, 40, 180), 4.0)
	return img

func _vgrad_strip(img: Image, cx: float, width: float, y0: int, y1: int) -> void:
	var x0 := maxi(0, int(cx - width * 0.5))
	var x1 := mini(img.get_width(), int(cx + width * 0.5))
	for y in range(y0, y1):
		var t: float = float(y - y0) / float(maxi(y1 - y0 - 1, 1))
		var c := _lerp_color(Color8(255, 230, 120), Color8(230, 60, 10), t)
		for x in range(x0, x1):
			var edge: float = 1.0 - absf(x - cx) / (width * 0.5)
			if edge > 0.0:
				var existing := img.get_pixel(x, y)
				img.set_pixel(x, y, _lerp_color(existing, c, edge))

func _gen_final() -> Image:
	# Referencia: estilo festivo rosa/magenta (jardin/templo de cerezos),
	# usado para el minijuego final -- gradiente rosado con "arboles" de
	# flores simples (blobs rosa/magenta) en vez de pixel art detallado.
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	_vgrad(img, Color8(120, 150, 245), Color8(245, 190, 225), 0, int(H * 0.55))
	_vgrad(img, Color8(150, 110, 200), Color8(90, 60, 140), int(H * 0.55), H)
	_rng.seed = 21
	for i in range(5):
		var tx: float = _rng.randf_range(0.0, W)
		var ty: float = H * 0.42 + _rng.randf_range(-20, 20)
		var col: Color = Color8(250, 150, 200) if i % 2 == 0 else Color8(240, 110, 170)
		_blob(img, tx, ty, 90.0, 55.0, col)
		_blob(img, tx - 50.0, ty + 20.0, 60.0, 40.0, col)
		_blob(img, tx + 55.0, ty + 15.0, 65.0, 42.0, col)
	return img

func _save(img: Image, path: String) -> void:
	img.save_png(path)
	print("guardado ", path)

func _ready() -> void:
	_save(_gen_sky(), "res://assets/backgrounds/Bonus/bonus_sky.png")
	_save(_gen_beach(), "res://assets/backgrounds/Bonus/bonus_beach.png")
	_save(_gen_snow(), "res://assets/backgrounds/Bonus/bonus_snow.png")
	_save(_gen_volcano(), "res://assets/backgrounds/Bonus/bonus_volcano.png")
	_save(_gen_final(), "res://assets/backgrounds/Bonus/bonus_final_kids_abuelas.png")
	print("listo")
	get_tree().quit()

extends Node

## A8: analiza el canal alpha de fausto.png en la zona del pelo (parte de
## arriba de la cabeza) para confirmar si hay pixeles transparentes o
## semi-transparentes, y su color, antes de corregir el sprite.

func _scan(path: String) -> void:
	print("=== ", path, " ===")
	var img: Image = load(path).get_image()
	img.decompress()
	var w := img.get_width()
	var h := img.get_height()
	print("size: ", w, "x", h)
	# Pelo: tipicamente el tercio superior del sprite.
	var hair_bottom := int(h * 0.30)
	for y in range(0, hair_bottom):
		var row := ""
		for x in range(w):
			var c := img.get_pixel(x, y)
			if c.a < 0.05:
				row += "."
			elif c.a < 0.95:
				row += "o"
			else:
				row += "#"
		print(y, ": ", row)
	# Reporta algunos colores de muestra en la zona de pelo.
	for y in [int(h*0.05), int(h*0.12), int(h*0.2)]:
		for x in [int(w*0.3), int(w*0.5), int(w*0.7)]:
			var c := img.get_pixel(x, y)
			print("  pixel(", x, ",", y, ")=", c)

func _row_colors(path: String) -> void:
	print("=== ", path, " row colors ===")
	var img: Image = load(path).get_image()
	img.decompress()
	var w := img.get_width()
	for y in range(0, 35):
		var line := "y=%2d: " % y
		for x in [int(w*0.25), int(w*0.35), int(w*0.5), int(w*0.65), int(w*0.75)]:
			var c := img.get_pixel(x, y)
			line += "(%.0f,%.0f,%.0f,a%.1f) " % [c.r*255, c.g*255, c.b*255, c.a]
		print(line)

func _ready() -> void:
	_row_colors("res://assets/characters/Kids/EndOfWorld1/fausto.png")
	get_tree().quit()

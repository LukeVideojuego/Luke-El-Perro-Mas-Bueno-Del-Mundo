extends Node

func _ready() -> void:
	var img := Image.load_from_file("res://referencia_visual/luke_capa.png")
	# Puntos de muestra manuales, aproximados visualmente sobre la imagen
	# 303x592 (top=reposo y=0-296, bottom=salto y=296-592).
	var points := {
		"cape_bright_red": Vector2i(140, 150),
		"cape_dark_red": Vector2i(100, 180),
		"cape_gold_trim": Vector2i(90, 195),
		"fur_brown": Vector2i(185, 50),
		"fur_cream": Vector2i(215, 240),
		"bg_navy": Vector2i(10, 10),
		"collar_blue": Vector2i(210, 122),
		"medallion_gold": Vector2i(232, 150),
	}
	for key in points:
		var p: Vector2i = points[key]
		var c := img.get_pixel(p.x, p.y)
		print(key, " @", p, " = (", int(c.r*255), ",", int(c.g*255), ",", int(c.b*255), ") a=", c.a)
	get_tree().quit()

extends Node

## A3: mide en pixeles reales donde esta el poste dentro de flag_blue_a.png
## para calcular el post_offset_x correcto que lo alinee con la base.

const PATHS := [
	"res://assets/Tiles/Default/flag_blue_a.png",
	"res://assets/Tiles/Default/flag_green_a.png",
	"res://assets/Tiles/Default/sign_exit.png",
	"res://assets/Tiles/Default/sign.png",
]

func _ready() -> void:
	for path in PATHS:
		print("=== ", path, " ===")
		var img: Image = load(path).get_image()
		img.decompress()
		var w := img.get_width()
		var h := img.get_height()
		for row in [h - 2, h - 6, h - 10]:
			var first := -1
			var last := -1
			for x in range(w):
				var c := img.get_pixel(x, row)
				if c.a > 0.1:
					if first == -1:
						first = x
					last = x
			print("  fila y=%d: poste de x=%d a x=%d (centro=%.1f, ancho=%d), img_w=%d" % [row, first, last, (first + last) / 2.0, last - first + 1, w])
	get_tree().quit()

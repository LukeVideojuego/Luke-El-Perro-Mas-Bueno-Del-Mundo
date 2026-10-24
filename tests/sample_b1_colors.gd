extends Node

const FILES := [
	"res://referencia_visual/bonus_sky.png",
	"res://referencia_visual/bonus_beach.png",
	"res://referencia_visual/bonus_snow.png",
	"res://referencia_visual/bonus_volcano.png",
	"res://referencia_visual/bonus_final_kids_abuelas.png",
]

func _ready() -> void:
	for f in FILES:
		var img := Image.load_from_file(f)
		var w := img.get_width()
		var h := img.get_height()
		print("=== ", f, " ", w, "x", h, " ===")
		for fy in [0.05, 0.3, 0.6, 0.9]:
			var row := ""
			for fx in [0.1, 0.3, 0.5, 0.7, 0.9]:
				var c := img.get_pixel(int(w * fx), int(h * fy))
				row += "(%d,%d,%d) " % [c.r * 255, c.g * 255, c.b * 255]
			print("y=%.2f: %s" % [fy, row])
	get_tree().quit()

extends Node

func _ready() -> void:
	var img := Image.load_from_file("res://../shotB1_bonus_world_1_mid.png")
	var w := img.get_width()
	var h := img.get_height()
	var cx := int(w * 0.5)
	for y in range(h):
		var c := img.get_pixel(cx, y)
		if y % 20 == 0:
			print(y, ": (", int(c.r*255), ",", int(c.g*255), ",", int(c.b*255), ")")
	get_tree().quit()

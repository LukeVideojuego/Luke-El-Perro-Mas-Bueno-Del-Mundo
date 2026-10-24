extends Node

func _ready() -> void:
	var img := Image.load_from_file("res://referencia_visual/luke_capa.png")
	var top := img.get_region(Rect2i(0, 0, 303, 296))
	top.resize(top.get_width() * 2, top.get_height() * 2, Image.INTERPOLATE_NEAREST)
	var step := 20 * 2
	for x in range(0, top.get_width(), step):
		for y in range(top.get_height()):
			top.set_pixel(x, y, Color(0, 1, 0, 1))
	for y in range(0, top.get_height(), step):
		for x in range(top.get_width()):
			top.set_pixel(x, y, Color(0, 1, 0, 1))
	top.save_png("res://../gridB2_capa_rest.png")
	print("done")
	get_tree().quit()

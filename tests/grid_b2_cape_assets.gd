extends Node

func _grid(path: String, out: String, step: int) -> void:
	var img: Image = load(path).get_image()
	img.decompress()
	var scale_f := 4
	img.resize(img.get_width() * scale_f, img.get_height() * scale_f, Image.INTERPOLATE_NEAREST)
	var s := step * scale_f
	for x in range(0, img.get_width(), s):
		for y in range(img.get_height()):
			img.set_pixel(x, y, Color(0, 1, 0, 1))
	for y in range(0, img.get_height(), s):
		for x in range(img.get_width()):
			img.set_pixel(x, y, Color(0, 1, 0, 1))
	img.save_png(out)

func _ready() -> void:
	_grid("res://assets/items/Shop/cape_rest.png", "res://../gridB2_cape_rest.png", 10)
	_grid("res://assets/items/Shop/cape_jump.png", "res://../gridB2_cape_jump.png", 10)
	print("done")
	get_tree().quit()

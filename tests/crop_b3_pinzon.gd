extends Node

func _ready() -> void:
	var img := Image.load_from_file("res://referencia_visual/aves.png")
	var left := img.get_region(Rect2i(635 + 10, 172 + 5, 130, 110))
	left.resize(left.get_width() * 6, left.get_height() * 6, Image.INTERPOLATE_NEAREST)
	left.save_png("res://../cropB3_pinzon_left.png")
	var right := img.get_region(Rect2i(635 + 160, 172 + 5, 130, 110))
	right.resize(right.get_width() * 6, right.get_height() * 6, Image.INTERPOLATE_NEAREST)
	right.save_png("res://../cropB3_pinzon_right.png")
	print("GUARDADA pinzon_left/right")
	get_tree().quit()

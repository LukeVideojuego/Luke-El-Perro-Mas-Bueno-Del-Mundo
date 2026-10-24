extends Node

func _ready() -> void:
	var img := Image.load_from_file("res://referencia_visual/luke_capa.png")
	var top := img.get_region(Rect2i(0, 0, 303, 296))
	top.save_png("res://../cropB2_capa_rest.png")
	var bottom := img.get_region(Rect2i(0, 296, 303, 296))
	bottom.save_png("res://../cropB2_capa_jump.png")
	print("done ", img.get_size())
	get_tree().quit()

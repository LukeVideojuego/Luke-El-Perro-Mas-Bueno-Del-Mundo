extends Node

## A8: guarda una version ampliada (nearest-neighbor, sin blur) de
## fausto.png y fausto_walk.png para inspeccionar el pelo de cerca.

func _save_zoomed(path: String, out_name: String) -> void:
	var img: Image = load(path).get_image()
	img.decompress()
	img.resize(img.get_width() * 10, img.get_height() * 10, Image.INTERPOLATE_NEAREST)
	img.save_png("res://../%s.png" % out_name)
	print("GUARDADA ", out_name)

func _ready() -> void:
	_save_zoomed("res://assets/characters/Kids/EndOfWorld1/fausto.png", "shotA8_fausto_idle_fixed")
	_save_zoomed("res://assets/characters/Kids/EndOfWorld1/fausto_walk.png", "shotA8_fausto_walk_fixed")
	get_tree().quit()

extends Node2D

var scripts: Array[String] = []
var failures := 0

func _ready() -> void:
	_collect("res://scripts")
	_collect("res://tests")
	print("TOTAL SCRIPTS: ", scripts.size())
	for f in scripts:
		var scr := load(f)
		if scr == null:
			failures += 1
			printerr("FALLO CARGA: ", f)
		else:
			print("OK: ", f)
	print("RESULTADO: ", failures, " fallos")
	get_tree().quit(failures)

func _collect(dir: String) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		printerr("NO SE PUEDE ABRIR: ", dir)
		return
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		if d.current_is_dir():
			_collect(dir + "/" + n)
		elif n.ends_with(".gd"):
			scripts.append(dir + "/" + n)
		n = d.get_next()
	d.list_dir_end()

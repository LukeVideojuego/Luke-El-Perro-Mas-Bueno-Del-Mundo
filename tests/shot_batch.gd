extends Node2D

## Herramienta de capturas reales (SIN --headless: renderiza de verdad).
## Lee la lista de tomas de res://tests/shot_batch.json y guarda un PNG por
## toma, asi se pueden pedir muchas capturas de muchos niveles en una sola
## corrida en vez de un script por captura.
##
## Formato de cada toma:
##   {
##     "level": "res://scenes/levels/world_2_level_1.tscn",
##     "x": 8000, "y": 820,          # centro de camara
##     "zoom": 1.5,                  # opcional (1.0 por defecto)
##     "out": "shot_w2l1_meta.png",  # se guarda en la carpeta padre del proyecto
##     "luke_x": 7900,               # opcional: reubica a Luke para la foto
##     "luke_y": 820,
##     "wait": 20                    # opcional: frames de fisica antes de la foto
##   }

const JSON_PATH := "res://tests/shot_batch.json"

var shots: Array = []
var index := -1
var level: Node
var cam: Camera2D
var frame := 0
var wait_frames := 12

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	var file := FileAccess.open(JSON_PATH, FileAccess.READ)
	if file == null:
		print("ERROR: no pude abrir ", JSON_PATH)
		get_tree().quit()
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_ARRAY:
		print("ERROR: ", JSON_PATH, " no es una lista")
		get_tree().quit()
		return
	shots = parsed
	_next_shot()

func _next_shot() -> void:
	if level != null:
		level.queue_free()
		level = null
	if cam != null:
		cam.queue_free()
		cam = null
	index += 1
	if index >= shots.size():
		print("LISTO: ", shots.size(), " capturas")
		get_tree().quit()
		return
	var shot: Dictionary = shots[index]
	level = load(String(shot.level)).instantiate()
	add_child(level)
	if shot.has("luke_x"):
		var luke: Node2D = level.get_node_or_null("Luke")
		if luke != null:
			luke.global_position = Vector2(float(shot.luke_x), float(shot.get("luke_y", 820.0)))
	if bool(shot.get("luke_camera", false)):
		# Usa la camara REAL de Luke (con los limites que calcula level_base),
		# que es lo unico que sirve para verificar el borde del encuadre.
		cam = null
	else:
		cam = Camera2D.new()
		cam.zoom = Vector2(float(shot.get("zoom", 1.0)), float(shot.get("zoom", 1.0)))
		cam.position = Vector2(float(shot.x), float(shot.y))
		add_child(cam)
		cam.make_current()
	wait_frames = int(shot.get("wait", 12))
	frame = 0

func _physics_process(_delta: float) -> void:
	if index < 0 or index >= shots.size():
		return
	frame += 1
	# La camara de Luke vuelve a tomar el control al entrar al arbol; la
	# re-forzamos un par de frames hasta que todo se asienta.
	if cam != null and frame < wait_frames:
		cam.make_current()
	if frame == wait_frames:
		await RenderingServer.frame_post_draw
		var shot: Dictionary = shots[index]
		var path := "res://../" + String(shot.out)
		get_viewport().get_texture().get_image().save_png(path)
		print("GUARDADA ", shot.out, "  (", shot.level.get_file(), " @ ", shot.x, ",", shot.y, " zoom ", shot.get("zoom", 1.0), ")")
		_next_shot()

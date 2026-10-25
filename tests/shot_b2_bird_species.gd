extends Node2D

## B2: captura real (no-headless) con zoom de cada tipo de ave, en sus 2
## poses (R/P e flapeo), para confirmar que ahora hay variedad real en
## vez de siempre el mismo pajaro con un color distinto.

const BIRD_SCENE := preload("res://scenes/enemies/bird.tscn")
const SPECIES := [
	"halcon", "aguila", "colibri", "flamenco", "lechuza",
	"loro", "pinzon", "carpintero", "tucan", "grulla",
]

var idx := 0
var bird: Node2D
var cam: Camera2D
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(500, 400)
	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()
	cam.zoom = Vector2(4.0, 4.0)
	_load_next()

func _load_next() -> void:
	if bird != null:
		bird.queue_free()
	var species: String = SPECIES[idx]
	bird = BIRD_SCENE.instantiate()
	bird.position = Vector2(250, 200)
	bird.walk_texture = load("res://assets/Enemies/Birds/%s_flap.png" % species)
	add_child(bird)
	bird.get_node("Sprite2D").texture = load("res://assets/Enemies/Birds/%s_idle.png" % species)
	cam.global_position = Vector2(250, 200)
	frame = 0

func _process(_delta: float) -> void:
	if idx >= SPECIES.size():
		return
	frame += 1
	var species: String = SPECIES[idx]
	if frame == 8:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotB2_%s_idle.png" % species)
		print("GUARDADA shotB2_", species, "_idle")
	if frame == 9:
		# forzar directamente la pose de aleteo para la captura (sin
		# depender del timing real del ciclo de caminata)
		bird.get_node("Sprite2D").texture = bird.walk_texture
	if frame == 12:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotB2_%s_flap.png" % species)
		print("GUARDADA shotB2_", species, "_flap")
		idx += 1
		if idx >= SPECIES.size():
			get_tree().quit()
		else:
			_load_next()

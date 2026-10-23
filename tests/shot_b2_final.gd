extends Node2D

## B2: capturas reales del minijuego final con el fondo nuevo
## (bonus_final_kids_abuelas.png), las barras aereas nuevas y las cajas
## con premios.

const LEVEL := preload("res://scenes/levels/final_screen.tscn")
var level: Node
var cam: Camera2D
var frame := 0
var idx := -1

const SHOTS := [
	{"x": 600.0, "y": 600.0, "zoom": 0.85, "name": "caja_monedas"},
	{"x": 1650.0, "y": 600.0, "zoom": 0.85, "name": "caja_carne"},
	{"x": 2950.0, "y": 600.0, "zoom": 0.85, "name": "caja_vida"},
	{"x": 1500.0, "y": 650.0, "zoom": 0.33, "name": "panoramica"},
]

func _ready() -> void:
	get_window().size = Vector2i(1000, 560)
	level = LEVEL.instantiate()
	add_child(level)
	var luke := level.get_node_or_null("Luke")
	if luke:
		luke.visible = false
	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()
	_next()

func _next() -> void:
	idx += 1
	if idx >= SHOTS.size():
		print("LISTO")
		get_tree().quit()
		return
	var s: Dictionary = SHOTS[idx]
	cam.position = Vector2(float(s.x), float(s.y))
	cam.zoom = Vector2(float(s.zoom), float(s.zoom))
	frame = 0

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 8:
		await RenderingServer.frame_post_draw
		var s: Dictionary = SHOTS[idx]
		get_viewport().get_texture().get_image().save_png("res://../shotB2_%s.png" % s.name)
		print("GUARDADA shotB2_", s.name)
		_next()

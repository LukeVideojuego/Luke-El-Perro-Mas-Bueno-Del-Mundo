extends Node2D

## F8: capturas reales (no-headless) de tiburon, medusa y ave alternando
## entre su pose quieta y su pose de movimiento, con zoom, para confirmar
## visualmente que el aleteo/coleteo/tentaculos se ve y que el recorte
## sigue limpio (sin fondo colandose).

const CASES := [
	{"scene": "res://scenes/enemies/fish_blue.tscn", "label": "shark"},
	{"scene": "res://scenes/enemies/fish_purple.tscn", "label": "jelly"},
	{"scene": "res://scenes/enemies/bird.tscn", "label": "bird"},
]

var idx := 0
var enemy
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(500, 400)
	_spawn()

func _spawn() -> void:
	frame = 0
	var c: Dictionary = CASES[idx]
	enemy = load(c.scene).instantiate()
	enemy.position = Vector2(250, 200)
	add_child(enemy)
	var cam := Camera2D.new()
	cam.position = Vector2(250, 200)
	cam.zoom = Vector2(2.2, 2.2)
	add_child(cam)
	cam.make_current()

func _physics_process(_delta: float) -> void:
	frame += 1
	var c: Dictionary = CASES[idx]
	if frame == 8:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotF8_%s_a.png" % c.label)
	if frame == 20:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotF8_%s_b.png" % c.label)
		for child in get_children():
			child.queue_free()
		idx += 1
		if idx >= CASES.size():
			get_tree().quit()
		else:
			call_deferred("_spawn")

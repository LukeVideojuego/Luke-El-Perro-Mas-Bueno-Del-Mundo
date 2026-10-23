extends Node2D

## F9: captura real (no-headless) del arranque del nivel world_4_boss,
## mostrando a la Serpiente parada en la plataforma mas alta de la arena y
## a Luke lejos, abajo, en su punto de partida.

const LEVEL := preload("res://scenes/levels/world_4_boss.tscn")

var level: Node
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(1000, 900)
	level = LEVEL.instantiate()
	add_child(level)
	var cam := Camera2D.new()
	cam.position = Vector2(600, 480)
	cam.zoom = Vector2(0.75, 0.75)
	add_child(cam)
	cam.make_current()

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 15:
		var boss = level.get_node("SerpentBoss")
		print("boss start pos=", boss.global_position)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotF9_arena_start.png")
		get_tree().quit()

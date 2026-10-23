extends Node2D

## F2: captura real (no-headless) de Luke sobre un tramo de pinchos de
## world_2_level_2, con el corazon perdido visible en el HUD, para
## confirmar visualmente que el dano funciona.

const LEVEL := preload("res://scenes/levels/world_2_level_2.tscn")

var level: Node
var luke: Luke
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(900, 700)
	level = LEVEL.instantiate()
	add_child(level)
	luke = level.get_node("Luke")
	var hud := load("res://scenes/ui/hud.tscn")
	if hud != null:
		var hud_inst = hud.instantiate()
		add_child(hud_inst)
	var cam := Camera2D.new()
	add_child(cam)
	cam.make_current()
	var hazard: Node2D = level.get_node("SpikeHazardOne")
	luke.global_position = hazard.global_position + Vector2(0.0, -40.0)
	cam.global_position = hazard.global_position + Vector2(0, -80)
	cam.zoom = Vector2(1.6, 1.6)

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 90:
		print("vidas=", GameState.lives)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotF2_spikes.png")
		get_tree().quit()

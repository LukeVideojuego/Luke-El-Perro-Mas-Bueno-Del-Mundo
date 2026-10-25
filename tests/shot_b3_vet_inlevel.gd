extends Node2D

## B3: captura real (no-headless, camara del nivel) del veterinario malvado
## ya puesto en un nivel real, para confirmar que el lugar elegido tiene
## espacio para esquivar (no esta pegado a una pared ni a otro peligro).

const LEVEL := preload("res://scenes/levels/world_2_level_1.tscn")

var level: Node
var luke: Node2D
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(1000, 700)
	level = LEVEL.instantiate()
	add_child(level)
	luke = level.get_node("Luke")

func _physics_process(_delta: float) -> void:
	frame += 1
	var vet: Node2D = level.get_node_or_null("VeterinarioMalvado")
	if frame == 2 and vet != null:
		luke.global_position = vet.global_position + Vector2(-260, -20)
	if frame == 100:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotB3_vet_inlevel.png")
		print("GUARDADA shotB3_vet_inlevel")
		get_tree().quit()

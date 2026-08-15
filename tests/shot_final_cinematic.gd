extends Node2D

const CINEMATIC := preload("res://scenes/cinematics/final_cinematic.tscn")
var cinematic: Node
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	cinematic = CINEMATIC.instantiate()
	add_child(cinematic)

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 15:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shot_final_cine_panel1.png")
		print("SAVED panel1")
	if frame == 20:
		var btn = cinematic.get_node("Panel1/Panel1Button")
		btn.pressed.emit()
	if frame == 30:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shot_final_cine_panel2.png")
		print("SAVED panel2")
	if frame == 35:
		get_tree().quit()

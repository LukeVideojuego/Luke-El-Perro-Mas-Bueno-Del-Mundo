extends Node

## A8: captura real (no headless) de Fausto en la pantalla de cierre del
## Mundo 1, a escala real de juego, con zoom, para confirmar que el pelo
## se ve bien en contexto real.

var frame := 0
var inst: Node

func _ready() -> void:
	get_window().size = Vector2i(500, 500)
	var scene: PackedScene = load("res://scenes/cinematics/world1_cheer_screen.tscn")
	inst = scene.instantiate()
	add_child(inst)

func _find_fausto(node: Node) -> Node2D:
	if node.name == "Fausto" and node is Node2D:
		return node
	for c in node.get_children():
		var r := _find_fausto(c)
		if r != null:
			return r
	return null

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 10:
		# Es un CanvasLayer (UI), Camera2D no lo afecta -- en vez de eso
		# escala y reencuadra el Panel directamente para "hacer zoom".
		var fausto: Node2D = _find_fausto(inst)
		var panel: Control = inst.get_node("Panel")
		print("fausto found=", fausto != null, " pos=", fausto.position if fausto else "?")
		if fausto != null:
			panel.scale = Vector2(10, 10)
			panel.position = -fausto.position * 10.0 + Vector2(250, 350)
	if frame == 15:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotA8_fausto_real_ingame.png")
		print("GUARDADA fausto_real_ingame")
		get_tree().quit()

extends Node2D

## F6: captura real (no-headless) de la pantalla de pausa con los botones
## REANUDAR / SALIR AL MENU PRINCIPAL nuevos.

const MAIN_SCENE := preload("res://scenes/main.tscn")

var main: Node
var frame := 0
var phase := 0
var wait_start := 0

func _phase(to: int) -> void:
	phase = to
	wait_start = frame
	print("PHASE->", to, " at frame ", frame)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_window().size = Vector2i(900, 700)
	main = MAIN_SCENE.instantiate()
	add_child(main)

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 10:
		main.start_game()
		_phase(10)
	match phase:
		10:
			if main.intro_cinematic != null and frame - wait_start > 15:
				main.intro_cinematic.get_node("Panel1/Panel1Button").pressed.emit()
				_phase(11)
		11:
			if frame - wait_start > 20:
				main.intro_cinematic.get_node("Panel2/Panel2Button").pressed.emit()
				_phase(12)
		12:
			if frame - wait_start > 20:
				main.intro_cinematic.get_node("Panel3/Panel3Button").pressed.emit()
				_phase(1)
		1:
			if main.active_level != null and not main.is_transitioning:
				_phase(2)
		2:
			if frame - wait_start > 20:
				main.set_paused(true)
				_phase(3)
		3:
			if frame - wait_start > 10:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://../shotF6_pause.png")
				get_tree().quit()

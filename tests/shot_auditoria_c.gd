extends Node2D

## Auditoria comercial: capturas reales de la pantalla de pausa y de la
## pantalla de "te quedaste sin vidas" (game over), usando el flujo real
## de main.tscn (igual que tests/shot_f6_pause.gd y tests/diag_game_over.gd).

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
	get_window().size = Vector2i(1280, 720)
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
			# Pausa a mitad de juego, con Luke ya corriendo un poco.
			if frame - wait_start > 15:
				Input.action_press("move_right")
			if frame - wait_start > 30:
				Input.action_release("move_right")
				main.set_paused(true)
				_phase(3)
		3:
			if frame - wait_start > 10:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://auditoria/00_pausa.png")
				print("GUARDADA 00_pausa")
				main.set_paused(false)
				_phase(4)
		4:
			if frame - wait_start > 10:
				_drain_lives()
				_phase(5)
		5:
			if main.game_over_screen != null and frame - wait_start > 15:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://auditoria/00_game_over.png")
				print("GUARDADA 00_game_over")
				get_tree().quit()
			elif frame - wait_start > 300:
				print("ERROR: no aparecio game_over_screen a tiempo")
				get_tree().quit()

func _drain_lives() -> void:
	var level: Node = main.active_level
	if level == null:
		return
	var luke: Luke = level.get_node_or_null("Luke")
	if luke == null:
		return
	for i in range(GameState.lives + 1):
		luke.defeated.emit()

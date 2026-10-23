extends Node2D

## F1: captura REAL (ventana no-headless) usando la CAMARA PROPIA del nivel
## (la que usa el jugador de verdad), con Luke parado cerca de Bird5/Bird6,
## en dos momentos separados varios segundos, para confirmar visualmente si
## de verdad estan quietos EN PANTALLA (no solo en coordenadas de mundo) y
## si se ven oscuros comparados con un enemigo normal en el mismo cuadro.

const LEVEL := preload("res://scenes/levels/world_1_level_3.tscn")

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
	var b5: Node2D = level.get_node_or_null("Bird5")
	var b6: Node2D = level.get_node_or_null("Bird6")
	if frame == 2:
		# Parar a Luke cerca de los 2 pajaros, con gravedad normal (cae al
		# piso solo) para que la camara del NIVEL (la real del juego) los
		# encuadre como veria el jugador.
		luke.global_position = Vector2(7700, 600)
	if frame == 60:
		print("t0 bird5=", b5.global_position, " bird6=", b6.global_position, " luke=", luke.global_position)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotF1_birds_t0.png")
	if frame == 260:  # ~3.3s despues
		print("t1 bird5=", b5.global_position, " bird6=", b6.global_position, " luke=", luke.global_position)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotF1_birds_t1.png")
		get_tree().quit()

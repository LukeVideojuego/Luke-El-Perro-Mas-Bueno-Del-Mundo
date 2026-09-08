extends Node2D

const MAIN_SCENE := preload("res://scenes/main.tscn")
var main: Node
var frame := 0

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	main = MAIN_SCENE.instantiate()
	add_child(main)

func _save(label: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://../shot_%s.png" % label)
	print("SAVED shot_", label)

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 10:
		main.start_game()
	# start_game ahora hace fade_to_black (~21 frames) antes de instanciar la
	# intro y fade_from_black (~21 frames) después; se deja margen extra.
	if frame == 65:
		await RenderingServer.frame_post_draw
		_save("intro_panel1")
	if frame == 70:
		# simulate clicking "SIGUIENTE" on panel 1
		var p1btn = main.intro_cinematic.get_node("Panel1/Panel1Button")
		p1btn.pressed.emit()
	if frame == 90:
		await RenderingServer.frame_post_draw
		_save("intro_panel2")
	if frame == 95:
		var p2btn = main.intro_cinematic.get_node("Panel2/Panel2Button")
		p2btn.pressed.emit()
	if frame == 115:
		await RenderingServer.frame_post_draw
		_save("intro_panel3")
	if frame == 120:
		get_tree().quit()

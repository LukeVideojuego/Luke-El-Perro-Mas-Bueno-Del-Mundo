extends Node2D

## F5: capturas reales (no-headless) con zoom de Luke con las medias
## aurinegras puestas en cada animacion (idle/walk/walk_b/run/jump/attack),
## para confirmar visualmente que siguen a las 4 patas sin tapar su diseno.

const LUKE_SCENE := preload("res://scenes/player/player.tscn")

var luke: Luke
var frame := 0
var idx := 0

const STEPS := [
	{"name": "idle", "anim": "idle", "jump": false, "attack": false},
	{"name": "walk", "anim": "walk", "jump": false, "attack": false},
	{"name": "run", "anim": "walk", "jump": false, "attack": false, "run": true},
	{"name": "jump", "anim": "jump", "jump": true, "attack": false},
	{"name": "attack", "anim": "attack", "jump": false, "attack": true},
]

func _ready() -> void:
	get_window().size = Vector2i(420, 420)
	GameState.socks_equipped = true
	luke = LUKE_SCENE.instantiate()
	luke.position = Vector2(210, 240)
	add_child(luke)
	var cam := Camera2D.new()
	cam.zoom = Vector2(9.0, 9.0)
	add_child(cam)
	cam.make_current()
	frame = 0

func _physics_process(_delta: float) -> void:
	frame += 1
	var cam := get_viewport().get_camera_2d()
	if cam:
		cam.global_position = luke.global_position + Vector2(0.0, 0.0)
	var step: Dictionary = STEPS[idx]
	if step.get("jump", false) and frame == 2:
		Input.action_press("jump")
	if step.get("jump", false) and frame == 3:
		Input.action_release("jump")
	if step.get("attack", false) and frame == 2:
		Input.action_press("attack")
	if step.get("attack", false) and frame == 3:
		Input.action_release("attack")
	if step.get("run", false):
		Input.action_press("move_right")
		Input.action_press("run")
	elif step.name == "walk":
		Input.action_press("move_right")
		Input.action_release("run")
	else:
		Input.action_release("move_right")
		Input.action_release("run")

	var shot_frame := 14 if step.name != "walk" else 10
	if frame == shot_frame:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotF5_socks_%s.png" % step.name)
	if frame == shot_frame + 6 and step.name == "walk":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotF5_socks_walk_b.png")
	var last_frame: int = shot_frame + 8 if step.name == "walk" else shot_frame + 2
	if frame >= last_frame:
		_release_all()
		idx += 1
		frame = 0
		if idx >= STEPS.size():
			get_tree().quit()
		else:
			luke.velocity = Vector2.ZERO
			luke.position = Vector2(210, 240)

func _release_all() -> void:
	Input.action_release("move_right")
	Input.action_release("run")
	Input.action_release("jump")
	Input.action_release("attack")

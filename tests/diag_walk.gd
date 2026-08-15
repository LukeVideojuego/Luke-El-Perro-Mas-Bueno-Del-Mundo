extends Node2D

## Camina automáticamente a Luke de punta a punta del nivel (manteniendo
## move_right + run, saltando cada tanto) para detectar colisiones
## invisibles/huérfanas: si Luke deja de avanzar en X durante muchos frames
## seguidos estando en el piso, imprime STUCK con su posición.

@export var scene_path := "res://scenes/levels/world_1_level_3.tscn"
@export var max_frames := 3600

var level: Node
var luke: CharacterBody2D
var frame := 0
var last_x := 0.0
var stuck_streak := 0
var max_x_reached := 0.0
var reported_stuck := false

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	Input.action_press("move_right")
	Input.action_press("run")
	var packed := load(scene_path) as PackedScene
	level = packed.instantiate()
	add_child(level)
	luke = level.get_node("Luke")
	last_x = luke.global_position.x
	max_x_reached = luke.global_position.x

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame % 50 == 0:
		Input.action_press("jump")
	if frame % 50 == 5:
		Input.action_release("jump")

	if frame % 12 == 0:
		Input.action_press("attack")
	if frame % 12 == 3:
		Input.action_release("attack")

	if frame % 30 == 0:
		print("t=", frame, " x=", luke.global_position.x, " y=", luke.global_position.y, " vel=", luke.velocity, " onfloor=", luke.is_on_floor())
	if frame % 20 == 0:
		var dx = luke.global_position.x - last_x
		if dx < 1.0 and luke.is_on_floor():
			stuck_streak += 1
		else:
			stuck_streak = 0
		last_x = luke.global_position.x
		max_x_reached = maxf(max_x_reached, luke.global_position.x)
		if stuck_streak >= 6 and not reported_stuck:
			print("STUCK at frame ", frame, " x=", luke.global_position.x, " y=", luke.global_position.y, " onwall=", luke.is_on_wall(), " onfloor=", luke.is_on_floor())
			reported_stuck = true
		if stuck_streak == 0 and reported_stuck:
			reported_stuck = false
			print("RECOVERED at frame ", frame, " x=", luke.global_position.x)

	if GameState.is_level_complete:
		print("LEVEL COMPLETE at frame ", frame, " x=", luke.global_position.x)
		get_tree().quit()
		return

	if frame >= max_frames:
		print("DONE max_x_reached=", max_x_reached, " final_x=", luke.global_position.x)
		get_tree().quit()

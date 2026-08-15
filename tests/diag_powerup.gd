extends Node2D

const LEVEL := preload("res://scenes/levels/world_1_level_3.tscn")
var level: Node
var luke: CharacterBody2D
var frame := 0

func _ready() -> void:
	level = LEVEL.instantiate()
	add_child(level)
	luke = level.get_node("Luke")
	var powerup := level.get_node("SpeedPowerUp")
	print("SpeedPowerUp found at ", powerup.global_position)
	luke.global_position = powerup.global_position

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 10:
		print("after pickup: has_speed_boost=", luke.has_speed_boost, " modulate=", luke.animated_sprite.modulate)
		Input.action_press("move_right")
		Input.action_press("run")
	if frame == 15:
		print("velocity with boost=", luke.velocity.x, " (walk_speed*run*1.5 expected around ", luke.run_speed * luke.speed_boost_multiplier, ")")
	if frame == 20:
		get_tree().quit()

extends Node2D

const LEVEL := preload("res://scenes/levels/world_1_level_3.tscn")
var level: Node
var luke: CharacterBody2D
var finish: Node
var frame := 0

func _ready() -> void:
	level = LEVEL.instantiate()
	add_child(level)
	luke = level.get_node("Luke")
	finish = level.get_node("Finish")
	print("finish global_position=", finish.global_position)
	luke.global_position = finish.global_position
	luke.velocity = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 10:
		print("is_level_complete=", GameState.is_level_complete, " luke_pos=", luke.global_position)
		get_tree().quit()

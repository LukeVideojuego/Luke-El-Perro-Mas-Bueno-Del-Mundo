extends Node2D

const LEVEL := preload("res://scenes/levels/final_screen.tscn")
var level: Node
var frame := 0
var positions: Array[float] = []

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	level = LEVEL.instantiate()
	add_child(level)

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame % 30 == 0 and frame <= 180:
		var p = level.get_node("PersonGreen")
		positions.append(p.global_position.x)
		print("frame ", frame, " PersonGreen.x=", p.global_position.x, " sprite.y=", p.sprite.position.y)
	if frame == 190:
		var moved := false
		for i in range(1, positions.size()):
			if absf(positions[i] - positions[0]) > 5.0:
				moved = true
		print("PASS" if moved else "FAIL", ": PersonGreen se movió de su posición inicial")
		get_tree().quit()

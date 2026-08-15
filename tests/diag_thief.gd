extends Node2D

@export var scene_path := "res://scenes/levels/world_1_level_3.tscn"
@export var enemy_names := "ThiefOne,ThiefTwo"
var level: Node
var enemies := []
var last_x := []
var stuck := []
var frame := 0

func _ready() -> void:
	var packed := load(scene_path) as PackedScene
	level = packed.instantiate()
	add_child(level)
	for n in enemy_names.split(","):
		var e = level.get_node_or_null(n)
		if e != null:
			enemies.append(e)
			last_x.append(e.global_position.x)
			stuck.append(0)

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame % 30 == 0:
		var line := "frame=" + str(frame)
		for i in range(enemies.size()):
			var e = enemies[i]
			var dx = absf(e.global_position.x - last_x[i])
			if dx < 0.5:
				stuck[i] += 1
			else:
				stuck[i] = 0
			line += " | %s x=%.1f onwall=%s onfloor=%s stuck=%d" % [e.name, e.global_position.x, e.is_on_wall(), e.is_on_floor(), stuck[i]]
			last_x[i] = e.global_position.x
			if stuck[i] >= 5:
				line += " <<< STUCK"
		print(line)
	if frame >= 1200:
		get_tree().quit()

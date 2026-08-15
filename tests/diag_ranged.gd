extends Node2D

const LEVEL := preload("res://scenes/levels/world_1_level_2.tscn")

var level: Node
var luke: CharacterBody2D
var thief: Node
var frame := 0
var fail_count := 0
var damaged_seen := false

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	level = LEVEL.instantiate()
	add_child(level)
	luke = level.get_node("Luke")
	thief = level.get_node("ThiefOne")
	luke.damaged.connect(func(): damaged_seen = true)
	_check(thief.can_ranged_attack, "el ladrón tiene ataque a distancia habilitado")
	_check(thief.ranged_projectile_scene != null, "el ladrón tiene una escena de proyectil asignada")

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 5:
		# fuera de rango de golpe cuerpo a cuerpo, dentro del rango a distancia
		luke.global_position = thief.global_position - Vector2(260, 0)
		luke.velocity = Vector2.ZERO
	if frame == 55:
		get_window().size = Vector2i(1280, 720)
		var cam := Camera2D.new()
		cam.zoom = Vector2(0.9, 0.9)
		cam.position = luke.global_position + Vector2(120, -60)
		add_child(cam)
		cam.make_current()
	if frame == 60:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shot_ranged_attack.png")
		print("SAVED shot_ranged_attack")
	if frame == 200:
		_check(damaged_seen, "el proyectil del ladrón golpea y daña a Luke a distancia")
		print("RESULTADO: ", fail_count, " fallos")
		get_tree().quit()

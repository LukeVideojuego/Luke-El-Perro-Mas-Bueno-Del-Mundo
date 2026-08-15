extends Node2D

const LEVEL := preload("res://scenes/levels/world_1_boss.tscn")
var level: Node
var luke: CharacterBody2D
var boss: Node
var frame := 0
var fail_count := 0
var damaged_seen := false
var projectile_seen := false
var screenshot_taken := false

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
	boss = level.get_node("ThiefBoss")
	luke.damaged.connect(func(): damaged_seen = true)
	_check(boss.can_ranged_attack, "el jefe tiene ataque a distancia habilitado")

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 5:
		luke.global_position = boss.global_position - Vector2(300, 0)
		luke.velocity = Vector2.ZERO
	for child in level.get_children():
		if child is EnemyProjectile:
			projectile_seen = true
	if frame > 20 and frame < 200 and not screenshot_taken:
		for child in level.get_children():
			if child is EnemyProjectile:
				screenshot_taken = true
				get_window().size = Vector2i(1280, 720)
				var cam := Camera2D.new()
				cam.zoom = Vector2(0.9, 0.9)
				cam.position = (luke.global_position + boss.global_position) / 2.0
				add_child(cam)
				cam.make_current()
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://../shot_boss_projectile.png")
				print("SAVED shot_boss_projectile")
	if frame == 250:
		_check(projectile_seen, "el jefe efectivamente lanza un proyectil")
		_check(damaged_seen, "el ataque del jefe (a distancia o cuerpo a cuerpo) daña a Luke")
		print("RESULTADO: ", fail_count, " fallos")
		get_tree().quit()

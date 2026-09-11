extends Node2D

const LEVEL := preload("res://scenes/levels/world_4_boss.tscn")
var level: Node
var boss: Node
var sprite: Sprite2D
var frame := 0
var cam: Camera2D
var got_idle := false
var got_jump := false
var got_power := false

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	level = LEVEL.instantiate()
	add_child(level)
	boss = level.get_node("SerpentBoss")
	sprite = boss.get_node("Sprite2D")

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 5:
		cam = Camera2D.new()
		cam.zoom = Vector2(1.1, 1.1)
		add_child(cam)
		cam.make_current()
	if frame >= 8:
		cam.position = boss.global_position + Vector2(0, -150)
	if frame == 15 and not got_idle:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shot_serpent_idle.png")
		print("SAVED idle onfloor=", boss.is_on_floor(), " tex=", sprite.texture.resource_path)
		got_idle = true
	if not boss.is_on_floor() and not got_jump and frame > 15:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shot_serpent_jump.png")
		print("SAVED jump tex=", sprite.texture.resource_path)
		got_jump = true
	if sprite.texture.resource_path.contains("power") and not got_power and frame > 15:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shot_serpent_power.png")
		print("SAVED power tex=", sprite.texture.resource_path)
		got_power = true
	if frame >= 150 or (got_idle and got_jump and got_power):
		print("done idle=", got_idle, " jump=", got_jump, " power=", got_power)
		get_tree().quit()

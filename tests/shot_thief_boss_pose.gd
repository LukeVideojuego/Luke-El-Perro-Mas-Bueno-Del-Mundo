extends Node2D

const LEVEL := preload("res://scenes/levels/world_1_boss.tscn")
var level: Node
var boss: Node
var sprite: Sprite2D
var frame := 0
var cam: Camera2D
var base_scale: Vector2

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	level = LEVEL.instantiate()
	add_child(level)
	boss = level.get_node("ThiefBoss")
	sprite = boss.get_node("Sprite2D")
	base_scale = sprite.scale
	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()

func _physics_process(_delta: float) -> void:
	frame += 1
	cam.position = boss.global_position + Vector2(0, -150)
	if frame == 10:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shot_thief_ground.png")
		print("SAVED ground scale=", sprite.scale, " base=", base_scale)
	if frame == 20:
		boss.velocity.y = -700.0
		await get_tree().physics_frame
	if frame == 24:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shot_thief_airborne.png")
		print("SAVED airborne scale=", sprite.scale, " on_floor=", boss.is_on_floor())
	if frame == 40:
		boss._power_use_diagonal = false
		boss._fire_power()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shot_thief_attack.png")
		print("SAVED attack modulate=", sprite.modulate, " scale=", sprite.scale)
	if frame >= 45:
		get_tree().quit()

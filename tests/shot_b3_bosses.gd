extends Node2D

## B3: capturas reales in-engine de las 3 mecanicas nuevas por jefe:
## Don Sombra semitransparente (fundido en sombras), la Bruja con la nube
## de humo del teletransporte, y Gran Codicia con sus 2 ayudantes recien
## llamados a mitad de vida.

var level: Node
var boss
var cam: Camera2D
var frame := 0
var stage := 0

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()
	_start_thief()

func _start_thief() -> void:
	stage = 0
	level = load("res://scenes/levels/world_1_boss.tscn").instantiate()
	add_child(level)
	boss = level.get_node("ThiefBoss")
	boss._shadow_timer = boss.shadow_fade_interval - 0.02
	frame = 0

func _start_witch() -> void:
	stage = 1
	level.queue_free()
	level = load("res://scenes/levels/world_2_boss.tscn").instantiate()
	add_child(level)
	boss = level.get_node("WitchBoss")
	boss._teleport_timer = boss.teleport_interval - 0.02
	frame = 0

func _start_corrupt() -> void:
	stage = 2
	level.queue_free()
	level = load("res://scenes/levels/world_3_boss.tscn").instantiate()
	add_child(level)
	boss = level.get_node("CorruptBoss")
	frame = 0

func _physics_process(_delta: float) -> void:
	frame += 1
	cam.position = boss.global_position + Vector2(0, -150)
	cam.zoom = Vector2(0.75, 0.75)
	if stage == 0:
		if frame == 90 and boss._is_shadow_invulnerable:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://../shotB3_don_sombra_invulnerable.png")
			print("SAVED don_sombra_invulnerable")
			_start_witch()
		elif frame > 240:
			print("WARN: Don Sombra no entro invulnerable, sigo de todas formas")
			_start_witch()
	elif stage == 1:
		var has_smoke := level.get_children().any(func(c): return c.get_script() == preload("res://scripts/effects/smoke_puff.gd"))
		if has_smoke and frame > 50:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://../shotB3_bruja_teletransporte.png")
			print("SAVED bruja_teletransporte")
			_start_corrupt()
		elif frame > 240:
			print("WARN: no aparecio humo de teletransporte, sigo de todas formas")
			_start_corrupt()
	elif stage == 2:
		if boss.health > boss.max_health / 2:
			boss.receive_attack(null, 1)
		if boss._allies_summoned and frame > 10:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://../shotB3_gran_codicia_ayudantes.png")
			print("SAVED gran_codicia_ayudantes")
			print("LISTO")
			get_tree().quit()
		elif frame > 240:
			print("WARN: no se llamaron ayudantes")
			print("LISTO")
			get_tree().quit()

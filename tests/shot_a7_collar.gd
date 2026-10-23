extends Node2D

## A7: capturas reales con zoom de Luke con el collar dorado puesto, en
## idle/walk/jump/attack, para calibrar el ancla de posicion.

const LUKE_SCENE := preload("res://scenes/player/player.tscn")
var luke: Luke
var frame := 0
var idx := 0
const ANIMS := ["idle", "walk", "jump", "attack"]

func _ready() -> void:
	get_window().size = Vector2i(420, 420)
	GameState.collar_equipped = true
	luke = LUKE_SCENE.instantiate()
	luke.gravity = 0.0
	luke.position = Vector2(210, 210)
	add_child(luke)
	var cam := Camera2D.new()
	cam.position = Vector2(210, 210)
	cam.zoom = Vector2(6.0, 6.0)
	add_child(cam)
	cam.make_current()

func _physics_process(_delta: float) -> void:
	frame += 1
	luke.set_physics_process(false)
	luke.animated_sprite.animation = ANIMS[idx]
	luke.facing_direction = 1
	luke._update_cosmetics()
	if frame == 10:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../shotA7_collar_%s.png" % ANIMS[idx])
		print("GUARDADA ", ANIMS[idx])
		idx += 1
		frame = 0
		if idx >= ANIMS.size():
			get_tree().quit()

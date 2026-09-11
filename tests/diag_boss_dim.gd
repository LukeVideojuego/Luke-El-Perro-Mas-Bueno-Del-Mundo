extends Node2D

## Punto 12: en los niveles de jefe, el fondo y el piso deben quedar a un
## tercio del brillo actual, pero personajes/monedas/cajas/interactivos NO
## deben cambiar. Verifica ambas cosas en los 4 niveles de jefe.

const LEVELS := [
	"res://scenes/levels/world_1_boss.tscn",
	"res://scenes/levels/world_2_boss.tscn",
	"res://scenes/levels/world_3_boss.tscn",
	"res://scenes/levels/world_4_boss.tscn",
]

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _is_dim(c: Color) -> bool:
	return c.r < 0.5 and c.g < 0.5 and c.b < 0.5

func _ready() -> void:
	for path in LEVELS:
		var level: Node = load(path).instantiate()
		add_child(level)
		var bg: Sprite2D = level.get_node("Background")
		var block_top: Sprite2D = level.get_node("Ground/BlockTop")
		var block_body: Sprite2D = level.get_node("Ground/BlockBody")
		var plat1: Sprite2D = level.get_node("PlatformOne/Visual")
		_check(_is_dim(bg.modulate), "%s: fondo oscurecido (%s)" % [path, bg.modulate])
		_check(_is_dim(block_top.modulate), "%s: piso (BlockTop) oscurecido (%s)" % [path, block_top.modulate])
		_check(_is_dim(block_body.modulate), "%s: piso (BlockBody) oscurecido (%s)" % [path, block_body.modulate])
		_check(_is_dim(plat1.modulate), "%s: plataforma oscurecida (%s)" % [path, plat1.modulate])

		var coin: Sprite2D = level.get_node("CoinA/Icon")
		var box: Sprite2D = level.get_node("BoxA/Sprite2D")
		var boss: Node = level.get_children().filter(func(c): return c is BossBase)[0]
		var luke: Luke = level.get_node("Luke")
		_check(coin.modulate == Color(1, 1, 1, 1), "%s: moneda SIN cambios (%s)" % [path, coin.modulate])
		_check(box.modulate == Color(1, 1, 1, 1), "%s: caja SIN cambios (%s)" % [path, box.modulate])
		_check(not _is_dim(boss.get_node("Sprite2D").modulate), "%s: jefe SIN oscurecer (%s)" % [path, boss.get_node("Sprite2D").modulate])
		_check(luke.animated_sprite.modulate == Color(1, 1, 1, 1), "%s: Luke SIN cambios" % path)

		level.queue_free()

	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

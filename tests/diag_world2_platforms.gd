extends Node2D

## Punto 8: las plataformas aereas de Corazones de Oro (Mundo 2) a veces no
## permitian avanzar porque una de ellas era una moving_platform oscilante
## -- si Luke llegaba cuando estaba en el otro extremo de su recorrido, el
## salto fallaba. Reemplazadas por plataformas fijas. Verifica que ya no
## quedan MovingPlatform en estos 3 niveles y que la nueva plataforma fija
## esta presente y tiene colision real.

const LEVELS := [
	{"path": "res://scenes/levels/world_2_level_1.tscn", "name": "PlatformEleven"},
	{"path": "res://scenes/levels/world_2_level_2.tscn", "name": "PlatformSeven"},
	{"path": "res://scenes/levels/world_2_level_3.tscn", "name": "PlatformNine"},
]

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	for cfg in LEVELS:
		var level: Node = load(cfg.path).instantiate()
		add_child(level)
		var moving_count := 0
		for child in level.get_children():
			if child is MovingPlatform:
				moving_count += 1
		_check(moving_count == 0, "%s: ya no tiene plataformas moviles" % cfg.path)
		var plat: Node = level.get_node_or_null(cfg.name)
		_check(plat != null and plat is StaticBody2D, "%s: %s existe como plataforma fija" % [cfg.path, cfg.name])
		if plat != null:
			var shape := plat.get_node_or_null("CollisionShape2D")
			_check(shape != null and shape.shape != null, "%s: %s tiene colision real" % [cfg.path, cfg.name])
		level.queue_free()
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

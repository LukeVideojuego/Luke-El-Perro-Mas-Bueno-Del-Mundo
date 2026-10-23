extends Node2D

## B1: chequeo rapido de que los 4 niveles bonus cargan sin error y tienen
## la estructura minima esperada (LukeStart, Camera2D, FallBoundary, 8
## barras + StartPad, 2 vidas + 4 monedas + 2 premios de tienda).

const LEVELS := [
	"res://scenes/levels/bonus_world_1.tscn",
	"res://scenes/levels/bonus_world_2.tscn",
	"res://scenes/levels/bonus_world_3.tscn",
	"res://scenes/levels/bonus_world_4.tscn",
]

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	for path in LEVELS:
		var level: Node = load(path).instantiate()
		add_child(level)
		_check(level.get_node_or_null("LukeStart") != null, "%s: tiene LukeStart" % path)
		_check(level.get_node_or_null("Camera2D") != null, "%s: tiene Camera2D" % path)
		_check(level.get_node_or_null("FallBoundary") != null, "%s: tiene FallBoundary" % path)
		_check(level.get_node_or_null("FinishMarker") != null, "%s: tiene FinishMarker" % path)
		_check(level.get_node_or_null("StartPad") != null, "%s: tiene StartPad" % path)
		var bar_count := 0
		var reward_count := 0
		var life_count := 0
		var shop_count := 0
		for child in level.get_children():
			if String(child.name).begins_with("Bar") and not String(child.name).ends_with("Reward"):
				bar_count += 1
			if child is BonusReward:
				reward_count += 1
				if child.reward_type == BonusReward.RewardType.LIFE:
					life_count += 1
				if child.reward_type == BonusReward.RewardType.SHOP_ITEM:
					shop_count += 1
		_check(bar_count == 8, "%s: tiene 8 barras (tiene %d)" % [path, bar_count])
		_check(life_count == 2, "%s: 2 premios de vida (tiene %d)" % [path, life_count])
		_check(shop_count == 2, "%s: 2 premios de tienda (tiene %d)" % [path, shop_count])
		level.queue_free()
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

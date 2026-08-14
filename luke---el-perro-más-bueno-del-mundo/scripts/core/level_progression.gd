class_name LevelProgression
extends RefCounted

## Registro central de progresión: ampliar aquí evita rutas y lógica duplicadas.

const LEVELS := {
	"world_1_level_1": {"world": 1, "order": 1, "scene": "res://scenes/levels/test_level.tscn", "next": "world_1_level_2"},
	"world_1_level_2": {"world": 1, "order": 2, "scene": "res://scenes/levels/world_1_level_2.tscn", "next": "world_1_level_3"},
	"world_1_level_3": {"world": 1, "order": 3, "scene": "res://scenes/levels/world_1_level_3.tscn", "next": "world_1_boss"},
	"world_1_boss": {"world": 1, "order": 4, "scene": "res://scenes/levels/world_1_boss.tscn", "next": "world_2_level_1"},
	"world_2_level_1": {"world": 2, "order": 1, "scene": "res://scenes/levels/world_2_level_1.tscn", "next": "world_2_level_2"},
	"world_2_level_2": {"world": 2, "order": 2, "scene": "res://scenes/levels/world_2_level_2.tscn", "next": "world_2_level_3"},
	"world_2_level_3": {"world": 2, "order": 3, "scene": "res://scenes/levels/world_2_level_3.tscn", "next": "world_2_boss"},
	"world_2_boss": {"world": 2, "order": 4, "scene": "res://scenes/levels/world_2_boss.tscn", "next": "world_3_level_1"},
	"world_3_level_1": {"world": 3, "order": 1, "scene": "res://scenes/levels/world_3_level_1.tscn", "next": "world_3_level_2"},
	"world_3_level_2": {"world": 3, "order": 2, "scene": "res://scenes/levels/world_3_level_2.tscn", "next": "world_3_level_3"},
	"world_3_level_3": {"world": 3, "order": 3, "scene": "res://scenes/levels/world_3_level_3.tscn", "next": "world_3_boss"},
	"world_3_boss": {"world": 3, "order": 4, "scene": "res://scenes/levels/world_3_boss.tscn", "next": "world_4_level_1"},
	"world_4_level_1": {"world": 4, "order": 1, "scene": "res://scenes/levels/world_4_level_1.tscn", "next": "world_4_level_2"},
	"world_4_level_2": {"world": 4, "order": 2, "scene": "res://scenes/levels/world_4_level_2.tscn", "next": "world_4_level_3"},
	"world_4_level_3": {"world": 4, "order": 3, "scene": "res://scenes/levels/world_4_level_3.tscn", "next": "world_4_boss"},
	"world_4_boss": {"world": 4, "order": 4, "scene": "res://scenes/levels/world_4_boss.tscn", "next": "final_screen"},
	"final_screen": {"world": 0, "order": 0, "scene": "res://scenes/levels/final_screen.tscn", "next": ""}
}

static func get_scene_path(level_id: String) -> String:
	return String(LEVELS.get(level_id, {}).get("scene", ""))

static func get_next_level(level_id: String) -> String:
	return String(LEVELS.get(level_id, {}).get("next", ""))

static func get_world(level_id: String) -> int:
	return int(LEVELS.get(level_id, {}).get("world", 0))

static func get_order(level_id: String) -> int:
	return int(LEVELS.get(level_id, {}).get("order", 0))

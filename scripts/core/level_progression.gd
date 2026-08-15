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

## Nombres oficiales de mundo y jefe (hoja de referencia visual del proyecto).
const WORLD_NAMES := {
	1: "Ciudad Segura",
	2: "Corazones de Oro",
	3: "El Reino del Poder",
	4: "Guardianes de la Naturaleza",
}

const BOSS_NAMES := {
	1: "Don Sombra",
	2: "La Bruja del Olvido",
	3: "El Gran Codicia",
	4: "La Reina Veneno",
}

static func get_world_name(world: int) -> String:
	return String(WORLD_NAMES.get(world, "Mundo %d" % world))

static func get_boss_name(world: int) -> String:
	return String(BOSS_NAMES.get(world, "Jefe del Mundo %d" % world))

## Contraseñas simples y ampliables: "LUKE" + número de orden global de dos
## dígitos (01..16). Pensadas para que un jugador pueda saltar directo a
## cualquier nivel sin tener que jugar los anteriores.
const PASSWORDS := {
	"LUKE01": "world_1_level_1",
	"LUKE02": "world_1_level_2",
	"LUKE03": "world_1_level_3",
	"LUKE04": "world_1_boss",
	"LUKE05": "world_2_level_1",
	"LUKE06": "world_2_level_2",
	"LUKE07": "world_2_level_3",
	"LUKE08": "world_2_boss",
	"LUKE09": "world_3_level_1",
	"LUKE10": "world_3_level_2",
	"LUKE11": "world_3_level_3",
	"LUKE12": "world_3_boss",
	"LUKE13": "world_4_level_1",
	"LUKE14": "world_4_level_2",
	"LUKE15": "world_4_level_3",
	"LUKE16": "world_4_boss",
}

## Devuelve el level_id asociado a una contraseña, o "" si no es válida.
## No distingue mayúsculas/minúsculas ni espacios alrededor.
static func get_level_id_from_password(code: String) -> String:
	var normalized := code.strip_edges().to_upper()
	return String(PASSWORDS.get(normalized, ""))

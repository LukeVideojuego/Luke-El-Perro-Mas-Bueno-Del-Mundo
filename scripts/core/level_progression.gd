class_name LevelProgression
extends RefCounted

## Registro central de progresión: ampliar aquí evita rutas y lógica duplicadas.

const LEVELS := {
	"world_1_level_1": {"world": 1, "order": 1, "scene": "res://scenes/levels/world_1_level_1.tscn", "next": "world_1_level_2"},
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

## Orden global 1..16 (Mundo 1 Nivel 1 = 1, ..., Mundo 4 Jefe = 16), usado
## por el mapa del mundo para saber qué niveles están desbloqueados.
static func get_global_order(level_id: String) -> int:
	var world := get_world(level_id)
	var order := get_order(level_id)
	if world <= 0 or order <= 0:
		return 0
	return (world - 1) * 4 + order

static func get_level_id_for_global_order(global_order: int) -> String:
	for level_id in LEVELS:
		if get_global_order(level_id) == global_order:
			return level_id
	return ""

## A5: antes eran "LUKE" + el numero de orden global (LUKE01..LUKE16), asi
## que cualquiera podia adivinar la del jefe final (LUKE16) sin jugar nada.
## Ahora son 16 palabras cortas del universo del juego + un digito SIN
## relacion con el orden del nivel ni entre si (ver el resumen del commit
## para la lista completa) -- faciles de leer para un chico, pero ya no
## adivinables por patron.
const PASSWORDS := {
	"PATA8": "world_1_level_1",
	"HUESO3": "world_1_level_2",
	"CAPA5": "world_1_level_3",
	"NOBLE2": "world_1_boss",
	"AMOR9": "world_2_level_1",
	"FIEL1": "world_2_level_2",
	"GORRO6": "world_2_level_3",
	"VALOR4": "world_2_boss",
	"COLA7": "world_3_level_1",
	"BUENO3": "world_3_level_2",
	"SALTO9": "world_3_level_3",
	"HEROE1": "world_3_boss",
	"AMIGO5": "world_4_level_1",
	"CORRE2": "world_4_level_2",
	"PERRO8": "world_4_level_3",
	"PELO6": "world_4_boss",
}

## Devuelve el level_id asociado a una contraseña, o "" si no es válida.
## No distingue mayúsculas/minúsculas ni espacios alrededor.
static func get_level_id_from_password(code: String) -> String:
	var normalized := code.strip_edges().to_upper()
	return String(PASSWORDS.get(normalized, ""))

## A5: busqueda inversa (level_id -> contraseña), usada por level_base.gd
## para mostrar en pantalla la contraseña del nivel recien completado.
static func get_password_for_level(level_id: String) -> String:
	for code in PASSWORDS:
		if PASSWORDS[code] == level_id:
			return String(code)
	return ""

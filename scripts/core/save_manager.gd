extends Node

## Persistencia simple en disco (JSON) del progreso del jugador.
## No depende de GameState en el orden de autoload: se accede vía el
## nombre global "SaveManager" desde game_state.gd y main.gd.

const SAVE_PATH := "user://savegame.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	var data := {
		"current_level_id": GameState.current_level_id,
		"checkpoint_id": GameState.checkpoint_id,
		"checkpoint_x": GameState.checkpoint_position.x,
		"checkpoint_y": GameState.checkpoint_position.y,
		"lives": GameState.lives,
		"continues_left": GameState.continues_left,
		"coins": GameState.coins,
		"has_seen_intro": GameState.has_seen_intro,
		"has_seen_world1_cheer": GameState.has_seen_world1_cheer,
		"highest_order_reached": GameState.highest_order_reached,
		"bone_throw_unlocked": GameState.bone_throw_unlocked,
		"owned_items": GameState.owned_items,
		"equipped_hat": GameState.equipped_hat,
		"suit_equipped": GameState.suit_equipped,
		"socks_equipped": GameState.socks_equipped,
		"pending_star": GameState.pending_star,
		"pending_boots": GameState.pending_boots,
		"pending_aura": GameState.pending_aura,
		"pending_hearts": GameState.pending_hearts,
		"bark_ammo": GameState.bark_ammo,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
	file.close()

## Carga los datos guardados en GameState y deja lista la bandera de
## reanudación. Devuelve false si no había partida guardada o el archivo
## está corrupto.
func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = parsed
	if String(data.get("current_level_id", "")).is_empty():
		return false
	GameState.current_level_id = String(data.get("current_level_id", ""))
	GameState.checkpoint_id = String(data.get("checkpoint_id", "start"))
	GameState.checkpoint_position = Vector2(
		float(data.get("checkpoint_x", 0.0)),
		float(data.get("checkpoint_y", 0.0))
	)
	GameState.lives = int(data.get("lives", GameState.DEFAULT_LIVES))
	GameState.continues_left = clampi(int(data.get("continues_left", GameState.DEFAULT_CONTINUES)), 0, GameState.DEFAULT_CONTINUES)
	GameState.coins = int(data.get("coins", 0))
	GameState.has_seen_intro = bool(data.get("has_seen_intro", false))
	GameState.has_seen_world1_cheer = bool(data.get("has_seen_world1_cheer", false))
	GameState.highest_order_reached = maxi(1, int(data.get("highest_order_reached", 1)))
	GameState.bone_throw_unlocked = bool(data.get("bone_throw_unlocked", false))
	GameState.owned_items.clear()
	for entry in data.get("owned_items", []):
		GameState.owned_items.append(String(entry))
	GameState.equipped_hat = String(data.get("equipped_hat", ""))
	GameState.suit_equipped = bool(data.get("suit_equipped", false))
	GameState.socks_equipped = bool(data.get("socks_equipped", false))
	GameState.pending_star = bool(data.get("pending_star", false))
	GameState.pending_boots = bool(data.get("pending_boots", false))
	GameState.pending_aura = bool(data.get("pending_aura", false))
	GameState.pending_hearts = int(data.get("pending_hearts", 0))
	GameState.bark_ammo = maxi(0, int(data.get("bark_ammo", 0)))
	GameState.is_level_complete = false
	# F4: si se guardo desde la tienda (antes de entrar a un nivel, nunca a
	# mitad de uno), checkpoint_position queda en (0,0) a proposito -- igual
	# que prepare_next_level() antes de cualquier nivel nuevo normal. Sin
	# este chequeo, resume_at_checkpoint=true a secas hacia que
	# begin_level() reubicara a Luke literalmente en el origen del mundo
	# (0,0) en vez de en el SpawnPoint real del nivel.
	GameState.resume_at_checkpoint = GameState.checkpoint_position != Vector2.ZERO
	GameState.clear_out_of_lives()
	return true

## Solo lee has_seen_intro sin tocar el resto del estado; se usa al arrancar
## el juego para saber si "Comenzar juego" debe mostrar la introducción.
func peek_has_seen_intro() -> bool:
	return bool(_peek_field("has_seen_intro", false))

## Igual que peek_has_seen_intro() pero para la pantalla de los 7 niños
## que se muestra una sola vez al completar el Mundo 1.
func peek_has_seen_world1_cheer() -> bool:
	return bool(_peek_field("has_seen_world1_cheer", false))

## Solo lee el progreso desbloqueado, sin tocar el resto del estado; se usa
## para poblar el mapa del mundo aunque el jugador no haya tocado "Cargar
## partida" todavía.
func peek_highest_order_reached() -> int:
	return maxi(1, int(_peek_field("highest_order_reached", 1)))

func _peek_field(key: String, default_value):
	if not has_save():
		return default_value
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return default_value
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return default_value
	return parsed.get(key, default_value)

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
		"coins": GameState.coins,
		"has_seen_intro": GameState.has_seen_intro,
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
	GameState.coins = int(data.get("coins", 0))
	GameState.has_seen_intro = bool(data.get("has_seen_intro", false))
	GameState.is_level_complete = false
	GameState.resume_at_checkpoint = true
	return true

## Solo lee has_seen_intro sin tocar el resto del estado; se usa al arrancar
## el juego para saber si "Comenzar juego" debe mostrar la introducción.
func peek_has_seen_intro() -> bool:
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
	return bool(parsed.get("has_seen_intro", false))

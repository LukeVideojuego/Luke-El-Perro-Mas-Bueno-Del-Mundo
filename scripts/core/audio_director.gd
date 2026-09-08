extends Node

## Punto único de audio: efectos de sonido puntuales (play_event) y música de
## fondo en loop por pantalla/mundo (play_music). Los archivos son WAV
## sintetizados en assets/audio/{sfx,music}/ (ver referencia_visual/ para el
## resto del arte; el audio no tuvo una referencia real provista, así que se
## generó en estilo chiptune/8-bit acorde al pixel art del juego).

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"

const SFX_FILES := {
	&"jump": "jump.wav",
	&"attack": "attack.wav",
	&"damage": "damage.wav",
	&"aura_on": "aura_on.wav",
	&"aura_lost": "aura_lost.wav",
	&"coin_pickup": "coin_pickup.wav",
	&"meat_pickup": "meat_pickup.wav",
	&"hug": "hug.wav",
	&"powerup_invincibility": "powerup_invincibility.wav",
	&"powerup_speed": "powerup_speed.wav",
	&"level_complete": "level_complete.wav",
	&"boss_hit": "boss_hit.wav",
	&"enemy_defeat": "enemy_defeat.wav",
	&"pause": "pause.wav",
}

const MUSIC_FILES := {
	"menu": "menu.wav",
	"world1": "world1.wav",
	"world2": "world2.wav",
	"world3": "world3.wav",
	"world4": "world4.wav",
	"final": "final.wav",
}

const SFX_POOL_SIZE := 6

## Offsets relativos por efecto (sumados a sfx_volume_db). Pensados para que
## ningún efecto tape a otro: los eventos "importantes" (daño, monedas, golpes
## de jefe) se oyen un poco más fuerte; los muy frecuentes (salto, ataque)
## quedan más discretos para no cansar; los de UI (pausa) van bajos.
const SFX_VOLUME_OFFSET := {
	&"jump": -3.0,
	&"attack": -2.0,
	&"damage": 2.0,
	&"aura_on": -1.0,
	&"aura_lost": -1.0,
	&"coin_pickup": 0.0,
	&"meat_pickup": 1.0,
	&"hug": -1.0,
	&"powerup_invincibility": 0.0,
	&"powerup_speed": 0.0,
	&"level_complete": 1.5,
	&"boss_hit": 1.5,
	&"enemy_defeat": -1.5,
	&"pause": -4.0,
}

const MUSIC_CROSSFADE_SEC := 0.9

var _sfx_streams: Dictionary = {}
var _music_streams: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _music_players: Array[AudioStreamPlayer] = []
var _active_music_index := 0
var _current_music := ""
var _music_tween: Tween

@export var sfx_volume_db := -6.0
@export var music_volume_db := -16.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for key in SFX_FILES:
		_sfx_streams[key] = load(SFX_DIR + SFX_FILES[key])
	for key in MUSIC_FILES:
		_music_streams[key] = load(MUSIC_DIR + MUSIC_FILES[key])
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.volume_db = sfx_volume_db
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_sfx_players.append(p)
	for i in 2:
		var mp := AudioStreamPlayer.new()
		mp.volume_db = -80.0
		mp.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(mp)
		mp.finished.connect(_on_music_finished.bind(mp))
		_music_players.append(mp)

## Dispara un efecto puntual por nombre. Silenciosamente no hace nada si el
## evento no está mapeado, para que llamar con un nombre nuevo no rompa nada.
func play_event(event_name: StringName) -> void:
	if not _sfx_streams.has(event_name):
		return
	var player: AudioStreamPlayer = _sfx_players[_next_player]
	_next_player = (_next_player + 1) % _sfx_players.size()
	player.stream = _sfx_streams[event_name]
	player.volume_db = sfx_volume_db + SFX_VOLUME_OFFSET.get(event_name, 0.0)
	player.play()

## Cambia la música de fondo si corresponde a una pista distinta de la
## actual, con un crossfade suave en vez de un corte brusco (evita reiniciar
## el loop al recargar el mismo mundo).
func play_music(track_key: String) -> void:
	if track_key == _current_music:
		return
	if not _music_streams.has(track_key):
		return
	_current_music = track_key
	var old_player: AudioStreamPlayer = _music_players[_active_music_index]
	var new_index := 1 - _active_music_index
	var new_player: AudioStreamPlayer = _music_players[new_index]
	_active_music_index = new_index

	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()

	new_player.stream = _music_streams[track_key]
	new_player.volume_db = -80.0
	new_player.play()

	_music_tween = create_tween()
	_music_tween.set_parallel(true)
	_music_tween.tween_property(new_player, "volume_db", music_volume_db, MUSIC_CROSSFADE_SEC)
	if old_player.playing:
		_music_tween.tween_property(old_player, "volume_db", -80.0, MUSIC_CROSSFADE_SEC)
		_music_tween.chain().tween_callback(old_player.stop)

func stop_music() -> void:
	_current_music = ""
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	for mp in _music_players:
		mp.stop()

func _on_music_finished(player: AudioStreamPlayer) -> void:
	if player == _music_players[_active_music_index]:
		player.play()

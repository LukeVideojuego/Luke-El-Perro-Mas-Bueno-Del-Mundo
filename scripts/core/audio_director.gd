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

var _sfx_streams: Dictionary = {}
var _music_streams: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _music_player: AudioStreamPlayer
var _current_music := ""

@export var sfx_volume_db := -6.0
@export var music_volume_db := -14.0

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
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = music_volume_db
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player)
	_music_player.finished.connect(_on_music_finished)

## Dispara un efecto puntual por nombre. Silenciosamente no hace nada si el
## evento no está mapeado, para que llamar con un nombre nuevo no rompa nada.
func play_event(event_name: StringName) -> void:
	if not _sfx_streams.has(event_name):
		return
	var player: AudioStreamPlayer = _sfx_players[_next_player]
	_next_player = (_next_player + 1) % _sfx_players.size()
	player.stream = _sfx_streams[event_name]
	player.play()

## Cambia la música de fondo si corresponde a una pista distinta de la
## actual (evita reiniciar el loop al recargar el mismo mundo).
func play_music(track_key: String) -> void:
	if track_key == _current_music:
		return
	if not _music_streams.has(track_key):
		return
	_current_music = track_key
	_music_player.stream = _music_streams[track_key]
	_music_player.play()

func stop_music() -> void:
	_current_music = ""
	_music_player.stop()

func _on_music_finished() -> void:
	_music_player.play()

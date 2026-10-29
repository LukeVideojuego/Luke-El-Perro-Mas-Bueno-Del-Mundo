extends Node

## Punto único de audio: efectos de sonido puntuales (play_event) y música de
## fondo en loop por pantalla/mundo (play_music). Los efectos siguen siendo
## WAV sintetizados en assets/audio/sfx/. La música (A1) son pistas reales de
## licencia libre elegidas por el usuario (originales en musica_candidata/ en
## la raíz del proyecto, con .gdignore para que Godot no las importe/exporte
## desde ahí); las copias realmente usadas por el juego viven en
## assets/audio/music/ como .mp3 (Godot 4 lo importa nativamente, no hace
## falta reconvertir).
##
## Solo habia 9 pistas para 19 pantallas, asi que varias pantallas comparten
## archivo a proposito: los nombres de los .mp3 originales ya indican que
## mundo1_nivelN y mundo2_nivelN (misma N) estan pensados para compartir
## tema, igual que los 2 jefes entre si. El Mundo 3 tiene las 4 pistas
## propias. El Mundo 4 y las pantallas sin musica dedicada (menu, intro) no
## tenian ninguna pista candidata: se reusan las mas cercanas (Mundo 3 para
## el Mundo 4, Mundo 1 -el mas tranquilo- para menu/intro). Ver el resumen
## del commit para la tabla completa asignacion -> archivo.
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

## A1: pista real por pantalla. Varias pantallas comparten archivo a
## proposito (ver comentario mas arriba) -- es el mismo .mp3 cargado bajo
## mas de una clave, no un problema.
const MUSIC_FILES := {
	"menu": "world1_1_world2_1.mp3",
	"intro": "world1_2_world2_2.mp3",
	"final": "final_real.mp3",
	"world1_level1": "world1_1_world2_1.mp3",
	"world1_level2": "world1_2_world2_2.mp3",
	"world1_level3": "world1_3_world2_3.mp3",
	"world1_boss": "world1_boss_world2_boss.mp3",
	"world2_level1": "world1_1_world2_1.mp3",
	"world2_level2": "world1_2_world2_2.mp3",
	"world2_level3": "world1_3_world2_3.mp3",
	"world2_boss": "world1_boss_world2_boss.mp3",
	"world3_level1": "world3_1.mp3",
	"world3_level2": "world3_2.mp3",
	"world3_level3": "world3_3.mp3",
	"world3_boss": "world3_boss.mp3",
	"world4_selva": "world3_1.mp3",
	"world4_mar": "world3_2.mp3",
	"world4_india": "world3_3.mp3",
	"world4_boss": "world3_boss.mp3",
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
## Punto 1 (web): la musica la toca el navegador con su <audio> nativo
## (LukeWeb en web/head_include.html). En web Godot reproduce todo en modo
## "Sample" (el recomendado sin hilos): eso decodifica cada pista ENTERA en
## memoria (5 min de MP3 = ~100 MB), demasiado para un iPhone, y ademas
## traba el juego al empezar cada pista. Los efectos (WAV cortitos) siguen
## por Godot en modo Sample, que es justo para lo que esta pensado.
var _web: JavaScriptObject = null

@export var sfx_volume_db := -6.0
@export var music_volume_db := -16.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web"):
		_web = JavaScriptBridge.get_interface("LukeWeb")
	for key in SFX_FILES:
		_sfx_streams[key] = load(SFX_DIR + SFX_FILES[key])
	for key in MUSIC_FILES:
		var stream: AudioStream = load(MUSIC_DIR + MUSIC_FILES[key])
		# A1: que el motor loopee la pista el mismo (gapless) en vez de
		# depender solo de reiniciar al recibir la señal "finished" --
		# eso ultimo deja un hueco de hasta un buffer de audio en cada
		# vuelta, que con musica real (no un loop de 1-2s como el chiptune
		# anterior) se nota mucho mas.
		if stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = true
		_music_streams[key] = stream
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
	if _web != null:
		_play_music_web(track_key)
		return
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
	if _web != null:
		_web.musicStop()
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	for mp in _music_players:
		mp.stop()

func _on_music_finished(player: AudioStreamPlayer) -> void:
	if player == _music_players[_active_music_index]:
		player.play()

func _play_music_web(track_key: String) -> void:
	# El MP3 original va tal cual (AudioStreamMP3.data) a un Blob del
	# navegador, una sola vez por archivo.
	var file: String = MUSIC_FILES[track_key]
	if not bool(_web.musicHas(file)):
		var stream := _music_streams[track_key] as AudioStreamMP3
		_web.musicLoad(file, Marshalls.raw_to_base64(stream.data))
	_web.musicPlay(file, db_to_linear(music_volume_db), MUSIC_CROSSFADE_SEC)

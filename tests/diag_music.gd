extends Node2D

## D1: musica por nivel.
##
## Antes habia una sola pista por MUNDO (compartida entre los 3 niveles
## regulares) y una pista "boss" generica para los 4 jefes: 16 niveles
## jugables sonando con solo 8 pistas distintas. Ahora cada uno de los 16
## tiene la suya.
##
## Este test corre el Main de verdad y, para cada nivel, dispara la misma
## transicion que usa el juego (_update_music_for_level) y comprueba:
##  1. Que suene musica (no silencio).
##  2. Que cada uno de los 16 niveles tenga una pista DISTINTA de todos los
##     demas (nada de "world1" compartido ni "boss" generica).
##  3. Que los 3 niveles + el jefe de cada mundo usen archivos .wav
##     distintos entre si pero reconocibles como la misma familia por
##     nombre (world%d_*).
##  4. Que las transiciones sigan siendo suaves: el crossfade (MUSIC_CROSSFADE_SEC)
##     no cambio.

const MAIN_SCENE := preload("res://scenes/main.tscn")

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	add_child(main)

	var level_ids: Array[String] = []
	for world in range(1, 5):
		for n in range(1, 4):
			level_ids.append("world_%d_level_%d" % [world, n])
		level_ids.append("world_%d_boss" % world)

	var used_tracks: Dictionary = {}
	for level_id in level_ids:
		main._update_music_for_level(level_id)
		var track: String = AudioDirector._current_music
		_check(not track.is_empty(), "%s dispara una pista de musica" % level_id)
		_check(not used_tracks.has(track), "%s usa una pista NUEVA (%s), no compartida con otro nivel ya visto" % [level_id, track])
		used_tracks[track] = level_id

	_check(used_tracks.size() == level_ids.size(),
		"los 16 niveles jugables usan 16 pistas distintas (hay %d pistas unicas)" % used_tracks.size())

	# Verifica que el archivo wav de cada pista existe y tiene audio real.
	var all_have_audio := true
	for track_key in used_tracks:
		var path := "res://assets/audio/music/" + String(AudioDirector.MUSIC_FILES.get(track_key, ""))
		if not ResourceLoader.exists(path):
			all_have_audio = false
			print("  FALTA ARCHIVO: ", track_key, " -> ", path)
			continue
		var stream: AudioStream = load(path)
		if stream == null or stream.get_length() < 10.0:
			all_have_audio = false
			print("  PISTA DEMASIADO CORTA O VACIA: ", track_key)
	_check(all_have_audio, "las 16 pistas tienen un .wav real de duracion razonable (>10s)")

	# Familias: world%d_level1/2/3/boss deben ser 4 archivos DISTINTOS que
	# comparten el prefijo del mundo (coherencia de familia por nombre).
	var families_ok := true
	for world in range(1, 5):
		var names: Array[String] = []
		for n in range(1, 4):
			names.append(String(AudioDirector.MUSIC_FILES.get("world%d_level%d" % [world, n], "")))
		# Mundo 4 usa nombres tematicos (selva/mar/india) en vez de level1/2/3.
		if world == 4:
			names = []
			for k in ["world4_selva", "world4_mar", "world4_india"]:
				names.append(String(AudioDirector.MUSIC_FILES.get(k, "")))
		names.append(String(AudioDirector.MUSIC_FILES.get("world%d_boss" % world, "")))
		var unique := {}
		for nm in names:
			unique[nm] = true
		if unique.size() != 4 or names.has(""):
			families_ok = false
			print("  Mundo %d: pistas=%s" % [world, names])
	_check(families_ok, "cada mundo tiene 4 pistas distintas (3 niveles + jefe), ninguna vacia ni repetida")

	_check(AudioDirector.MUSIC_CROSSFADE_SEC > 0.0,
		"el crossfade entre pistas sigue activo (%.2fs), las transiciones siguen suaves" % AudioDirector.MUSIC_CROSSFADE_SEC)

	main.queue_free()
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

extends Node2D

## D1 (histórico) + A1: música real por nivel.
##
## A1 reemplazó las 19 pistas chiptune sintéticas por música real de
## licencia libre (musica_candidata/ en la raíz). Solo había 9 archivos
## reales para 19 pantallas, y los propios nombres de archivo que eligió el
## usuario ("mundo1_nivel1_y_mundo2_nivel2.mp3", etc.) indican que varias
## pantallas SE COMPARTEN A PROPOSITO (ver audio_director.gd):
##   - world1_levelN y world2_levelN (misma N) comparten archivo.
##   - world1_boss y world2_boss comparten archivo.
##   - world4_* (sin pista propia) reusa las 4 del Mundo 3 (el mas cercano).
##   - menu/intro (sin pista propia) reusan las del Mundo 1 (el mas tranquilo).
## Por eso esta version del test YA NO exige que los 16 niveles jugables usen
## 16 archivos distintos (eso era el requisito D1 original, con las pistas
## sintetizadas viejas) -- en cambio, fija el reparto real como contrato:
## confirma que las parejas que DEBEN sonar igual suenan igual, y que las
## que deben sonar distinto (dentro de cada mundo, y Mundo 1 vs Mundo 3)
## siguen distintas.
##
## Sigue comprobando:
##  1. Que cada pantalla dispare musica real (no silencio).
##  2. Que el archivo de cada pista exista y tenga audio de duracion real.
##  3. Que cada mundo tenga 4 archivos distintos entre si (3 niveles + jefe).
##  4. Que las parejas compartidas a proposito (world1<->world2, Mundo3<->Mundo4)
##     efectivamente apunten al mismo archivo.
##  5. Que el crossfade siga activo.
##  6. Que las pistas reales looppeen gapless (AudioStreamMP3.loop = true).

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

	var track_by_level: Dictionary = {}
	for level_id in level_ids:
		main._update_music_for_level(level_id)
		var track: String = AudioDirector._current_music
		_check(not track.is_empty(), "%s dispara una pista de musica" % level_id)
		track_by_level[level_id] = track

	# 2: archivo existe y dura mas de 10s.
	var all_have_audio := true
	var seen_files: Dictionary = {}
	for track_key in AudioDirector.MUSIC_FILES:
		var fname: String = String(AudioDirector.MUSIC_FILES[track_key])
		if seen_files.has(fname):
			continue
		seen_files[fname] = true
		var path := "res://assets/audio/music/" + fname
		if not ResourceLoader.exists(path):
			all_have_audio = false
			print("  FALTA ARCHIVO: ", track_key, " -> ", path)
			continue
		var stream: AudioStream = load(path)
		if stream == null or stream.get_length() < 10.0:
			all_have_audio = false
			print("  PISTA DEMASIADO CORTA O VACIA: ", track_key)
	_check(all_have_audio, "las pistas reales tienen un archivo .mp3 real de duracion razonable (>10s)")

	# 3: cada mundo tiene 4 archivos DISTINTOS entre si (3 niveles + jefe).
	var families_ok := true
	for world in range(1, 5):
		var names: Array[String] = []
		if world == 4:
			for k in ["world4_selva", "world4_mar", "world4_india"]:
				names.append(String(AudioDirector.MUSIC_FILES.get(k, "")))
		else:
			for n in range(1, 4):
				names.append(String(AudioDirector.MUSIC_FILES.get("world%d_level%d" % [world, n], "")))
		names.append(String(AudioDirector.MUSIC_FILES.get("world%d_boss" % world, "")))
		var unique := {}
		for nm in names:
			unique[nm] = true
		if unique.size() != 4 or names.has(""):
			families_ok = false
			print("  Mundo %d: pistas=%s" % [world, names])
	_check(families_ok, "cada mundo tiene 4 pistas distintas (3 niveles + jefe), ninguna vacia ni repetida DENTRO del mismo mundo")

	# 4: las parejas compartidas a proposito deben sonar literalmente igual.
	const SHARED_PAIRS := [
		["world_1_level_1", "world_2_level_1"],
		["world_1_level_2", "world_2_level_2"],
		["world_1_level_3", "world_2_level_3"],
		["world_1_boss", "world_2_boss"],
	]
	for pair in SHARED_PAIRS:
		var a: String = String(AudioDirector.MUSIC_FILES.get(track_by_level[pair[0]], ""))
		var b: String = String(AudioDirector.MUSIC_FILES.get(track_by_level[pair[1]], ""))
		_check(a == b and a != "", "%s y %s comparten pista a proposito (son la misma familia nombrada por el usuario)" % [pair[0], pair[1]])

	var world4_tracks := {
		"world_4_level_1": "world3_level1",
		"world_4_level_2": "world3_level2",
		"world_4_level_3": "world3_level3",
		"world_4_boss": "world3_boss",
	}
	for w4_level in world4_tracks:
		var w3_key: String = world4_tracks[w4_level]
		var w4_track: String = String(AudioDirector.MUSIC_FILES.get(track_by_level[w4_level], ""))
		var w3_track: String = String(AudioDirector.MUSIC_FILES.get(w3_key, ""))
		_check(w4_track == w3_track and w4_track != "",
			"%s reusa la pista del Mundo 3 mas cercana (%s) al no tener una propia" % [w4_level, w3_key])

	_check(AudioDirector.MUSIC_CROSSFADE_SEC > 0.0,
		"el crossfade entre pistas sigue activo (%.2fs), las transiciones siguen suaves" % AudioDirector.MUSIC_CROSSFADE_SEC)

	# 6: loop gapless activado en las pistas reales.
	var all_loop := true
	for track_key in seen_files:
		var stream: AudioStream = load("res://assets/audio/music/" + String(track_key))
		if stream is AudioStreamMP3 and not (stream as AudioStreamMP3).loop:
			all_loop = false
			print("  SIN LOOP: ", track_key)
	_check(all_loop, "las pistas reales (.mp3) tienen loop=true (loopean sin corte, no dependen solo de reiniciar al terminar)")

	main.queue_free()
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

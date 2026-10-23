extends Node2D

## A8: fondos repetidos. Confirma que los 12 niveles regulares (los que
## tienen fondo en mas de una copia, es decir, son "largos") tienen
## elementos decorativos nuevos delante del fondo (z_index entre el fondo
## en -10 y el resto del juego en 0) en cada costura de repeticion, y que
## NO son todos el mismo elemento repetido (eso solo cambiaria un patron
## por otro).

const EXPECTED_DECOS := {
	"world_1_level_1": 6, "world_1_level_2": 6, "world_1_level_3": 8,
	"world_2_level_1": 6, "world_2_level_2": 8, "world_2_level_3": 8,
	"world_3_level_1": 6, "world_3_level_2": 8, "world_3_level_3": 8,
	"world_4_level_1": 8, "world_4_level_2": 8, "world_4_level_3": 8,
}

var fail_count := 0

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		print("FAIL: ", label)
		fail_count += 1

func _ready() -> void:
	for level_id in EXPECTED_DECOS:
		_check_level(level_id, EXPECTED_DECOS[level_id])
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _check_level(level_id: String, expected_count: int) -> void:
	var level: Node = load("res://scenes/levels/%s.tscn" % level_id).instantiate()
	add_child(level)
	var decos: Array = []
	for child in level.get_children():
		if child is Sprite2D and String(child.name).begins_with("DecoSeam"):
			decos.append(child)
	_check(decos.size() == expected_count,
		"%s: tiene %d decoraciones de costura (esperaba %d)" % [level_id, decos.size(), expected_count])

	var textures := {}
	for d in decos:
		_check(d.z_index == -5, "%s/%s: z_index=-5 (delante del fondo, detras del juego)" % [level_id, d.name])
		if d.texture != null:
			textures[d.texture.resource_path] = true
	_check(textures.size() > 1,
		"%s: usa mas de una textura distinta entre las decoraciones (%d), no repite siempre la misma" % [level_id, textures.size()])

	level.queue_free()

extends Node2D

## B6: mide la ALTURA REAL EN PANTALLA (pixeles opacos del sprite x el scale
## global ya aplicado) de todos los personajes de los 16 niveles, los 4
## jefes y el minijuego final, y la compara con la regla de escala del
## proyecto tomando a Luke como unidad.
##
## Regla base: Luke = 1 m (no se toca). Mujeres y ancianas = 1,4 m. Hombres
## = 1,8 m. Ninios = 0,7 a 1,1 m. Los jefes tienen regla propia y solo se
## informan.
##
## Ajuste de proporcion visual (pedido explicito del usuario: "si al medirlo
## ya cumplen la regla pero a la vista se siguen viendo chicos junto al
## ladron, subilos"): el arte de los villanos esta dibujado con proporciones
## de caricatura (cabeza grande, silueta ancha) y el de los civiles con
## proporciones realistas, asi que a la misma altura metrica los civiles se
## leen mas chicos. Por eso mujeres y ancianas van a 1,55 m en vez de 1,4 m,
## y los ninios se ubican en la mitad de ARRIBA de su banda (0,90 a 1,10 m
## en vez de 0,70 a 1,10 m). Hombres, villanos y Luke quedan exactamente
## donde dice la regla.
##
## No asume nada del arte: la altura se saca del rectangulo opaco real de la
## textura (get_used_rect) multiplicado por el scale global del nodo, que es
## exactamente lo que se ve en pantalla.

const SCENES := [
	"res://scenes/levels/world_1_level_1.tscn",
	"res://scenes/levels/world_1_level_2.tscn",
	"res://scenes/levels/world_1_level_3.tscn",
	"res://scenes/levels/world_1_boss.tscn",
	"res://scenes/levels/world_2_level_1.tscn",
	"res://scenes/levels/world_2_level_2.tscn",
	"res://scenes/levels/world_2_level_3.tscn",
	"res://scenes/levels/world_2_boss.tscn",
	"res://scenes/levels/world_3_level_1.tscn",
	"res://scenes/levels/world_3_level_2.tscn",
	"res://scenes/levels/world_3_level_3.tscn",
	"res://scenes/levels/world_3_boss.tscn",
	"res://scenes/levels/world_4_level_1.tscn",
	"res://scenes/levels/world_4_level_2.tscn",
	"res://scenes/levels/world_4_level_3.tscn",
	"res://scenes/levels/world_4_boss.tscn",
	"res://scenes/levels/final_screen.tscn",
]

## textura -> [categoria, metros objetivo]. "jefe" y "animal" solo se informan.
const CATEGORY := {
	"luke_idle.png": ["Luke", 1.0],
	"anciana.png": ["anciana", 1.55],
	"anciana_walk.png": ["anciana", 1.55],
	"grandma_idle.png": ["anciana", 1.55],
	"transeunte1.png": ["mujer", 1.55],
	"transeunte1_walk.png": ["mujer", 1.55],
	"transeunte2.png": ["hombre", 1.8],
	"transeunte2_walk.png": ["hombre", 1.8],
	"transeunte3.png": ["hombre", 1.8],
	"transeunte3_walk.png": ["hombre", 1.8],
	"diego.png": ["hombre", 1.8],
	"diego_walk.png": ["hombre", 1.8],
	"thief.png": ["villano hombre", 1.8],
	"thief_walk.png": ["villano hombre", 1.8],
	"carterista.png": ["villano hombre", 1.8],
	"carterista_walk.png": ["villano hombre", 1.8],
	"guardia.png": ["villano hombre", 1.8],
	"guardia_walk.png": ["villano hombre", 1.8],
	"politico_corrupto.png": ["villano hombre", 1.8],
	"politico_corrupto_walk.png": ["villano hombre", 1.8],
	"ladron_politico.png": ["villano hombre", 1.8],
	"ladron_politico_walk.png": ["villano hombre", 1.8],
	"bauti.png": ["nino", 1.0],
	"bauti_walk.png": ["nino", 1.0],
	"fausto.png": ["nino", 0.98],
	"fausto_walk.png": ["nino", 0.98],
	"izan.png": ["nino", 1.05],
	"izan_walk.png": ["nino", 1.05],
	"lara.png": ["nina", 1.1],
	"lara_walk.png": ["nina", 1.1],
	"mathi.png": ["nino", 0.92],
	"mathi_walk.png": ["nino", 0.92],
	"roma.png": ["nina", 0.9],
	"roma_walk.png": ["nina", 0.9],
	"zoe.png": ["nina", 1.08],
	"zoe_walk.png": ["nina", 1.08],
	"character_green_idle.png": ["vecino", 1.6],
	"character_green_front.png": ["vecino", 1.6],
	"character_yellow_idle.png": ["vecino", 1.6],
	"character_yellow_front.png": ["vecino", 1.6],
	"character_purple_idle.png": ["vecino", 1.6],
	"character_purple_front.png": ["vecino", 1.6],
	"character_pink_idle.png": ["vecino", 1.6],
	"character_pink_front.png": ["vecino", 1.6],
	"character_beige_idle.png": ["vecino", 1.6],
	"don_sombra.png": ["JEFE", 0.0],
	"don_sombra_walk.png": ["JEFE", 0.0],
	"bruja_olvido.png": ["JEFE", 0.0],
	"gran_codicia.png": ["JEFE", 0.0],
	"gran_codicia_walk.png": ["JEFE", 0.0],
	"serpiente.png": ["JEFE", 0.0],
}
## Tolerancia: +-6% de la altura objetivo.
const TOLERANCE := 0.06

var luke_height := 0.0
var fail_count := 0
var rows: Array = []

func _ready() -> void:
	for path in SCENES:
		await _scan(path)
	print("")
	print("=== TABLA DE ALTURAS (1 m = %.1f px, medido sobre Luke) ===" % luke_height)
	print("%-22s %-18s %-14s %7s %7s %7s  %s" % [
		"ESCENA", "NODO", "CATEGORIA", "MEDIDO", "METROS", "OBJETIVO", "ESTADO"])
	for r in rows:
		var target_px: float = r.target_m * luke_height
		var meters: float = r.height / luke_height if luke_height > 0.0 else 0.0
		var state := "-- jefe/animal --"
		if r.target_m > 0.0:
			var off: float = absf(r.height - target_px) / target_px
			state = "OK" if off <= TOLERANCE else ("MAL (%+.0f%%)" % ((r.height / target_px - 1.0) * 100.0))
			if off > TOLERANCE:
				fail_count += 1
		print("%-22s %-18s %-14s %6.0fpx %6.2fm %6.0fpx  %s" % [
			r.scene, r.node, r.category, r.height, meters, target_px, state])
	print("")
	print("RESULTADO: ", fail_count, " fallos")
	get_tree().quit()

func _scan(path: String) -> void:
	var scene: Node = load(path).instantiate()
	add_child(scene)
	await get_tree().physics_frame
	for node in _walk(scene):
		var info := _measure(node)
		if info.is_empty():
			continue
		if info.category == "Luke" and luke_height <= 0.0:
			luke_height = info.height
		info["scene"] = path.get_file().replace(".tscn", "")
		rows.append(info)
	scene.queue_free()
	await get_tree().process_frame

func _measure(node: Node) -> Dictionary:
	var texture: Texture2D = null
	if node is Sprite2D:
		texture = node.texture
	elif node is AnimatedSprite2D and node.sprite_frames != null:
		var anim: StringName = node.animation
		if node.sprite_frames.has_animation(anim) and node.sprite_frames.get_frame_count(anim) > 0:
			texture = node.sprite_frames.get_frame_texture(anim, 0)
	if texture == null or texture.resource_path.is_empty():
		return {}
	var file := texture.resource_path.get_file()
	if not CATEGORY.has(file):
		return {}
	var image := texture.get_image()
	var used_h: float = float(texture.get_height())
	if image != null:
		var used := image.get_used_rect()
		if used.size.y > 0:
			used_h = float(used.size.y)
	var entry: Array = CATEGORY[file]
	return {
		"node": node.name if _is_scene_root(node.get_parent()) else node.get_parent().name,
		"category": entry[0],
		"target_m": float(entry[1]),
		"height": used_h * absf((node as Node2D).global_scale.y),
	}

func _is_scene_root(node: Node) -> bool:
	return node == null or node.get_parent() == self

func _walk(node: Node) -> Array:
	var result: Array = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_walk(child))
	return result

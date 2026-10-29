class_name LevelBase
extends Node2D

## Base común para todos los niveles: registra el nivel en GameState,
## conecta la derrota de Luke y opcionalmente muestra un cartel de fin.

## B1: cualquier DigSpot hijo del nivel burbujea su pedido de bonus hacia
## arriba (main.gd escucha esto en load_level()).
signal bonus_requested(bonus_scene_path: String, return_position: Vector2)

## Si Luke cae más abajo del punto de spawn que este margen (p. ej. atraviesa
## un hueco de agua sin tocar fondo), se lo trata como una derrota en vez de
## dejarlo caer para siempre.
const FALL_RESET_MARGIN := 450.0

## Carga 3 (rendimiento en celular): los enemigos comunes que estan lejos
## FUERA de lo que muestra la camara se pausan y salen de la simulacion de
## fisica; al acercarse Luke se reactivan exactamente donde estaban. El
## margen (mas alla del borde de la pantalla) es mucho mayor que cualquier
## distancia de deteccion/ataque de un enemigo comun (<= 420), asi que cerca
## de Luke todo pasa igual que antes. Los jefes no se tocan.
## Antes, en los niveles grandes (40 enemigos) cada paso de fisica movia y
## chocaba a todos, y en un celular lento eso entraba en "espiral" (Godot
## corre mas pasos de fisica para alcanzar, que tardan mas, y asi).
const SLEEP_MARGIN := Vector2(900.0, 650.0)
const SLEEP_CHECK_FRAMES := 10

@export var level_id := ""
@export_multiline var mission_text := ""

@onready var luke: Luke = $Luke
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var mission_sign: Interactable = get_node_or_null("MissionSign")
@onready var completion_label: Label = get_node_or_null("CompletionLabel")

var _fall_reset_y := 0.0
var _game_over := false
var _sleepers: Array[EnemyBase] = []
var _sleep_tick := 0

func _ready() -> void:
	GameState.begin_level(level_id, spawn_point.global_position)
	if GameState.consume_resume_flag():
		luke.global_position = GameState.checkpoint_position
	luke.set_protective_aura(GameState.aura_active)
	luke.defeated.connect(_on_luke_defeated)
	if mission_sign != null and not mission_text.is_empty():
		mission_sign.interaction_text = mission_text
	if mission_sign != null and mission_sign.hint_label != null:
		mission_sign.hint_label.text = mission_sign.interaction_text
	if completion_label != null:
		GameState.level_completed.connect(_on_level_completed)
	for child in get_children():
		if child is DigSpot:
			child.bonus_triggered.connect(_on_dig_bonus_triggered)
	_fall_reset_y = spawn_point.global_position.y + FALL_RESET_MARGIN
	_apply_camera_limits()
	_apply_shop_purchases()
	for n in find_children("*", "CharacterBody2D", true, false):
		if n is EnemyBase and not (n is BossBase):
			_sleepers.append(n)

func _on_dig_bonus_triggered(bonus_scene_path: String, return_position: Vector2) -> void:
	bonus_requested.emit(bonus_scene_path, return_position)

## C3: aplica lo comprado en la tienda al arrancar el nivel. Los consumibles
## se gastan acá (una compra = un nivel); los cosméticos los dibuja Luke solo
## leyendo GameState.
func _apply_shop_purchases() -> void:
	if GameState.pending_hearts > 0:
		GameState.add_life(GameState.pending_hearts)
		GameState.pending_hearts = 0
	if GameState.pending_aura:
		GameState.pending_aura = false
		luke.set_protective_aura(true)
	if GameState.pending_boots:
		GameState.pending_boots = false
		luke.grant_speed_boost()
	if GameState.pending_star:
		GameState.pending_star = false
		luke.grant_invincibility(12.0)
	SaveManager.save_game()

## La cámara de Luke (player.tscn) viene con límites fijos pensados para un
## solo nivel de referencia; como cada nivel tiene un largo distinto (5100 a
## 9800px aprox.), ese límite fijo hacía que la cámara dejara de seguir a
## Luke mucho antes del final de casi todos los niveles (bug de cámara:
## Luke se salía de cuadro y quedaba invisible en el tramo final). Acá se
## recalculan los límites en base a la geometría sólida real del nivel
## (todos los StaticBody2D: piso, plataformas fijas) y, sobre todo, al
## fondo: la cámara NUNCA puede mostrar nada fuera del fondo.
##
## Las paredes invisibles de los bordes (*Boundary) quedan excluidas a
## propósito: se extienden 70px más allá del piso y del fondo, y eran la
## causa de la franja gris vertical de la izquierda (la cámara llegaba a
## x=-70 mientras el fondo arranca en x=0, así que ese tramo quedaba sin
## fondo ni piso y Luke se veía "por delante del gris").
func _apply_camera_limits() -> void:
	var camera: Camera2D = luke.get_node_or_null("Camera2D")
	if camera == null:
		return
	var bounds := _compute_static_x_bounds(self)
	var background := _compute_background_rect()
	if background.size.x > 0.0:
		bounds.x = maxf(bounds.x, background.position.x)
		bounds.y = minf(bounds.y, background.position.x + background.size.x)
		camera.limit_top = int(maxf(float(camera.limit_top), background.position.y))
		camera.limit_bottom = int(minf(float(camera.limit_bottom), background.position.y + background.size.y))
	if bounds.y <= bounds.x:
		return
	camera.limit_left = int(bounds.x)
	camera.limit_right = int(bounds.y)

## Rect global del fondo del nivel. Rect2() vacío si el nivel no tiene
## fondo propio.
##
## E1: el fondo de los niveles normales ya NO es un solo Sprite2D con un
## region_rect gigante simulando tiling infinito (esa tecnica se rompia de
## verdad en el renderer: mas alla de ~3 repeticiones reales necesarias,
## dejaba de dibujar y aparecia la franja gris del motor, confirmado con
## captura real). Ahora son VARIAS instancias Sprite2D normales
## ("Background", "BackgroundTile2", "BackgroundTile3"...) puestas una al
## lado de la otra, cada una con su copia completa de la textura. Esta
## funcion junta el rectangulo de TODAS para seguir dando el ancho real
## cubierto (si solo mirara "Background", el límite de cámara quedaría
## recortado al ancho de una sola copia de la textura).
func _compute_background_rect() -> Rect2:
	var tiles: Array[Sprite2D] = []
	for child in get_children():
		if child is Sprite2D and (child.name == "Background" or String(child.name).begins_with("BackgroundTile")):
			tiles.append(child)
	if tiles.is_empty():
		# El minijuego final no tiene "Background": su fondo es "Sky".
		var sky := get_node_or_null("Sky") as Sprite2D
		if sky != null:
			tiles.append(sky)
	if tiles.is_empty():
		return Rect2()
	var result := Rect2()
	var first := true
	for tile in tiles:
		if tile.texture == null:
			continue
		var size: Vector2 = tile.region_rect.size if tile.region_enabled else tile.texture.get_size()
		size *= tile.global_scale
		var origin: Vector2 = tile.global_position
		if tile.centered:
			origin -= size * 0.5
		var rect := Rect2(origin, size)
		result = rect if first else result.merge(rect)
		first = false
	return result

## Devuelve Vector2(min_x, max_x) de toda la geometría sólida del nivel.
func _compute_static_x_bounds(root: Node) -> Vector2:
	var min_x := INF
	var max_x := -INF
	for body in _collect_static_bodies(root):
		if body.name.ends_with("Boundary"):
			continue
		for child in body.get_children():
			if child is CollisionShape2D and child.shape is RectangleShape2D:
				var half_x: float = child.shape.size.x * 0.5
				var gx: float = child.global_position.x
				min_x = minf(min_x, gx - half_x)
				max_x = maxf(max_x, gx + half_x)
	return Vector2(min_x, max_x)

func _collect_static_bodies(node: Node) -> Array:
	var result: Array = []
	for child in node.get_children():
		if child is StaticBody2D:
			result.append(child)
		result.append_array(_collect_static_bodies(child))
	return result

func _physics_process(_delta: float) -> void:
	if _game_over:
		return
	_sleep_tick -= 1
	if _sleep_tick <= 0:
		_sleep_tick = SLEEP_CHECK_FRAMES
		_update_sleeping_enemies()
	if luke.global_position.y > _fall_reset_y:
		_on_luke_defeated()

func _update_sleeping_enemies() -> void:
	var vp := get_viewport()
	if vp == null or vp.get_camera_2d() == null:
		return
	var view := vp.get_canvas_transform().affine_inverse() * vp.get_visible_rect()
	var awake_area := view.grow_individual(SLEEP_MARGIN.x, SLEEP_MARGIN.y, SLEEP_MARGIN.x, SLEEP_MARGIN.y)
	for i in range(_sleepers.size() - 1, -1, -1):
		var e := _sleepers[i]
		if not is_instance_valid(e) or e.is_defeated:
			_sleepers.remove_at(i)
			continue
		var mode := Node.PROCESS_MODE_INHERIT if awake_area.has_point(e.global_position) else Node.PROCESS_MODE_DISABLED
		if e.process_mode != mode:
			e.process_mode = mode

## C1: al perder la ULTIMA vida el nivel ya no se reinicia solo con 3 vidas
## de la nada. Se congela y se avisa a GameState; main.gd es quien muestra la
## pantalla negra de "Te has quedado sin vidas" con CONTINUAR / GAME OVER.
func _on_luke_defeated() -> void:
	if _game_over:
		return
	if GameState.lose_life():
		luke.respawn(GameState.checkpoint_position)
		return
	_game_over = true
	set_physics_process(false)
	luke.set_physics_process(false)
	luke.velocity = Vector2.ZERO
	GameState.report_out_of_lives()

var _password_label: Label = null

## A5: muestra la contraseña del nivel recien completado (para poder saltar
## directo a el mas adelante desde el menu) justo debajo del cartel de
## "nivel completado" que ya existia. Se crea en runtime (no se toca cada
## escena de nivel a mano) para no tener que editar los 16 niveles.
func _on_level_completed(completed_id: String) -> void:
	if completion_label != null and completed_id == level_id:
		completion_label.visible = true
		_show_password_hint()

func _show_password_hint() -> void:
	var code := LevelProgression.get_password_for_level(level_id)
	if code.is_empty():
		return
	if _password_label == null:
		_password_label = Label.new()
		_password_label.custom_minimum_size = Vector2(500, 0)
		_password_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_password_label.add_theme_font_size_override("font_size", 26)
		_password_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		_password_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		_password_label.add_theme_constant_override("outline_size", 6)
		add_child(_password_label)
	_password_label.text = "Contraseña de este nivel: %s" % code
	var anchor: Vector2 = completion_label.position
	if completion_label.size.x > 0.0:
		anchor.x += completion_label.size.x * 0.5 - _password_label.custom_minimum_size.x * 0.5
	else:
		anchor.x -= _password_label.custom_minimum_size.x * 0.5 - 150.0
	_password_label.position = anchor + Vector2(0.0, 90.0)
	_password_label.visible = true

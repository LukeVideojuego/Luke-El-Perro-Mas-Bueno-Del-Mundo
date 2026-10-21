class_name LevelBase
extends Node2D

## Base común para todos los niveles: registra el nivel en GameState,
## conecta la derrota de Luke y opcionalmente muestra un cartel de fin.

## Si Luke cae más abajo del punto de spawn que este margen (p. ej. atraviesa
## un hueco de agua sin tocar fondo), se lo trata como una derrota en vez de
## dejarlo caer para siempre.
const FALL_RESET_MARGIN := 450.0

@export var level_id := ""
@export_multiline var mission_text := ""

@onready var luke: Luke = $Luke
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var mission_sign: Interactable = get_node_or_null("MissionSign")
@onready var completion_label: Label = get_node_or_null("CompletionLabel")

var _fall_reset_y := 0.0
var _game_over := false

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
	_fall_reset_y = spawn_point.global_position.y + FALL_RESET_MARGIN
	_apply_camera_limits()
	_apply_shop_purchases()

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

## Rect global del fondo del nivel (Sprite2D "Background", sin centrar y con
## region_rect). Rect2() vacío si el nivel no tiene fondo propio.
func _compute_background_rect() -> Rect2:
	var background := get_node_or_null("Background") as Sprite2D
	if background == null:
		# El minijuego final no tiene "Background": su fondo es "Sky".
		background = get_node_or_null("Sky") as Sprite2D
	if background == null or background.texture == null:
		return Rect2()
	var size: Vector2 = background.region_rect.size if background.region_enabled else background.texture.get_size()
	size *= background.global_scale
	var origin: Vector2 = background.global_position
	if background.centered:
		origin -= size * 0.5
	return Rect2(origin, size)

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
	if luke.global_position.y > _fall_reset_y:
		_on_luke_defeated()

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

func _on_level_completed(completed_id: String) -> void:
	if completion_label != null and completed_id == level_id:
		completion_label.visible = true

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

## La cámara de Luke (player.tscn) viene con límites fijos pensados para un
## solo nivel de referencia; como cada nivel tiene un largo distinto (5100 a
## 9800px aprox.), ese límite fijo hacía que la cámara dejara de seguir a
## Luke mucho antes del final de casi todos los niveles (bug de cámara:
## Luke se salía de cuadro y quedaba invisible en el tramo final). Acá se
## recalculan los límites en base a la geometría sólida real del nivel
## (todos los StaticBody2D: piso, plataformas fijas, paredes), en vez de un
## valor hardcodeado.
## Solo se ajustan los límites horizontales: los verticales (0..1080) ya
## están pensados para un nivel de una sola pantalla de alto y tocarlos en
## base a la altura de las plataformas más altas podría impedir que la
## cámara suba lo suficiente durante un salto.
func _apply_camera_limits() -> void:
	var camera: Camera2D = luke.get_node_or_null("Camera2D")
	if camera == null:
		return
	var bounds := _compute_static_x_bounds(self)
	if bounds.y <= bounds.x:
		return
	camera.limit_left = int(bounds.x)
	camera.limit_right = int(bounds.y)

## Devuelve Vector2(min_x, max_x) de toda la geometría sólida del nivel.
func _compute_static_x_bounds(root: Node) -> Vector2:
	var min_x := INF
	var max_x := -INF
	for body in _collect_static_bodies(root):
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
	if luke.global_position.y > _fall_reset_y:
		_on_luke_defeated()

func _on_luke_defeated() -> void:
	if not GameState.lose_life():
		GameState.reset_level_state(spawn_point.global_position)
	luke.respawn(GameState.checkpoint_position)

func _on_level_completed(completed_id: String) -> void:
	if completion_label != null and completed_id == level_id:
		completion_label.visible = true

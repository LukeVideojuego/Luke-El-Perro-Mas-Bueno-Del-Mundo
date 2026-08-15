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

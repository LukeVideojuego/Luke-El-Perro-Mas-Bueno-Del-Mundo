extends Node2D

const LEVEL_ID := "world_1_level_1"

@onready var luke: Luke = $Luke
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var completion_label: Label = $CompletionLabel

func _ready() -> void:
	GameState.begin_level(LEVEL_ID, spawn_point.global_position)
	luke.set_protective_aura(GameState.aura_active)
	luke.defeated.connect(_on_luke_defeated)
	GameState.level_completed.connect(_on_level_completed)

func _on_luke_defeated() -> void:
	if not GameState.lose_life():
		GameState.reset_level_state(spawn_point.global_position)
	luke.respawn(GameState.checkpoint_position)

func _on_level_completed(level_id: String) -> void:
	if level_id != LEVEL_ID:
		return
	completion_label.visible = true

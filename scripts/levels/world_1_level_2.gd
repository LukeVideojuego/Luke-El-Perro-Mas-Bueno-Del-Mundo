extends Node2D

const LEVEL_ID := "world_1_level_2"

@onready var luke: Luke = $Luke
@onready var spawn_point: Marker2D = $SpawnPoint

func _ready() -> void:
	GameState.begin_level(LEVEL_ID, spawn_point.global_position)
	luke.set_protective_aura(GameState.aura_active)
	luke.defeated.connect(_on_luke_defeated)

func _on_luke_defeated() -> void:
	if not GameState.lose_life():
		GameState.reset_level_state(spawn_point.global_position)
	luke.respawn(GameState.checkpoint_position)

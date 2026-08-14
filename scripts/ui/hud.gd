extends CanvasLayer

@onready var level_label: Label = $Panel/LevelLabel
@onready var lives_label: Label = $Panel/LivesLabel
@onready var aura_label: Label = $Panel/AuraLabel
@onready var progress_label: Label = $Panel/ProgressLabel

func _ready() -> void:
	GameState.level_begun.connect(_update_level)
	GameState.lives_changed.connect(_update_lives)
	GameState.aura_changed.connect(_update_aura)
	GameState.checkpoint_changed.connect(_update_checkpoint)
	_update_lives(GameState.lives)
	_update_aura(GameState.aura_active)
	_update_checkpoint(GameState.checkpoint_id)

func _update_level(level_id: String) -> void:
	var world := LevelProgression.get_world(level_id)
	var order := LevelProgression.get_order(level_id)
	if level_label == null:
		return
	if world == 0:
		level_label.text = "GRAN FINAL"
	elif order >= 4:
		level_label.text = "MUNDO %d · JEFE" % world
	else:
		level_label.text = "MUNDO %d · NIVEL %d" % [world, order]

func _update_lives(value: int) -> void:
	if lives_label == null:
		return
	lives_label.text = "VIDAS: %d" % value

func _update_aura(active: bool) -> void:
	if aura_label == null:
		return
	aura_label.text = "AURA: ACTIVA" if active else "AURA: --"

func _update_checkpoint(_checkpoint_id: String) -> void:
	if progress_label == null:
		return
	progress_label.text = "CHECKPOINT: ACTIVADO"

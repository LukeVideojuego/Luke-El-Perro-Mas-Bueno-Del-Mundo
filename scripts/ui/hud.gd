extends CanvasLayer

const HEART_FULL := preload("res://assets/ui/icon_corazon.png")
const HEART_EMPTY := preload("res://assets/ui/icon_corazon_empty.png")

@onready var level_label: Label = $LevelLabel
@onready var lives_label: Label = $Panel/LivesLabel
@onready var aura_label: Label = $Panel/AuraLabel
@onready var coins_label: Label = $Panel/CoinsLabel
@onready var time_label: Label = $Panel/TimeLabel
@onready var meat_icon: TextureRect = $Panel/MeatIcon
@onready var hearts: Array[TextureRect] = [$Panel/Heart1, $Panel/Heart2, $Panel/Heart3]

var elapsed_seconds := 0.0

func _ready() -> void:
	GameState.level_begun.connect(_update_level)
	GameState.lives_changed.connect(_update_lives)
	GameState.aura_changed.connect(_update_aura)
	GameState.coins_changed.connect(_update_coins)
	_update_lives(GameState.lives)
	_update_aura(GameState.aura_active)
	_update_coins(GameState.coins)
	_update_time()

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	elapsed_seconds += delta
	_update_time()

func _update_level(level_id: String) -> void:
	var world := LevelProgression.get_world(level_id)
	var order := LevelProgression.get_order(level_id)
	if level_label == null:
		return
	elapsed_seconds = 0.0
	if world == 0:
		level_label.text = "GRAN FINAL"
	elif order >= 4:
		level_label.text = "%s · %s" % [LevelProgression.get_world_name(world), LevelProgression.get_boss_name(world)]
	else:
		level_label.text = "%s · NIVEL %d" % [LevelProgression.get_world_name(world), order]

func _update_lives(value: int) -> void:
	if lives_label == null:
		return
	lives_label.text = "x%02d" % value
	for i in hearts.size():
		hearts[i].texture = HEART_FULL if i < value else HEART_EMPTY

func _update_aura(active: bool) -> void:
	if aura_label == null:
		return
	aura_label.text = "AURA: ACTIVA" if active else "AURA: --"
	meat_icon.modulate = Color(1, 1, 1, 1) if active else Color(1, 1, 1, 0.35)

func _update_coins(total: int) -> void:
	if coins_label == null:
		return
	coins_label.text = "x%d" % total

func _update_time() -> void:
	if time_label == null:
		return
	var total := int(elapsed_seconds)
	var minutes := total / 60.0
	time_label.text = "%02d:%02d" % [floori(minutes), total % 60]

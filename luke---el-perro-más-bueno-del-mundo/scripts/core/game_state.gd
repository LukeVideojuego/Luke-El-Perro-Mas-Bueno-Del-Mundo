extends Node

## Estado persistente y desacoplado para niveles, checkpoints y transición futura.
signal lives_changed(current_lives: int)
signal aura_changed(is_active: bool)
signal checkpoint_changed(checkpoint_id: String)
signal level_begun(level_id: String)
signal level_completed(level_id: String)

const DEFAULT_LIVES := 3

var lives := DEFAULT_LIVES
var aura_active := false
var checkpoint_position := Vector2.ZERO
var checkpoint_id := ""
var current_level_id := ""
var is_level_complete := false

func begin_level(level_id: String, spawn_position: Vector2) -> void:
	var entering_new_level := current_level_id != level_id
	current_level_id = level_id
	is_level_complete = false
	if entering_new_level or checkpoint_position == Vector2.ZERO:
		checkpoint_position = spawn_position
		checkpoint_id = "start"
	lives_changed.emit(lives)
	aura_changed.emit(aura_active)
	level_begun.emit(level_id)

func set_checkpoint(id: String, position: Vector2) -> void:
	checkpoint_id = id
	checkpoint_position = position
	checkpoint_changed.emit(checkpoint_id)

func set_aura(active: bool) -> void:
	if aura_active == active:
		return
	aura_active = active
	aura_changed.emit(aura_active)

func lose_life() -> bool:
	lives = maxi(lives - 1, 0)
	lives_changed.emit(lives)
	return lives > 0

func reset_level_state(spawn_position: Vector2) -> void:
	lives = DEFAULT_LIVES
	aura_active = false
	checkpoint_position = spawn_position
	checkpoint_id = "start"
	lives_changed.emit(lives)
	aura_changed.emit(aura_active)

func complete_current_level() -> void:
	if is_level_complete:
		return
	is_level_complete = true
	level_completed.emit(current_level_id)

func prepare_next_level() -> void:
	checkpoint_position = Vector2.ZERO
	checkpoint_id = ""
	aura_active = false
	lives_changed.emit(lives)
	aura_changed.emit(aura_active)

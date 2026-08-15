extends Node

## Estado persistente y desacoplado para niveles, checkpoints y transición futura.
signal lives_changed(current_lives: int)
signal aura_changed(is_active: bool)
signal checkpoint_changed(checkpoint_id: String)
signal level_begun(level_id: String)
signal level_completed(level_id: String)
signal coins_changed(total_coins: int)
signal speed_boost_changed(is_active: bool)
signal invincibility_changed(is_active: bool)

const DEFAULT_LIVES := 3

var lives := DEFAULT_LIVES
var aura_active := false
var checkpoint_position := Vector2.ZERO
var checkpoint_id := ""
var current_level_id := ""
var is_level_complete := false
var coins := 0
var has_seen_intro := false

## Orden global (LevelProgression.get_global_order) del nivel más avanzado
## que el jugador ya desbloqueó. Nunca baja; lo usa el mapa del mundo para
## decidir qué niveles se pueden elegir. 1 = Mundo 1 Nivel 1, siempre
## desbloqueado desde el arranque.
var highest_order_reached := 1

## Cuando true, el próximo nivel que arranque debe reubicar a Luke en
## checkpoint_position en vez de en su SpawnPoint (usado por "Cargar partida").
var resume_at_checkpoint := false

func begin_level(level_id: String, spawn_position: Vector2) -> void:
	var entering_new_level := current_level_id != level_id
	current_level_id = level_id
	is_level_complete = false
	if (entering_new_level or checkpoint_position == Vector2.ZERO) and not resume_at_checkpoint:
		checkpoint_position = spawn_position
		checkpoint_id = "start"
	lives_changed.emit(lives)
	aura_changed.emit(aura_active)
	coins_changed.emit(coins)
	level_begun.emit(level_id)

## Debe llamarse desde el _ready() de cada nivel, después de begin_level(),
## para saber si hay que reubicar a Luke en el checkpoint guardado.
func consume_resume_flag() -> bool:
	var was_resuming := resume_at_checkpoint
	resume_at_checkpoint = false
	return was_resuming

func set_checkpoint(id: String, position: Vector2) -> void:
	checkpoint_id = id
	checkpoint_position = position
	checkpoint_changed.emit(checkpoint_id)
	SaveManager.save_game()

func set_aura(active: bool) -> void:
	if aura_active == active:
		return
	aura_active = active
	aura_changed.emit(aura_active)

## Buffs temporizados: no persisten entre niveles ni se guardan, a
## diferencia del aura protectora.
func set_speed_boost(active: bool) -> void:
	speed_boost_changed.emit(active)

func set_invincibility(active: bool) -> void:
	invincibility_changed.emit(active)

func add_coins(amount: int = 1) -> void:
	coins += amount
	coins_changed.emit(coins)
	SaveManager.save_game()

func lose_life() -> bool:
	lives = maxi(lives - 1, 0)
	lives_changed.emit(lives)
	SaveManager.save_game()
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
	var next_order := LevelProgression.get_global_order(current_level_id) + 1
	highest_order_reached = maxi(highest_order_reached, next_order)
	level_completed.emit(current_level_id)
	SaveManager.save_game()

func prepare_next_level() -> void:
	checkpoint_position = Vector2.ZERO
	checkpoint_id = ""
	aura_active = false
	lives_changed.emit(lives)
	aura_changed.emit(aura_active)

## Reinicia todo el progreso para una partida nueva desde cero.
## has_seen_intro NO se toca: es permanente una vez visto.
func reset_for_new_game() -> void:
	lives = DEFAULT_LIVES
	aura_active = false
	checkpoint_position = Vector2.ZERO
	checkpoint_id = ""
	current_level_id = ""
	is_level_complete = false
	coins = 0
	resume_at_checkpoint = false
	highest_order_reached = 1

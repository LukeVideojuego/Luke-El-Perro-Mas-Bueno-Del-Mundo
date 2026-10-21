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
signal bone_throw_unlocked_changed(is_unlocked: bool)
## C1: se quedo sin vidas. El nivel NO se reinicia solo: main.gd muestra la
## pantalla negra de "Te has quedado sin vidas" con CONTINUAR / GAME OVER.
signal out_of_lives(level_id: String)
signal continues_changed(remaining: int)

const DEFAULT_LIVES := 3
## C1: continues totales por partida (no por nivel).
const DEFAULT_CONTINUES := 3

var lives := DEFAULT_LIVES
## C1: cuantos CONTINUAR le quedan al jugador en esta partida.
var continues_left := DEFAULT_CONTINUES
var aura_active := false
var checkpoint_position := Vector2.ZERO
var checkpoint_id := ""
var current_level_id := ""
var is_level_complete := false
var coins := 0
var has_seen_intro := false
var has_seen_world1_cheer := false

## --- C3: TIENDA ---
## Cosmeticos permanentes ya comprados (ids de ShopCatalog).
var owned_items: Array[String] = []
## Sombrero equipado ("" = ninguno) y si el traje con capa esta puesto.
var equipped_hat := ""
var suit_equipped := false
## Comprados en la tienda y pendientes de aplicarse al empezar el nivel.
var pending_star := false
var pending_boots := false
var pending_aura := false
var pending_hearts := 0
## Municion del ladrido de onda expansiva (reemplaza al huesito mientras haya).
var bark_ammo := 0

signal shop_changed

## Permanente una vez conseguido el primer huesito: desbloquea el ataque a
## distancia de Luke (doble tap del botón de ataque). Nunca se desactiva.
var bone_throw_unlocked := false

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

## C3: intenta comprar un item de la tienda. Devuelve false si no alcanza la
## plata o si es un cosmetico que ya tiene.
func buy_item(item_id: String) -> bool:
	var item := ShopCatalog.get_item(item_id)
	if item.is_empty():
		return false
	if ShopCatalog.is_permanent(item) and owned_items.has(item_id):
		return false
	var price: int = int(item.price)
	if coins < price:
		return false
	coins -= price
	match item.kind:
		ShopCatalog.Kind.HAT:
			owned_items.append(item_id)
			equipped_hat = item_id
		ShopCatalog.Kind.SUIT:
			owned_items.append(item_id)
			suit_equipped = true
		ShopCatalog.Kind.AMMO:
			bark_ammo += int(item.get("amount", 1))
		ShopCatalog.Kind.CONSUMABLE:
			match item_id:
				"star": pending_star = true
				"boots": pending_boots = true
				"aura": pending_aura = true
				"heart": pending_hearts += 1
	coins_changed.emit(coins)
	shop_changed.emit()
	SaveManager.save_game()
	return true

## C3: ponerse/sacarse un sombrero ya comprado, o el traje.
func toggle_equipped(item_id: String) -> void:
	var item := ShopCatalog.get_item(item_id)
	if item.is_empty() or not owned_items.has(item_id):
		return
	if item.kind == ShopCatalog.Kind.HAT:
		equipped_hat = "" if equipped_hat == item_id else item_id
	elif item.kind == ShopCatalog.Kind.SUIT:
		suit_equipped = not suit_equipped
	shop_changed.emit()
	SaveManager.save_game()

## C3: gasta un ladrido. Devuelve false si no queda municion.
func consume_bark() -> bool:
	if bark_ammo <= 0:
		return false
	bark_ammo -= 1
	shop_changed.emit()
	return true

## C2: vida extra de las cajas escondidas.
func add_life(amount: int = 1) -> void:
	lives += amount
	lives_changed.emit(lives)
	SaveManager.save_game()

func unlock_bone_throw() -> void:
	if bone_throw_unlocked:
		return
	bone_throw_unlocked = true
	bone_throw_unlocked_changed.emit(true)
	SaveManager.save_game()

func lose_life() -> bool:
	lives = maxi(lives - 1, 0)
	lives_changed.emit(lives)
	SaveManager.save_game()
	return lives > 0

## C1: lo llama level_base cuando Luke perdio la ultima vida. Se protege de
## emitir dos veces seguidas (el nivel sigue vivo unos frames mas).
var _out_of_lives_pending := false

func report_out_of_lives() -> void:
	if _out_of_lives_pending:
		return
	_out_of_lives_pending = true
	SaveManager.save_game()
	out_of_lives.emit(current_level_id)

## C1: gasta un continue y deja el estado listo para reiniciar el nivel con
## 3 vidas desde el principio. Devuelve false si ya no quedaban.
func use_continue() -> bool:
	if continues_left <= 0:
		return false
	continues_left -= 1
	continues_changed.emit(continues_left)
	lives = DEFAULT_LIVES
	aura_active = false
	checkpoint_position = Vector2.ZERO
	checkpoint_id = ""
	is_level_complete = false
	_out_of_lives_pending = false
	lives_changed.emit(lives)
	aura_changed.emit(aura_active)
	SaveManager.save_game()
	return true

func clear_out_of_lives() -> void:
	_out_of_lives_pending = false

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
## has_seen_intro y has_seen_world1_cheer NO se tocan: son permanentes
## una vez vistos.
func reset_for_new_game() -> void:
	lives = DEFAULT_LIVES
	continues_left = DEFAULT_CONTINUES
	_out_of_lives_pending = false
	continues_changed.emit(continues_left)
	aura_active = false
	checkpoint_position = Vector2.ZERO
	checkpoint_id = ""
	current_level_id = ""
	is_level_complete = false
	coins = 0
	resume_at_checkpoint = false
	highest_order_reached = 1
	owned_items = []
	equipped_hat = ""
	suit_equipped = false
	pending_star = false
	pending_boots = false
	pending_aura = false
	pending_hearts = 0
	bark_ammo = 0
	shop_changed.emit()

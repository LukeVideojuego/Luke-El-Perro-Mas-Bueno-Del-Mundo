class_name HugMinigame
extends LevelBase

## Minijuego final: abrazar a la mayor cantidad de gente posible antes de que
## se acabe el tiempo.
##
## E4: antes, agotar el reloj completaba el nivel SIEMPRE, aunque Luke no
## hubiera abrazado a nadie (el final del juego se daba por visto sin que el
## jugador hiciera nada). Ahora el resultado depende del medidor de amor:
## abrazar a TODOS siempre completa (sin importar el tiempo), pero si se
## agota el reloj sin llegar a la mitad del objetivo (LOVE_THRESHOLD_RATIO),
## se muestra "Se acabó el tiempo" con la opción de reintentar en vez de
## marcar el nivel como completado.

@export var time_limit := 45.0
## Umbral "balanceado" pedido: con la mitad de la gente abrazada ya se
## considera que Luke se gano el final (no hace falta un 100% perfecto
## contra el reloj), pero menos que eso es claramente insuficiente.
const LOVE_THRESHOLD_RATIO := 0.5

@onready var timer_label: Label = $HugHUD/Panel/TimerLabel
@onready var love_label: Label = $HugHUD/Panel/LoveLabel
@onready var love_bar: ProgressBar = $HugHUD/Panel/LoveBar
@onready var retry_hud: CanvasLayer = $RetryHUD
@onready var retry_detail_label: Label = $RetryHUD/DetailLabel
@onready var retry_button: Button = $RetryHUD/RetryButton

var time_left := 0.0
var hugged_count := 0
var total_people := 0
var minigame_over := false
var people: Array[HuggablePerson] = []

func _ready() -> void:
	super._ready()
	time_left = time_limit
	for child in get_tree().get_nodes_in_group("huggable"):
		if child is HuggablePerson:
			people.append(child)
			child.hugged.connect(_on_person_hugged)
	total_people = people.size()
	_update_hud()
	if retry_button != null:
		retry_button.pressed.connect(_on_retry_pressed)

func _process(delta: float) -> void:
	if minigame_over:
		return
	time_left = maxf(0.0, time_left - delta)
	_update_hud()
	if time_left <= 0.0:
		_on_time_up()

func _on_person_hugged(_person: HuggablePerson) -> void:
	if minigame_over:
		return
	hugged_count += 1
	_update_hud()
	if hugged_count >= total_people:
		_finish_minigame()

func _update_hud() -> void:
	if timer_label != null:
		timer_label.text = "%02d" % int(ceil(time_left))
	if love_label != null:
		love_label.text = "%d / %d" % [hugged_count, total_people]
	if love_bar != null:
		love_bar.value = (float(hugged_count) / float(total_people)) * 100.0 if total_people > 0 else 0.0

func _love_threshold() -> int:
	return int(ceil(total_people * LOVE_THRESHOLD_RATIO))

## Al agotarse el reloj: completa si Luke llego al umbral de amor, si no
## muestra la pantalla de reintentar (nunca el cartel de nivel completado).
func _on_time_up() -> void:
	if minigame_over:
		return
	if hugged_count >= _love_threshold():
		_finish_minigame()
	else:
		_show_retry()

func _finish_minigame() -> void:
	if minigame_over:
		return
	minigame_over = true
	GameState.complete_current_level()

func _show_retry() -> void:
	minigame_over = true
	if retry_detail_label != null:
		retry_detail_label.text = "Abrazaste a %d de %d (necesitabas al menos %d). ¡Probá de nuevo!" % [
			hugged_count, total_people, _love_threshold()]
	if retry_hud != null:
		retry_hud.visible = true

func _on_retry_pressed() -> void:
	retry_hud.visible = false
	hugged_count = 0
	time_left = time_limit
	minigame_over = false
	for person in people:
		if is_instance_valid(person):
			person.reset_hug()
	if luke != null and spawn_point != null:
		luke.respawn(spawn_point.global_position)
	_update_hud()

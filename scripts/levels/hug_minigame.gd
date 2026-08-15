class_name HugMinigame
extends LevelBase

## Minijuego final: abrazar a la mayor cantidad de gente posible antes de que
## se acabe el tiempo. Termina cuando se abraza a todos o se agota el reloj;
## en ambos casos se marca el nivel como completado (no hace falta llegar a
## una bandera).

@export var time_limit := 45.0

@onready var timer_label: Label = $HugHUD/Panel/TimerLabel
@onready var love_label: Label = $HugHUD/Panel/LoveLabel
@onready var love_bar: ProgressBar = $HugHUD/Panel/LoveBar

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

func _process(delta: float) -> void:
	if minigame_over:
		return
	time_left = maxf(0.0, time_left - delta)
	_update_hud()
	if time_left <= 0.0:
		_finish_minigame()

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

func _finish_minigame() -> void:
	if minigame_over:
		return
	minigame_over = true
	GameState.complete_current_level()

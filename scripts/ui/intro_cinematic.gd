extends CanvasLayer

signal finished

const PANEL_1 = 1
const PANEL_2 = 2
const PANEL_3 = 3

var current_panel := PANEL_1
var _finished := false
var _timeout_timer: SceneTreeTimer = null
var _panel_tween: Tween = null

@onready var panel1: Control = $Panel1
@onready var panel2: Control = $Panel2
@onready var panel3: Control = $Panel3

func _ready() -> void:
	_update_panel(PANEL_1)
	_start_timeout()
	$Panel1/Panel1Button.pressed.connect(_on_button_pressed)
	$Panel2/Panel2Button.pressed.connect(_on_button_pressed)
	$Panel3/Panel3Button.pressed.connect(_on_button_pressed)

## Cada panel tiene su propio timeout de 10s que lo AVANZA al siguiente
## (nunca termina toda la cinemática de golpe): si el jugador no toca nada,
## las 3 pantallas igual se muestran una por una en orden, y recién al
## vencer el timeout del panel 3 se llama a _finish(). Antes _auto_finish()
## llamaba a finished.emit() directamente sin importar en qué panel
## estuviera, así que quedarse quieto en el panel 1 saltaba directo al
## Nivel 1 sin mostrar los paneles 2 y 3.
func _start_timeout() -> void:
	_cancel_timeout()
	_timeout_timer = get_tree().create_timer(10.0)
	_timeout_timer.timeout.connect(_auto_finish)

func _auto_finish() -> void:
	if _finished:
		return
	_advance()

func _finish() -> void:
	if _finished:
		return
	_finished = true
	finished.emit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_advance()

func _on_button_pressed() -> void:
	_advance()

func _advance() -> void:
	if current_panel == PANEL_1:
		_update_panel(PANEL_2)
	elif current_panel == PANEL_2:
		_update_panel(PANEL_3)
	else:
		_finish()
		return
	_start_timeout()

func _move_to_panel(panel: int) -> void:
	current_panel = panel
	_update_panel(panel)

func _panel_node(panel: int) -> Control:
	match panel:
		PANEL_1: return panel1
		PANEL_2: return panel2
		PANEL_3: return panel3
	return null

func _all_panels() -> Array:
	return [panel1, panel2, panel3]

## Cruza en fundido entre paneles en vez de un corte seco (visible=true/false
## instantáneo), que se percibía como un parpadeo entre imágenes distintas.
## Los paneles vienen con visible=true por defecto en el .tscn, así que
## siempre se ocultan explícitamente todos los que no sean el viejo/nuevo.
func _update_panel(panel: int) -> void:
	var old_panel := _panel_node(current_panel)
	var new_panel := _panel_node(panel)
	var is_same := panel == current_panel
	current_panel = panel
	if _panel_tween != null and _panel_tween.is_valid():
		_panel_tween.kill()
	for p in _all_panels():
		if p != old_panel and p != new_panel:
			p.visible = false
	if is_same:
		new_panel.visible = true
		new_panel.modulate.a = 1.0
		return
	old_panel.modulate.a = 1.0
	new_panel.visible = true
	new_panel.modulate.a = 0.0
	_panel_tween = create_tween()
	_panel_tween.tween_property(new_panel, "modulate:a", 1.0, 0.2)
	_panel_tween.parallel().tween_property(old_panel, "modulate:a", 0.0, 0.2)
	await _panel_tween.finished
	old_panel.visible = false
	old_panel.modulate.a = 1.0

func _cancel_timeout() -> void:
	if _timeout_timer != null:
		if _timeout_timer.timeout.is_connected(_auto_finish):
			_timeout_timer.timeout.disconnect(_auto_finish)
		_timeout_timer = null

func get_current_panel() -> int:
	return current_panel

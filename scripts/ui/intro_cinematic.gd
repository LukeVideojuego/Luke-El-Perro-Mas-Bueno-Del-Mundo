extends CanvasLayer

signal finished

const PANEL_1 = 1
const PANEL_2 = 2
const PANEL_3 = 3

var current_panel := PANEL_1
var _finished := false
var _panel_tween: Tween = null

## A1: las cinemáticas NO avanzan solas -- el jugador tiene que apretar el
## botón "SIGUIENTE" visible, o cualquiera de estas acciones equivalentes
## (Enter/Espacio via ui_accept, o el botón de acción del juego).
const WATCHED_ACTIONS := ["ui_accept", "interact", "attack"]

@onready var panel1: Control = $Panel1
@onready var panel2: Control = $Panel2
@onready var panel3: Control = $Panel3

func _ready() -> void:
	_update_panel(PANEL_1)
	$Panel1/Panel1Button.pressed.connect(_on_button_pressed)
	$Panel2/Panel2Button.pressed.connect(_on_button_pressed)
	$Panel3/Panel3Button.pressed.connect(_on_button_pressed)

func _finish() -> void:
	if _finished:
		return
	_finished = true
	finished.emit()

func _input(event: InputEvent) -> void:
	for action in WATCHED_ACTIONS:
		if event.is_action_pressed(action):
			_advance()
			return

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

func get_current_panel() -> int:
	return current_panel

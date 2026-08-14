extends CanvasLayer

signal finished

const PANEL_1 = 1
const PANEL_2 = 2
const PANEL_3 = 3

var current_panel := PANEL_1
var _finished := false
var _timeout_timer: SceneTreeTimer = null

@onready var panel1: Control = $Panel1
@onready var panel2: Control = $Panel2
@onready var panel3: Control = $Panel3

func _ready() -> void:
	_update_panel(current_panel)
	_start_timeout()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		if current_panel == PANEL_3:
			_finish()
		else:
			_move_to_next_panel()
		_cancel_timeout()

func _start_timeout() -> void:
	_cancel_timeout()
	_timeout_timer = get_tree().create_timer(10.0)
	_timeout_timer.timeout.connect(_auto_finish)

func _auto_finish() -> void:
	if _finished:
		return
	_finished = true
	finished.emit()

func _finish() -> void:
	if _finished:
		return
	_finished = true
	finished.emit()

func _move_to_next_panel() -> void:
	if current_panel == PANEL_1:
		_update_panel(PANEL_2)
	elif current_panel == PANEL_2:
		_update_panel(PANEL_3)
	else:
		finished.emit()

func _update_panel(panel: int) -> void:
	current_panel = panel
	panel1.visible = current_panel == PANEL_1
	panel2.visible = current_panel == PANEL_2
	panel3.visible = current_panel == PANEL_3

func _cancel_timeout() -> void:
	if _timeout_timer != null:
		if _timeout_timer.timeout.is_connected(_auto_finish):
			_timeout_timer.timeout.disconnect(_auto_finish)
		_timeout_timer = null

func get_current_panel() -> int:
	return current_panel
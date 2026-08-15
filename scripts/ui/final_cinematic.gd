extends CanvasLayer

signal finished

const PANEL_1 = 1
const PANEL_2 = 2

var current_panel := PANEL_1
var _finished := false
var _timeout_timer: SceneTreeTimer = null

@onready var panel1: Control = $Panel1
@onready var panel2: Control = $Panel2

func _ready() -> void:
	_update_panel(PANEL_1)
	_start_timeout()
	$Panel1/Panel1Button.pressed.connect(_on_button_pressed)
	$Panel2/Panel2Button.pressed.connect(_on_button_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		_on_button_pressed()
		_cancel_timeout()

func _on_button_pressed() -> void:
	if current_panel == PANEL_1:
		_update_panel(PANEL_2)
		_start_timeout()
	else:
		_finish()
	_cancel_timeout()

func _start_timeout() -> void:
	_cancel_timeout()
	_timeout_timer = get_tree().create_timer(10.0)
	_timeout_timer.timeout.connect(_auto_advance)

func _auto_advance() -> void:
	if _finished:
		return
	if current_panel == PANEL_1:
		_update_panel(PANEL_2)
		_start_timeout()
	else:
		_finish()

func _finish() -> void:
	if _finished:
		return
	_finished = true
	_cancel_timeout()
	finished.emit()

func _update_panel(panel: int) -> void:
	current_panel = panel
	panel1.visible = current_panel == PANEL_1
	panel2.visible = current_panel == PANEL_2

func _cancel_timeout() -> void:
	if _timeout_timer != null:
		if _timeout_timer.timeout.is_connected(_auto_advance):
			_timeout_timer.timeout.disconnect(_auto_advance)
		_timeout_timer = null

func get_current_panel() -> int:
	return current_panel

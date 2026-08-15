extends CanvasLayer

signal finished

var _finished := false
var _timeout_timer: SceneTreeTimer = null

func _ready() -> void:
	_start_timeout()
	if has_node("Panel1/Panel1Button"):
		$Panel1/Panel1Button.pressed.connect(_finish)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		_finish()

func _start_timeout() -> void:
	_cancel_timeout()
	_timeout_timer = get_tree().create_timer(12.0)
	_timeout_timer.timeout.connect(_finish)

func _finish() -> void:
	if _finished:
		return
	_finished = true
	_cancel_timeout()
	finished.emit()

func _cancel_timeout() -> void:
	if _timeout_timer != null:
		if _timeout_timer.timeout.is_connected(_finish):
			_timeout_timer.timeout.disconnect(_finish)
		_timeout_timer = null

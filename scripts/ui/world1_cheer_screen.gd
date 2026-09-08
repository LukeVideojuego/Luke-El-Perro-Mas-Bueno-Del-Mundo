extends CanvasLayer

## Pantalla única (solo la primera vez) que se muestra al completar el
## Mundo 1, antes de pasar al Mundo 2. Mismo patrón de auto-timeout que
## las cinemáticas (scripts/ui/intro_cinematic.gd).
signal finished

var _finished := false
var _timeout_timer: SceneTreeTimer = null

func _ready() -> void:
	$Panel/ContinueButton.pressed.connect(_finish)
	_timeout_timer = get_tree().create_timer(12.0)
	_timeout_timer.timeout.connect(_finish)

func _finish() -> void:
	if _finished:
		return
	_finished = true
	finished.emit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_finish()

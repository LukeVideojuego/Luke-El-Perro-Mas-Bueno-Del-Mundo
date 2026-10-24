extends CanvasLayer

## Pantalla única (solo la primera vez) que se muestra al completar el
## Mundo 1, antes de pasar al Mundo 2.
## A1: no avanza sola -- requiere el botón "CONTINUAR" visible, o
## Enter/Espacio (ui_accept) o el botón de acción del juego.
signal finished

const WATCHED_ACTIONS := ["ui_accept", "interact", "attack"]

var _finished := false

func _ready() -> void:
	$Panel/ContinueButton.pressed.connect(_finish)

func _finish() -> void:
	if _finished:
		return
	_finished = true
	finished.emit()

func _input(event: InputEvent) -> void:
	for action in WATCHED_ACTIONS:
		if event.is_action_pressed(action):
			_finish()
			return

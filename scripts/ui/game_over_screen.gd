extends CanvasLayer

## C1: pantalla negra de "Te has quedado sin vidas", con CONTINUAR y GAME
## OVER. Se muestra al perder la ultima vida en vez de reiniciar el nivel
## solo con 3 vidas (que era lo que pasaba antes y no se entendia).
##
## Hay 3 continues por partida. Si no quedan, el boton CONTINUAR aparece
## deshabilitado y la unica salida es volver al menu principal.
##
## El arte es el que entrego el usuario (referencia_visual/game-over.png ->
## assets/backgrounds/Cinematics/game_over_panel.png): ya trae escrito "TE HAS
## QUEDADO SIN VIDAS PARA SALVAR EL MUNDO" en el cartel, asi que la pantalla
## no repite ese texto por encima.

signal continue_requested
signal game_over_requested

@onready var continues_label: Label = $ContinuesLabel
@onready var continue_button: Button = $ContinueButton
@onready var game_over_button: Button = $GameOverButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	continue_button.pressed.connect(func() -> void: continue_requested.emit())
	game_over_button.pressed.connect(func() -> void: game_over_requested.emit())

func setup(continues_left: int) -> void:
	if continues_left > 0:
		continues_label.text = "Te quedan %d continue%s" % [continues_left, "" if continues_left == 1 else "s"]
		continue_button.disabled = false
		continue_button.grab_focus()
	else:
		continues_label.text = "No te quedan continues"
		continue_button.disabled = true
		game_over_button.grab_focus()

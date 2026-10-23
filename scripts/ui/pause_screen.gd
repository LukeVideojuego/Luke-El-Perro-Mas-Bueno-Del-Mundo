extends CanvasLayer

## B4: cartel de PAUSA. Vive en main.tscn con process_mode = ALWAYS para
## seguir dibujandose (y para que el juego pueda despausarse) con el arbol
## pausado. Quien decide cuando se muestra es main.gd.
##
## F6: antes esto era solo texto -- "pausa" no tenia forma de salir mas que
## apretando ESC de nuevo, y (bug aparte, ver main.tscn) el resto del juego
## seguia corriendo porque LevelContainer heredaba el process_mode=ALWAYS
## de Main. Ahora tiene botones reales: REANUDAR (listo abajo) y SALIR AL
## MENU PRINCIPAL.

signal resume_requested
signal exit_requested

@onready var resume_button: Button = $ResumeButton
@onready var exit_button: Button = $ExitButton

func _ready() -> void:
	resume_button.pressed.connect(func() -> void: resume_requested.emit())
	exit_button.pressed.connect(func() -> void: exit_requested.emit())

func show_paused() -> void:
	visible = true

func hide_paused() -> void:
	visible = false

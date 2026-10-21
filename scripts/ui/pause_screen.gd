extends CanvasLayer

## B4: cartel de PAUSA. Vive en main.tscn con process_mode = ALWAYS para
## seguir dibujandose (y para que el juego pueda despausarse) con el arbol
## pausado. Quien decide cuando se muestra es main.gd.

func show_paused() -> void:
	visible = true

func hide_paused() -> void:
	visible = false

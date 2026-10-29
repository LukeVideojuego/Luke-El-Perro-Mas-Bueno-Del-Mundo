extends CanvasLayer
class_name TapToStart

## Punto 1 (web): "TOCÁ PARA EMPEZAR". Los navegadores (sobre todo Safari
## de iPhone) no dejan sonar nada hasta que el jugador toca la pantalla.
## Esta pantalla aparece al abrir el juego en el navegador y espera ese
## primer toque/clic/tecla: la pagina (LukeWeb.unlock, en
## web/head_include.html) despierta el audio DENTRO de ese mismo toque, y
## recien ahi se pasa al menu con su musica.
##
## En la compu (ejecutable) no hace falta y no se muestra.

signal started

## Ademas del navegador, se puede forzar para probarla: -- --tap-to-start
static func needed() -> bool:
	return OS.has_feature("web") or OS.get_cmdline_user_args().has("--tap-to-start")

var _luke: TextureRect
var _label: Label
var _done := false

func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.13, 0.3)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 30)
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	_luke = TextureRect.new()
	_luke.texture = load("res://assets/characters/Luke/luke_idle.png")
	_luke.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_luke.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_luke.custom_minimum_size = Vector2(0, 520)
	_luke.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_luke)
	_label = Label.new()
	_label.text = "¡TOCÁ PARA EMPEZAR!"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 130)
	_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35))
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 26)
	box.add_child(_label)

func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	_luke.pivot_offset = _luke.size * Vector2(0.5, 1.0)
	_luke.scale = Vector2.ONE * (1.0 + sin(t * 4.0) * 0.03)
	_label.pivot_offset = _label.size * 0.5
	_label.scale = Vector2.ONE * (1.0 + sin(t * 3.0) * 0.04)

## Se sigue al SOLTAR (fin del toque / clic): en iPhone es ese momento el
## que habilita el audio, y asi el toque tampoco llega a apretar un boton
## del menu de abajo.
func _input(event: InputEvent) -> void:
	if _done:
		get_viewport().set_input_as_handled()
		return
	var released: bool = (event is InputEventScreenTouch and not event.pressed) \
			or (event is InputEventMouseButton and not event.pressed) \
			or (event is InputEventKey and not event.pressed and not event.echo)
	get_viewport().set_input_as_handled()
	if released:
		_done = true
		started.emit()
		queue_free()

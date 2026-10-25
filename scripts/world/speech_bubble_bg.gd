extends Control

## A2: fondo del globo de dialogo tipo comic de los chicos (kid_npc.tscn).
## Dibuja un rectangulo blanco de esquinas redondeadas con borde negro,
## mas una "colita" triangular apuntando hacia la cabeza del chico (el
## origen local del nodo, ya que el sprite del chico esta centrado ahi).
## El tamaño se recalcula en base al texto real de label_path, asi que el
## globo siempre se ajusta al largo de cada frase en los 12 niveles.

@export var label_path: NodePath
@export var max_text_width := 560.0
@export var padding := Vector2(28, 20)
@export var tail_tip := Vector2(0.0, -95.0)
@export var tail_half_width := 16.0
@export var bubble_bottom_y := -185.0
@export var corner_radius := 18
@export var border_width := 4
## A4: marron del pelaje del cuerpo de Luke (sampleado de luke_idle.png),
## para que el globo deje de ser blanco generico.
@export var bg_color := Color(0.42, 0.26, 0.18)

var _label: Label
var _was_visible := false
var _bubble_rect := Rect2()

func _ready() -> void:
	_label = get_node_or_null(label_path)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	if _label == null:
		return
	visible = _label.visible
	if visible:
		_layout()
		queue_redraw()

func _layout() -> void:
	var font: Font = _label.get_theme_font("font")
	if font == null:
		font = ThemeDB.fallback_font
	var font_size: int = _label.get_theme_font_size("font_size")
	if font_size <= 0:
		font_size = 20
	var text_size: Vector2 = font.get_multiline_string_size(
		_label.text, HORIZONTAL_ALIGNMENT_CENTER, max_text_width, font_size)
	var bubble_size: Vector2 = text_size + padding * 2.0
	bubble_size.x = max(bubble_size.x, 120.0)
	bubble_size.y = max(bubble_size.y, 70.0)
	var bubble_pos := Vector2(-bubble_size.x / 2.0, bubble_bottom_y - bubble_size.y)
	_bubble_rect = Rect2(bubble_pos, bubble_size)

	_label.position = bubble_pos + padding
	_label.size = bubble_size - padding * 2.0
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.clip_text = false

func _draw() -> void:
	if not visible or _bubble_rect.size == Vector2.ZERO:
		return
	var base_y: float = _bubble_rect.position.y + _bubble_rect.size.y
	var left := Vector2(-tail_half_width, base_y)
	var right := Vector2(tail_half_width, base_y)

	draw_colored_polygon([left, right, tail_tip], bg_color)
	draw_line(left, tail_tip, Color.BLACK, border_width)
	draw_line(right, tail_tip, Color.BLACK, border_width)

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = Color.BLACK
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	draw_style_box(style, _bubble_rect)

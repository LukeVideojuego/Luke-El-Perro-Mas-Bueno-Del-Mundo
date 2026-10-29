extends Node

## Punto 2: el juego llena la pantalla en cualquier tamaño (celular, tablet,
## compu) sin deformarse ni dejar zonas grises.
##
## El escalado del proyecto es canvas_items + aspect "expand": el area visible
## siempre mide al menos 1920x1080 y crece en ancho (celulares, mas
## alargados) o en alto (tablets 4:3) segun la pantalla. Eso por si solo deja
## dos problemas, que se arreglan aca sin tocar cada escena:
##
##  1. Camaras de los niveles: si el area visible es mas grande que el
##     rectangulo que cubre el fondo del nivel (limit_* de la Camera2D), se
##     veria gris afuera. Se sube el zoom lo justo para que nunca pase.
##  2. Pantallas diseñadas a 1920x1080 con posiciones fijas (menu, tienda,
##     album, mapa, cinematicas, Game Over...): el diseño se centra en el area
##     visible y sus fondos se estiran para cubrirla entera. Los Control
##     anclados (centro, pantalla completa) ya se adaptan solos.
##
## Ademas muestra el aviso "Girá el celular" si la pantalla esta en vertical.

const DESIGN := Vector2(1920.0, 1080.0)

## Pantallas cuyo diseño se centra/cubre. El HUD queda afuera a proposito:
## va pegado arriba a la izquierda en cualquier tamaño.
const FIT_SCENES := [
	"res://scenes/ui/main_menu.tscn",
	"res://scenes/ui/album_screen.tscn",
	"res://scenes/ui/world_map.tscn",
	"res://scenes/ui/shop_screen.tscn",
	"res://scenes/ui/pause_screen.tscn",
	"res://scenes/ui/game_over_screen.tscn",
	"res://scenes/ui/level_transition.tscn",
	"res://scenes/cinematics/intro_cinematic.tscn",
	"res://scenes/cinematics/final_cinematic.tscn",
	"res://scenes/cinematics/world1_cheer_screen.tscn",
]

var _layers: Array[CanvasLayer] = []
var _rotate_notice: CanvasLayer
var _paused_by_notice := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	get_viewport().size_changed.connect(_on_size_changed)
	_build_rotate_notice()

func visible_size() -> Vector2:
	return get_viewport().get_visible_rect().size

func _on_node_added(node: Node) -> void:
	if node is CanvasLayer and FIT_SCENES.has(node.scene_file_path):
		_layers.append(node)
		node.ready.connect(_fit_layer.bind(node), CONNECT_ONE_SHOT)
		node.tree_exiting.connect(func() -> void: _layers.erase(node), CONNECT_ONE_SHOT)

func _on_size_changed() -> void:
	for layer in _layers:
		if is_instance_valid(layer):
			_fit_layer(layer)
	_update_rotate_notice()

func _process(_delta: float) -> void:
	_fit_camera()
	if _rotate_notice.visible:
		# Luke se balancea como si girara el celular.
		var luke: Control = _rotate_notice.get_node("Box/Luke")
		luke.pivot_offset = luke.size * 0.5
		luke.rotation = sin(Time.get_ticks_msec() / 350.0) * 0.18

# --- Camaras -----------------------------------------------------------------

func _fit_camera() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	# Si algo de afuera (un script, un test) cambio el zoom, ese pasa a ser
	# el zoom "de diseño" de esta camara.
	if not cam.has_meta("fit_applied") or cam.zoom != cam.get_meta("fit_applied"):
		cam.set_meta("fit_base", cam.zoom)
	var base: Vector2 = cam.get_meta("fit_base")
	var s := visible_size()
	var limit_w := float(cam.limit_right - cam.limit_left)
	var limit_h := float(cam.limit_bottom - cam.limit_top)
	var needed := 0.0
	if limit_w > 0.0 and limit_w < 1000000.0:
		needed = maxf(needed, s.x / limit_w)
	if limit_h > 0.0 and limit_h < 1000000.0:
		needed = maxf(needed, s.y / limit_h)
	var z := Vector2(maxf(base.x, needed), maxf(base.y, needed))
	cam.zoom = z
	cam.set_meta("fit_applied", z)

# --- Pantallas diseñadas a 1920x1080 -----------------------------------------

func _fit_layer(layer: CanvasLayer) -> void:
	if not is_instance_valid(layer):
		return
	var s := visible_size()
	var off := Vector2(maxf(0.0, (s.x - DESIGN.x) * 0.5), maxf(0.0, (s.y - DESIGN.y) * 0.5))
	var cover := maxf(s.x / DESIGN.x, s.y / DESIGN.y)
	for child in layer.get_children():
		if child is Control:
			var c := child as Control
			if _is_full_rect(c):
				# Se estira solo; lo que tenga adentro en coordenadas fijas
				# de diseño se corre al centro.
				for g in c.get_children():
					if g is Control and _is_top_left(g):
						_shift(g, off)
					elif g is Node2D:
						_shift(g, off)
			elif _is_top_left(c):
				if _is_design_backdrop(c):
					_cover_rect(c, Vector2.ZERO, s)
				else:
					_shift(c, off)
					for g in c.get_children():
						if g is Control and _is_design_backdrop(g):
							_cover_rect(g, -off, s)
						elif g is Sprite2D and _is_background_name(g.name):
							_cover_sprite(g, cover, Vector2.ZERO)
		elif child is Sprite2D:
			_cover_sprite(child, cover, off)
		elif child is Node2D:
			for g in child.get_children():
				if g is Sprite2D:
					_cover_sprite(g, cover, off)

func _is_full_rect(c: Control) -> bool:
	return c.anchor_left == 0.0 and c.anchor_top == 0.0 and c.anchor_right == 1.0 and c.anchor_bottom == 1.0

func _is_top_left(c: Control) -> bool:
	return c.anchor_left == 0.0 and c.anchor_top == 0.0 and c.anchor_right == 0.0 and c.anchor_bottom == 0.0

func _is_background_name(n: StringName) -> bool:
	var s := String(n)
	return s.begins_with("Background") or s.begins_with("Sky")

## Un ColorRect que en el diseño ocupaba la pantalla entera (0,0,1920,1080).
func _is_design_backdrop(c: Control) -> bool:
	if not (c is ColorRect):
		return false
	var r: Rect2 = c.get_meta("fit_rect") if c.has_meta("fit_rect") else Rect2(c.position, c.size)
	return r.position == Vector2.ZERO and r.size.x >= DESIGN.x - 1.0 and r.size.y >= DESIGN.y - 1.0

func _shift(n: CanvasItem, off: Vector2) -> void:
	if not n.has_meta("fit_pos"):
		n.set_meta("fit_pos", n.position)
	n.position = n.get_meta("fit_pos") + off

func _cover_rect(c: Control, pos: Vector2, s: Vector2) -> void:
	if not c.has_meta("fit_rect"):
		c.set_meta("fit_rect", Rect2(c.position, c.size))
	c.position = pos
	c.size = s

## Fondo centrado en (960,540). Si la pantalla es mas ancha que 16:9 se
## escala para cubrir (recorta un poco arriba/abajo, que en los fondos es
## cielo/piso). Si es mas alta (tablet 4:3), escalar para cubrir recortaria
## los costados (p.ej. el cartel de HISTORIA del menu): ahi se ajusta al
## ancho y las franjas de arriba/abajo se pintan con el color del borde
## superior/inferior de la propia imagen, asi se ve como una continuacion.
func _cover_sprite(sp: Sprite2D, cover: float, off: Vector2) -> void:
	if not sp.has_meta("fit_pos"):
		sp.set_meta("fit_pos", sp.position)
		sp.set_meta("fit_scale", sp.scale)
	var s := visible_size()
	var taller := s.y / s.x > DESIGN.y / DESIGN.x + 0.001
	var k := (s.x / DESIGN.x) if taller else cover
	sp.position = sp.get_meta("fit_pos") + off
	sp.scale = sp.get_meta("fit_scale") * k
	_update_bands(sp, taller)

func _update_bands(sp: Sprite2D, show: bool) -> void:
	var top: ColorRect = sp.get_node_or_null("FitBandTop")
	var bottom: ColorRect = sp.get_node_or_null("FitBandBottom")
	if not show or sp.texture == null:
		if top != null:
			top.visible = false
			bottom.visible = false
		return
	if top == null:
		var img := sp.texture.get_image()
		if img == null:
			return
		if img.is_compressed():
			img.decompress()
		top = _make_band(sp, "FitBandTop", _row_color(img, 2))
		bottom = _make_band(sp, "FitBandBottom", _row_color(img, img.get_height() - 3))
	top.visible = true
	bottom.visible = true
	# En coordenadas locales del sprite (centrado): bandas enormes pegadas
	# arriba y abajo de la textura, detras de ella.
	var tex := sp.texture.get_size()
	var big := 20000.0
	top.position = Vector2(-big * 0.5, -tex.y * 0.5 - big)
	top.size = Vector2(big, big)
	bottom.position = Vector2(-big * 0.5, tex.y * 0.5)
	bottom.size = Vector2(big, big)

func _make_band(sp: Sprite2D, band_name: String, color: Color) -> ColorRect:
	var band := ColorRect.new()
	band.name = band_name
	band.color = color
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.show_behind_parent = true
	sp.add_child(band)
	return band

func _row_color(img: Image, y: int) -> Color:
	var acc := Color(0, 0, 0, 0)
	var n := 0
	for x in range(0, img.get_width(), 8):
		acc += img.get_pixel(x, y)
		n += 1
	return Color(acc.r / n, acc.g / n, acc.b / n, 1.0)

# --- Aviso "Girá el celular" ---------------------------------------------------

func _build_rotate_notice() -> void:
	_rotate_notice = CanvasLayer.new()
	_rotate_notice.layer = 128
	_rotate_notice.visible = false
	add_child(_rotate_notice)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.08, 0.16, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rotate_notice.add_child(bg)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 60)
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rotate_notice.add_child(box)
	var luke := TextureRect.new()
	luke.name = "Luke"
	luke.texture = load("res://assets/characters/Luke/luke_idle.png")
	luke.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	luke.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	luke.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	luke.custom_minimum_size = Vector2(0, 900)
	box.add_child(luke)
	var label := Label.new()
	label.name = "Message"
	label.text = "¡Girá el celular\npara jugar!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 150)
	label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 24)
	box.add_child(label)
	var arrow := Label.new()
	arrow.name = "Arrow"
	arrow.text = "⟳"
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.add_theme_font_size_override("font_size", 260)
	arrow.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	box.add_child(arrow)
	_update_rotate_notice()

func is_portrait() -> bool:
	var w := get_window().size
	return w.y > w.x

func _update_rotate_notice() -> void:
	var portrait := is_portrait()
	if portrait == _rotate_notice.visible:
		return
	_rotate_notice.visible = portrait
	# Mientras esta en vertical el juego queda congelado (sin perder nada).
	if portrait and not get_tree().paused:
		_paused_by_notice = true
		get_tree().paused = true
	elif not portrait and _paused_by_notice:
		_paused_by_notice = false
		get_tree().paused = false

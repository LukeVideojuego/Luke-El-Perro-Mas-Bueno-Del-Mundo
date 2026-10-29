extends CanvasLayer

## Menú principal: Comenzar juego / Cargar partida / Contraseña de nivel.

## A4: ahora lleva la dificultad elegida ("normal" o "facil").
signal new_game_requested(difficulty: String)
signal continue_requested
signal password_requested(level_id: String)
signal map_requested
## A7: abre el Album de Luke (huellas doradas encontradas por nivel).
signal album_requested

@onready var menu_panel: Control = $MenuPanel
@onready var password_panel: Control = $PasswordPanel
@onready var difficulty_panel: Control = $DifficultyPanel
@onready var new_game_button: Button = $MenuPanel/Center/NewGameButton
@onready var continue_button: Button = $MenuPanel/Center/ContinueButton
@onready var password_button: Button = $MenuPanel/Center/PasswordButton
@onready var map_button: Button = $MenuPanel/Center/MapButton
@onready var album_button: Button = $MenuPanel/Center/AlbumButton
@onready var password_input: LineEdit = $PasswordPanel/Center/PasswordInput
@onready var password_error: Label = $PasswordPanel/Center/ErrorLabel
@onready var password_submit: Button = $PasswordPanel/Center/SubmitButton
@onready var password_back: Button = $PasswordPanel/Center/BackButton
@onready var normal_button: Button = $DifficultyPanel/Center/NormalButton
@onready var easy_button: Button = $DifficultyPanel/Center/EasyButton
@onready var difficulty_back: Button = $DifficultyPanel/Center/BackButton

func _ready() -> void:
	continue_button.disabled = not SaveManager.has_save()
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	password_button.pressed.connect(_on_password_menu_pressed)
	map_button.pressed.connect(func() -> void: map_requested.emit())
	album_button.pressed.connect(func() -> void: album_requested.emit())
	password_submit.pressed.connect(_on_password_submit)
	password_back.pressed.connect(_on_password_back)
	password_input.text_submitted.connect(func(_text: String) -> void: _on_password_submit())
	normal_button.pressed.connect(func() -> void: _on_difficulty_chosen("normal"))
	easy_button.pressed.connect(func() -> void: _on_difficulty_chosen("facil"))
	difficulty_back.pressed.connect(_on_difficulty_back)
	_setup_fullscreen_button()
	if TouchControls.touch_mode:
		# En celular los controles se ven en pantalla: el texto de teclas
		# sobra y su lugar lo ocupan los botones agrandados.
		$MenuPanel/Center/Controls.visible = false
		$MenuPanel/Center/Spacer2.visible = false
		_enlarge_for_touch.call_deferred()
	new_game_button.grab_focus()

## A4: "COMENZAR JUEGO" ya no arranca directo -- primero pregunta dificultad,
## igual que "CONTRASEÑA" ya mostraba su propio panel.
func _on_new_game_pressed() -> void:
	menu_panel.visible = false
	difficulty_panel.visible = true
	normal_button.grab_focus()

func _on_difficulty_chosen(difficulty: String) -> void:
	new_game_requested.emit(difficulty)

func _on_difficulty_back() -> void:
	difficulty_panel.visible = false
	menu_panel.visible = true
	new_game_button.grab_focus()

func _on_continue_pressed() -> void:
	if continue_button.disabled:
		return
	continue_requested.emit()

func _on_password_menu_pressed() -> void:
	menu_panel.visible = false
	password_panel.visible = true
	password_error.visible = false
	password_input.text = ""
	if TouchControls.touch_mode:
		_show_touch_keyboard()
	else:
		password_input.grab_focus()

func _on_password_submit() -> void:
	var level_id := LevelProgression.get_level_id_from_password(password_input.text)
	if level_id.is_empty():
		password_error.visible = true
		return
	password_requested.emit(level_id)

func _on_password_back() -> void:
	password_panel.visible = false
	menu_panel.visible = true
	new_game_button.grab_focus()

## Punto 1: en celular/tablet, teclado propio en pantalla para la contraseña
## (el teclado nativo del navegador no aparece de forma confiable sobre el
## juego, sobre todo en iPhone). El LineEdit queda de solo-mostrar.
const KEYBOARD_ROWS := ["1234567890", "QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM<"]

var _touch_keyboard: VBoxContainer

func _show_touch_keyboard() -> void:
	password_input.virtual_keyboard_enabled = false
	password_input.editable = false
	if _touch_keyboard != null:
		return
	# El bloque del titulo/campo/botones sube para dejar lugar abajo.
	var center: Control = $PasswordPanel/Center
	center.offset_top -= 250.0
	center.offset_bottom -= 250.0
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.05, 0.1, 0.85)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	password_panel.add_child(shade)
	password_panel.move_child(shade, 0)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_touch_keyboard = VBoxContainer.new()
	_touch_keyboard.name = "TouchKeyboard"
	_touch_keyboard.add_theme_constant_override("separation", 10)
	password_panel.add_child(_touch_keyboard)
	_touch_keyboard.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	for row in KEYBOARD_ROWS:
		var line := HBoxContainer.new()
		line.alignment = BoxContainer.ALIGNMENT_CENTER
		line.add_theme_constant_override("separation", 10)
		_touch_keyboard.add_child(line)
		for key in row:
			var b := Button.new()
			b.text = "BORRAR" if key == "<" else key
			b.custom_minimum_size = Vector2(200 if key == "<" else 96, 92)
			b.focus_mode = Control.FOCUS_NONE
			b.add_theme_font_size_override("font_size", 38)
			b.pressed.connect(_on_touch_key.bind(key))
			line.add_child(b)
	_touch_keyboard.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_touch_keyboard.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_touch_keyboard.offset_bottom = -30.0

func _on_touch_key(key: String) -> void:
	password_error.visible = false
	if key == "<":
		password_input.text = password_input.text.substr(0, maxi(0, password_input.text.length() - 1))
	elif password_input.text.length() < password_input.max_length:
		password_input.text += key

## Punto 1: en celular los botones del menu se agrandan (dedos de niño). Se
## escala todo el bloque desde su borde inferior, que es donde esta anclado.
func _enlarge_for_touch() -> void:
	for node in [$MenuPanel/Center, $MenuPanel/ButtonBackdrop, $DifficultyPanel/Center, $DifficultyPanel/Backdrop]:
		var c := node as Control
		c.pivot_offset = Vector2(c.size.x * 0.5, c.size.y if c.get_parent() == menu_panel else c.size.y * 0.5)
		c.scale = Vector2(1.22, 1.22)

## Punto 2: boton de pantalla completa (arriba a la derecha). En el navegador
## solo aparece si la pagina puede pasar a pantalla completa: en iPhone
## Safari no existe esa funcion, asi que ahi directamente no se muestra.
var fullscreen_button: Button

func _fullscreen_available() -> bool:
	if not OS.has_feature("web"):
		return true
	var ok: Variant = JavaScriptBridge.eval(
			"!!(document.fullscreenEnabled || document.webkitFullscreenEnabled)", true)
	return ok == true

func _is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN 			or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

func _setup_fullscreen_button() -> void:
	if not _fullscreen_available():
		return
	fullscreen_button = Button.new()
	fullscreen_button.name = "FullscreenButton"
	for state in ["normal", "hover", "pressed", "focus"]:
		fullscreen_button.add_theme_stylebox_override(state, new_game_button.get_theme_stylebox(state))
	fullscreen_button.add_theme_font_size_override("font_size", 26)
	fullscreen_button.add_theme_color_override("font_outline_color", Color.BLACK)
	fullscreen_button.add_theme_constant_override("outline_size", 5)
	menu_panel.add_child(fullscreen_button)
	fullscreen_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	fullscreen_button.offset_left = -470.0
	fullscreen_button.offset_right = -30.0
	fullscreen_button.offset_top = 30.0
	fullscreen_button.offset_bottom = 100.0
	fullscreen_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_update_fullscreen_text()
	fullscreen_button.pressed.connect(_on_fullscreen_pressed)

func _update_fullscreen_text() -> void:
	fullscreen_button.text = "SALIR DE PANTALLA COMPLETA" if _is_fullscreen() else "PANTALLA COMPLETA"

func _on_fullscreen_pressed() -> void:
	if _is_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		if OS.has_feature("web"):
			# En Android, ya en pantalla completa, se puede trabar en
			# horizontal. Si el navegador no lo permite no pasa nada.
			JavaScriptBridge.eval("try { screen.orientation.lock('landscape').catch(function(){}); } catch (e) {}", true)
	_update_fullscreen_text.call_deferred()

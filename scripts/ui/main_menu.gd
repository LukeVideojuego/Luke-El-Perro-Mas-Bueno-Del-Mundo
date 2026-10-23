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

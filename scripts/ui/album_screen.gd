extends CanvasLayer

## A7: "ÁLBUM DE LUKE", accesible desde el menú principal. Muestra cuántas
## de las 3 huellas doradas de cada uno de los 12 niveles regulares ya se
## encontraron, el total general, y si el collar dorado (premio por juntar
## las 36) ya está desbloqueado.

signal closed

const LEVEL_LABEL := {
	"world_1_level_1": "Mundo 1 · Nivel 1", "world_1_level_2": "Mundo 1 · Nivel 2", "world_1_level_3": "Mundo 1 · Nivel 3",
	"world_2_level_1": "Mundo 2 · Nivel 1", "world_2_level_2": "Mundo 2 · Nivel 2", "world_2_level_3": "Mundo 2 · Nivel 3",
	"world_3_level_1": "Mundo 3 · Nivel 1", "world_3_level_2": "Mundo 3 · Nivel 2", "world_3_level_3": "Mundo 3 · Nivel 3",
	"world_4_level_1": "Mundo 4 · Nivel 1", "world_4_level_2": "Mundo 4 · Nivel 2", "world_4_level_3": "Mundo 4 · Nivel 3",
}

@onready var back_button: Button = $Panel/BackButton
@onready var rows: VBoxContainer = $Panel/Scroll/Rows
@onready var total_label: Label = $Panel/TotalLabel
@onready var collar_label: Label = $Panel/CollarLabel

func _ready() -> void:
	back_button.pressed.connect(func() -> void: closed.emit())
	_build_rows()
	_refresh()

func _build_rows() -> void:
	for level_id in GameState.PAW_LEVELS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 20)

		var name_label := Label.new()
		name_label.custom_minimum_size = Vector2(420, 48)
		name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		name_label.add_theme_constant_override("outline_size", 4)
		name_label.add_theme_font_size_override("font_size", 22)
		name_label.text = String(LEVEL_LABEL.get(level_id, level_id))
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(name_label)

		var count_label := Label.new()
		count_label.name = "Count"
		count_label.custom_minimum_size = Vector2(700, 48)
		count_label.add_theme_color_override("font_color", Color(1, 0.84, 0.3, 1))
		count_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		count_label.add_theme_constant_override("outline_size", 4)
		count_label.add_theme_font_size_override("font_size", 22)
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(count_label)

		row.set_meta("level_id", level_id)
		rows.add_child(row)

func _refresh() -> void:
	for row in rows.get_children():
		var level_id: String = row.get_meta("level_id")
		var found := GameState.paws_found_in_level(level_id)
		var count_label: Label = row.get_node("Count")
		var paws_text := ""
		for i in range(GameState.PAWS_PER_LEVEL):
			paws_text += "🐾" if i < found else "·"
		count_label.text = "%s   %d / %d" % [paws_text, found, GameState.PAWS_PER_LEVEL]

	var total := GameState.total_paws_found()
	var possible := GameState.total_paws_possible()
	total_label.text = "Huellas doradas encontradas: %d / %d" % [total, possible]
	if GameState.golden_collar_unlocked:
		collar_label.text = "¡Collar dorado desbloqueado! Luke ya lo tiene puesto."
	else:
		collar_label.text = "Juntá las %d para desbloquear el collar dorado" % possible

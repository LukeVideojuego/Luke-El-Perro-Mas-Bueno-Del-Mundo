extends CanvasLayer

## Mapa del mundo: muestra los 4 mundos y sus 4 niveles cada uno (3 niveles +
## jefe), bloqueados/desbloqueados según GameState.highest_order_reached, y
## permite elegir a cuál saltar.

signal level_selected(level_id: String)
signal closed

const LEVEL_LABELS := ["1", "2", "3", "JEFE"]

## Color distintivo por mundo (coincide con la paleta de cada fondo ya
## usado en los niveles): Mundo 1 noche cálida, Mundo 2 día celeste,
## Mundo 3 gris institucional, Mundo 4 verde selva.
const WORLD_ACCENT := {
	1: Color(1, 0.7, 0.4, 1),
	2: Color(0.55, 0.8, 1, 1),
	3: Color(0.8, 0.75, 1, 1),
	4: Color(0.6, 1, 0.6, 1),
}

@onready var back_button: Button = $Panel/BackButton
@onready var world_rows: VBoxContainer = $Panel/Scroll/Rows

func _ready() -> void:
	back_button.pressed.connect(func() -> void: closed.emit())
	_build_map()

func _build_map() -> void:
	for world in range(1, 5):
		var row_box := world_rows.get_node("World%dRow" % world) as HBoxContainer
		var title := row_box.get_node("WorldTitle") as Label
		title.text = "MUNDO %d\n%s" % [world, LevelProgression.get_world_name(world)]
		title.add_theme_color_override("font_color", WORLD_ACCENT[world])
		for i in range(4):
			var order := i + 1
			var level_id := LevelProgression.get_level_id_for_global_order((world - 1) * 4 + order)
			var button := row_box.get_node("Level%d" % order) as Button
			var unlocked := GameState.highest_order_reached >= (world - 1) * 4 + order
			var completed := GameState.highest_order_reached > (world - 1) * 4 + order
			button.text = ("★ " if completed else "") + LEVEL_LABELS[i]
			button.disabled = not unlocked
			if unlocked:
				button.modulate = Color(1, 1, 1, 1).lerp(WORLD_ACCENT[world], 0.3)
			else:
				button.modulate = Color(0.5, 0.5, 0.55, 0.6)
			if unlocked and not button.pressed.is_connected(_on_level_pressed):
				button.pressed.connect(_on_level_pressed.bind(level_id))

func _on_level_pressed(level_id: String) -> void:
	level_selected.emit(level_id)

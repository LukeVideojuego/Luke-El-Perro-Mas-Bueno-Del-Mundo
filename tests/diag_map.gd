extends Node

const MAIN_SCENE := preload("res://scenes/main.tscn")
var main: Node
var frame := 0

func _ready() -> void:
	main = MAIN_SCENE.instantiate()
	add_child(main)

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 5:
		print("has_seen_intro=", GameState.has_seen_intro, " highest_order=", GameState.highest_order_reached)
		GameState.highest_order_reached = 5
		var menu = main.get_node("MainMenu")
		menu.map_requested.emit()
	if frame == 10:
		var map = main.get_node("WorldMap")
		print("map built, world_map != null: ", map != null)
		var row1 = map.get_node("Panel/Scroll/Rows/World1Row")
		var lvl2_btn: Button = row1.get_node("Level2")
		print("Level2 (world_1_level_2) disabled=", lvl2_btn.disabled, " text=", lvl2_btn.text)
		var row2 = map.get_node("Panel/Scroll/Rows/World2Row")
		var w2_lvl1: Button = row2.get_node("Level1")
		var w2_lvl2: Button = row2.get_node("Level2")
		print("World2 Level1 disabled=", w2_lvl1.disabled, " World2 Level2 disabled=", w2_lvl2.disabled)
		w2_lvl1.pressed.emit()
	if frame == 20:
		print("current_level_id after selection=", GameState.current_level_id)
		print("active_level name=", main.active_level.name if main.active_level else "null")
		get_tree().quit()

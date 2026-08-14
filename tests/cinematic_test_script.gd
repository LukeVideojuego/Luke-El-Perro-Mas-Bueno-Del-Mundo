extends Node2D

func _ready() -> void:
	var main_scene = load("res://scenes/main.tscn")
	print("Loading main scene: ", main_scene != null)
	if main_scene:
		var main_inst = main_scene.instantiate()
		add_child(main_inst)
	
	var intro_scene = load("res://scenes/cinematics/intro_cinematic.tscn")
	print("Loading intro cinematic: ", intro_scene != null)
	if intro_scene:
		var intro_inst = intro_scene.instantiate()
		add_child(intro_inst)
	
	var final_scene = load("res://scenes/cinematics/final_cinematic.tscn")
	print("Loading final cinematic: ", final_scene != null)
	if final_scene:
		var final_inst = final_scene.instantiate()
		add_child(final_inst)
	
	get_tree().quit()
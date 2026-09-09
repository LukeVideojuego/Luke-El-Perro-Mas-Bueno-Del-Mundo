class_name Bird
extends EnemyBase

## Ave que vuela de un lado a otro de la pantalla y suelta UNA sola caca por
## pasada (al llegar a cada extremo de su recorrido y dar la vuelta), en vez
## de atacar a distancia por proximidad como el resto de los enemigos con
## ranged attack.

const POOP_SCENE := preload("res://scenes/objects/bird_poop.tscn")

var _last_direction := 0.0
var _direction_initialized := false

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_defeated:
		return
	if not _direction_initialized:
		_last_direction = patrol_direction
		_direction_initialized = true
		return
	if patrol_direction != _last_direction:
		_drop_poop()
		_last_direction = patrol_direction

func _drop_poop() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var poop := POOP_SCENE.instantiate()
	parent.add_child(poop)
	poop.launch(global_position, self)

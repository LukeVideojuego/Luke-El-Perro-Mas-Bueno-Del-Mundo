class_name FishHookSpawner
extends Node2D

## Punto fijo en la parte superior de la pantalla que suelta un anzuelo
## (fishhook.tscn) cada spawn_interval segundos. Reemplaza a las aves en el
## nivel del mar (Mundo 4): mismo rol de "peligro que cae del cielo" pero
## con un enemigo que tiene sentido bajo el agua.

const FISHHOOK_SCENE := preload("res://scenes/objects/fishhook.tscn")

@export var spawn_interval := 4.0
@export var initial_delay := 1.0

var _timer := 0.0

func _ready() -> void:
	_timer = spawn_interval - initial_delay

func _physics_process(delta: float) -> void:
	_timer += delta
	if _timer >= spawn_interval:
		_timer = 0.0
		_spawn_hook()

func _spawn_hook() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var hook: Node = FISHHOOK_SCENE.instantiate()
	parent.add_child(hook)
	hook.global_position = global_position

class_name DigSpot
extends Area2D

## B1: mancha de tierra con un hueso asomando, escondida en el piso del
## Nivel 2 de cada mundo. Si Luke esta parado justo encima y ataca (golpe
## cuerpo a cuerpo O a distancia, cualquiera de los dos cuenta como "ataca"),
## cava un poco; al tercer golpe entra al bonus de ese mundo.
##
## "Usado" se guarda con la partida (GameState.is_dig_spot_used) y NO se
## reactiva solo con la muerte/respawn normal -- unicamente CONTINUAR desde
## la pantalla de Game Over lo reactiva (GameState.use_continue() lo hace
## para el nivel donde se murio, ver game_state.gd).

signal bonus_triggered(bonus_scene_path: String, return_position: Vector2)

@export var level_id := ""
@export var bonus_scene_path := ""
@export var hits_required := 3

@onready var mound_sprite: Sprite2D = $Mound
@onready var hole_sprite: Sprite2D = $HoleUsed

var _hits := 0
var _luke_nearby: Luke = null

func _ready() -> void:
	hole_sprite.visible = false
	if GameState.is_dig_spot_used(level_id):
		_show_used()

func _show_used() -> void:
	mound_sprite.visible = false
	hole_sprite.visible = true
	monitoring = false

func _on_body_entered(body: Node2D) -> void:
	if body is Luke and not hole_sprite.visible:
		_luke_nearby = body
		if not body.attack_started.is_connected(_on_luke_attack):
			body.attack_started.connect(_on_luke_attack)

func _on_body_exited(body: Node2D) -> void:
	if body == _luke_nearby:
		if body.attack_started.is_connected(_on_luke_attack):
			body.attack_started.disconnect(_on_luke_attack)
		_luke_nearby = null

func _on_luke_attack() -> void:
	if _luke_nearby == null or not _luke_nearby.is_on_floor():
		return
	_hits += 1
	_punch_feedback()
	AudioDirector.play_event(&"coin_pickup")
	if _hits >= hits_required:
		# La posicion real de Luke (parado encima), no el origen del propio
		# DigSpot -- son parecidas pero no identicas (Luke se asienta un poco
		# distinto segun donde toco el piso), y "vuelve exacto a donde cavo"
		# tiene que ser literal. Tiene que leerse ANTES de _show_used(): ese
		# apaga "monitoring", lo que dispara body_exited solo y deja
		# _luke_nearby en null antes de poder leerlo.
		var luke := _luke_nearby
		var pos := luke.global_position
		GameState.set_dig_spot_used(level_id, true)
		_show_used()
		if luke.attack_started.is_connected(_on_luke_attack):
			luke.attack_started.disconnect(_on_luke_attack)
		_luke_nearby = null
		bonus_triggered.emit(bonus_scene_path, pos)

## Progreso visual simple: el monticulo se achica y se oscurece con cada
## golpe, asi se nota que se esta cavando antes de entrar al bonus.
func _punch_feedback() -> void:
	var t: float = float(_hits) / float(hits_required)
	mound_sprite.scale = Vector2(1.0, 1.0 - 0.3 * t)
	mound_sprite.modulate = Color(1.0 - 0.3 * t, 1.0 - 0.3 * t, 1.0 - 0.3 * t, 1.0)

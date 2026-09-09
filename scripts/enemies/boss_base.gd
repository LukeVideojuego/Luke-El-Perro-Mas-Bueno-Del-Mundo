class_name BossBase
extends EnemyBase

## Jefe reutilizable: se mueve y carga contra Luke, recibe varios golpes y
## muestra una barra de vida. Al ser derrotado completa el nivel.

signal boss_defeated

@export var hp_bar_width := 120.0
@export var hp_bar_height := 10.0
@export var hp_bar_y_offset := -92.0

## Para jefes sin piernas visibles (la Bruja, cuya pollera/capa las tapa; la
## Serpiente, que no tiene piernas): en vez de alternar 2 poses de caminata
## como el resto de los personajes, balancea la tela/cuerpo con una leve
## rotación oscilante mientras se mueve, simulando el movimiento sin
## necesitar sprites de piernas que no existen.
@export var sway_enabled := false
@export var sway_amplitude_deg := 5.0
@export var sway_speed := 5.0

func _init() -> void:
	drops_bone_on_defeat = true

var _hp_back: ColorRect
var _hp_front: ColorRect

func _ready() -> void:
	super()
	health = max_health
	_build_hp_bar()

func _physics_process(delta: float) -> void:
	if is_defeated:
		return
	super(delta)
	_hop_time += delta
	if is_on_floor() and _hop_time >= hop_interval:
		_hop_time = 0.0
		velocity.y = hop_strength
	if sway_enabled and sprite != null:
		var sway_strength: float = clampf(absf(velocity.x) / maxf(patrol_speed, 1.0), 0.35, 1.0)
		sprite.rotation = sin(_time * sway_speed) * deg_to_rad(sway_amplitude_deg) * sway_strength

func receive_attack(_attacker: Node) -> void:
	if is_defeated:
		return
	health -= 1
	_update_hp_bar()
	AudioDirector.play_event(&"boss_hit")
	if health <= 0:
		is_defeated = true
		$CollisionShape2D.set_deferred("disabled", true)
		$DamageArea.set_deferred("monitoring", false)
		_drop_bone()
		boss_defeated.emit(self)
		GameState.complete_current_level()
		queue_free()
	else:
		modulate = Color(1.0, 0.55, 0.55, 1.0)
		await get_tree().create_timer(0.12).timeout
		if is_instance_valid(self):
			modulate = Color.WHITE

func _build_hp_bar() -> void:
	_hp_back = ColorRect.new()
	_hp_back.color = Color(0.08, 0.08, 0.12, 0.9)
	_hp_back.size = Vector2(hp_bar_width, hp_bar_height)
	_hp_back.position = Vector2(-hp_bar_width / 2.0, hp_bar_y_offset)
	_hp_back.z_index = 5
	add_child(_hp_back)
	_hp_front = ColorRect.new()
	_hp_front.color = Color(0.95, 0.25, 0.2, 1.0)
	_hp_front.size = Vector2(hp_bar_width, hp_bar_height)
	_hp_front.position = _hp_back.position
	_hp_front.z_index = 6
	add_child(_hp_front)

func _update_hp_bar() -> void:
	if _hp_front == null:
		return
	_hp_front.size.x = maxf(hp_bar_width * (float(health) / float(max_health)), 0.0)

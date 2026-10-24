class_name ShieldedEnemy
extends EnemyBase

## B4: guardaespaldas con escudo (Mundo 3). Bloquea cualquier golpe que
## llegue desde el lado hacia el que esta mirando (el escudo); solo se lo
## puede derrotar golpeandolo por detras, o saltandole encima (TopHurtbox,
## que ignora el escudo por completo, como una pisada).

@onready var shield: Sprite2D = $Shield
@onready var top_hurtbox: Area2D = $TopHurtbox

const SHIELD_OFFSET_X := 26.0
var _block_flash_active := false

func _physics_process(delta: float) -> void:
	super(delta)
	if shield != null:
		var facing_dir: float = 1.0 if sprite.flip_h else -1.0
		shield.position.x = SHIELD_OFFSET_X * facing_dir

## Golpe normal (ataque cuerpo a cuerpo, huesito, ladrido): bloqueado si
## llega del lado del escudo (el lado hacia el que esta mirando). Desde
## atras, pasa igual que en cualquier otro enemigo (EnemyBase.receive_attack).
func receive_attack(attacker: Node, amount: int = 1) -> void:
	if is_defeated:
		return
	if attacker is Node2D:
		var facing_dir: float = 1.0 if sprite.flip_h else -1.0
		var attacker_side: float = signf((attacker as Node2D).global_position.x - global_position.x)
		if is_zero_approx(attacker_side):
			attacker_side = facing_dir
		if attacker_side == facing_dir:
			_block_flash()
			return
	super.receive_attack(attacker, amount)

## El escudo "absorbe" el golpe: destello + empujoncito visual, sin daño.
func _block_flash() -> void:
	if shield == null or _block_flash_active:
		return
	_block_flash_active = true
	AudioDirector.play_event(&"boss_hit")
	var base_scale: Vector2 = shield.scale
	var tween := create_tween()
	tween.tween_property(shield, "scale", base_scale * 1.2, 0.06)
	tween.tween_property(shield, "scale", base_scale, 0.12)
	tween.tween_callback(func(): _block_flash_active = false)

## Saltarle encima ignora el escudo por completo (es una "pisada" desde
## arriba, no un golpe de frente). Apaga el DamageArea un instante despues
## para que la misma pisada no le haga daño a Luke en el mismo momento en
## que estaba aterrizando sobre la cabeza del guardia.
func _on_top_hurtbox_body_entered(body: Node2D) -> void:
	if is_defeated or not (body is Luke):
		return
	if body.velocity.y <= 40.0:
		return
	var damage_area: Area2D = $DamageArea
	damage_area.set_deferred("monitoring", false)
	super.receive_attack(body, 1)
	if not is_instance_valid(self):
		return
	body.velocity.y = -420.0
	if not is_defeated:
		await get_tree().create_timer(0.3).timeout
		if is_instance_valid(self) and not is_defeated:
			damage_area.monitoring = true

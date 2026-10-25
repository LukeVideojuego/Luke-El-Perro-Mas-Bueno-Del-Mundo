class_name VeterinarioMalvado
extends EnemyBase

## B3: nuevo villano, Mundo 2 a Mundo 4. Ataque a distancia (jeringa, ya
## soportado por EnemyBase) con una pose de lanzamiento propia: se asoma
## por encima del ciclo de caminata normal (EnemyBase) un instante
## despues de cada tiro, en vez de quedarse en la pose de caminar.

@export var throw_texture: Texture2D
@export var throw_pose_time := 0.3
var _throw_pose_left := 0.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_defeated:
		return
	if _throw_pose_left > 0.0:
		_throw_pose_left -= delta
		if sprite != null:
			sprite.texture = throw_texture

func _fire_projectile(target: Luke) -> void:
	super._fire_projectile(target)
	_throw_pose_left = throw_pose_time

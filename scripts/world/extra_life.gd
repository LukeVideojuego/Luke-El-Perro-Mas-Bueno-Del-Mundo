class_name ExtraLife
extends CharacterBody2D

## C2: vida extra escondida en algunas cajas rompibles.
##
## Se comporta como el hongo de Super Mario Bros: primero asoma saliendo de
## la caja, despues camina solo a velocidad constante, rebota contra
## cualquier obstaculo y se cae por los bordes de las plataformas. Su diseno
## es la carita de Luke en chiquito (assets/items/extra_life_*.png).
##
## No colisiona con Luke (se le agrega excepcion al entrar al arbol): tiene
## que poder pasarle por encima para que lo agarre, no empujarlo.

@export var speed := 115.0
@export var gravity := 1800.0
@export var max_fall_speed := 900.0
@export var direction := 1.0
## Mientras asoma de la caja sube despacio y todavia no camina.
@export var emerge_time := 0.4
@export var emerge_speed := -160.0
## Si se cae del nivel, se borra solo en vez de caer para siempre.
@export var despawn_fall := 1400.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _emerge_left := 0.0
var _start_y := 0.0
var _collected := false

func _ready() -> void:
	_emerge_left = emerge_time
	_start_y = global_position.y
	add_to_group("extra_life")
	var level := get_parent()
	if level != null:
		var luke := level.get_node_or_null("Luke")
		if luke is PhysicsBody2D:
			add_collision_exception_with(luke)
	$PickupArea.body_entered.connect(_on_pickup_body_entered)

func _physics_process(delta: float) -> void:
	if _collected:
		return
	if _emerge_left > 0.0:
		_emerge_left -= delta
		velocity = Vector2(0.0, emerge_speed)
		move_and_slide()
		return
	velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
	velocity.x = speed * direction
	move_and_slide()
	if is_on_wall():
		direction = -direction
	sprite.flip_h = direction < 0.0
	if global_position.y > _start_y + despawn_fall:
		queue_free()

func _on_pickup_body_entered(body: Node2D) -> void:
	if _collected or not (body is Luke):
		return
	_collected = true
	GameState.add_life()
	AudioDirector.play_event(&"powerup_invincibility")
	queue_free()

class_name CapeSprite
extends Node2D

## B2: la capa vuelve a ser 2 sprites fijos (reposo/salto, recortados de
## referencia_visual/luke_capa.png) en vez de la simulacion de tela con
## Verlet de la version anterior (pedido explicito: usar esas 2
## referencias puntuales, no fisica). "Reposo" cubre quieto Y caminando
## (misma pose); "salto" cubre subir Y caer (tambien la misma pose, un
## salto desplegado) -- son solo 2 estados, elegidos afuera con
## set_deployed() segun si Luke esta en el piso o no.
##
## La transicion entre las 2 no es un corte seco: ambos sprites existen
## siempre superpuestos y se hace un fade cruzado de opacidad entre ellos
## con un Tween, asi se ve una se difumina mientras la otra aparece en
## vez de un "pop" instantaneo.

const REST_TEXTURE := preload("res://assets/items/Shop/cape_rest.png")
const JUMP_TEXTURE := preload("res://assets/items/Shop/cape_jump.png")
const FADE_TIME := 0.12

@onready var rest_sprite: Sprite2D = $Rest
@onready var jump_sprite: Sprite2D = $Jump

var _deployed := false
var _fade_tween: Tween = null

func _ready() -> void:
	rest_sprite.texture = REST_TEXTURE
	jump_sprite.texture = JUMP_TEXTURE
	rest_sprite.modulate.a = 1.0
	jump_sprite.modulate.a = 0.0

## true = pose de salto (desplegada), false = pose de reposo (apoyada).
func set_deployed(deployed: bool) -> void:
	if deployed == _deployed:
		return
	_deployed = deployed
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	var shown: Sprite2D = jump_sprite if deployed else rest_sprite
	var hidden: Sprite2D = rest_sprite if deployed else jump_sprite
	_fade_tween = create_tween().set_parallel(true)
	_fade_tween.tween_property(shown, "modulate:a", 1.0, FADE_TIME)
	_fade_tween.tween_property(hidden, "modulate:a", 0.0, FADE_TIME)

func set_tint(c: Color) -> void:
	var a_rest: float = rest_sprite.modulate.a
	var a_jump: float = jump_sprite.modulate.a
	rest_sprite.modulate = c
	rest_sprite.modulate.a = a_rest
	jump_sprite.modulate = c
	jump_sprite.modulate.a = a_jump

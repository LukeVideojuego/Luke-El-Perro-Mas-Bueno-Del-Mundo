class_name BonusReward
extends Area2D

## B1: premio de los niveles bonus. 3 tipos:
##  - LIFE: +1 vida (las 2 "faciles" van en las primeras barras).
##  - COINS: monedas (las del tramo medio).
##  - SHOP_ITEM: un cosmetico de la tienda, queda "comprado" directo en
##    owned_items (las barras mas dificiles, al final). Si Luke ya lo tenia
##    (por ejemplo, el mismo cosmetico premiado en el bonus de otro mundo),
##    en vez de desaparecer sin dar nada se convierte en un extra de
##    monedas, para que esa barra tan dificil de alcanzar nunca quede vacia.
const FALLBACK_COINS := 15

enum RewardType { LIFE, COINS, SHOP_ITEM }

@export var reward_type: RewardType = RewardType.COINS
@export var coin_amount := 1
@export var item_id := ""

@onready var icon: Sprite2D = $Icon

const LIFE_ICON := preload("res://assets/ui/icon_corazon.png")
const COIN_ICON := preload("res://assets/ui/icon_moneda.png")

var _already_owned := false

func _ready() -> void:
	match reward_type:
		RewardType.LIFE:
			icon.texture = LIFE_ICON
		RewardType.COINS:
			icon.texture = COIN_ICON
		RewardType.SHOP_ITEM:
			_already_owned = GameState.owned_items.has(item_id)
			if _already_owned:
				icon.texture = COIN_ICON
			elif not item_id.is_empty():
				var item := ShopCatalog.get_item(item_id)
				if not item.is_empty():
					icon.texture = load(String(item.icon))

func _on_body_entered(body: Node2D) -> void:
	if not body is Luke:
		return
	match reward_type:
		RewardType.LIFE:
			GameState.add_life(1)
		RewardType.COINS:
			GameState.add_coins(coin_amount)
		RewardType.SHOP_ITEM:
			if _already_owned:
				GameState.add_coins(FALLBACK_COINS)
			else:
				GameState.owned_items.append(item_id)
				SaveManager.save_game()
	AudioDirector.play_event(&"coin_pickup")
	queue_free()

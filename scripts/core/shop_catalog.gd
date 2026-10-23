class_name ShopCatalog
extends RefCounted

## C3: catalogo de la tienda que aparece antes de cada nivel a partir del
## nivel 2.
##
## Balance de precios: cada nivel tiene 8 grupos de 3 monedas = 24 monedas si
## se juntan todas, y hay 15 visitas a la tienda (del nivel 2 al 16). O sea
## que un jugador prolijo maneja unas 24 monedas por visita y poco mas de
## 350 en toda la partida. Con eso:
##  - los consumibles baratos (15 a 20) se pueden comprar casi siempre,
##  - los sombreros (20 a 70) son metas de 1 a 3 niveles de ahorro,
##  - el traje con capa (90) es la compra grande del juego,
##  - la municion de ladridos (25 por 5 tiros) esta pensada para que
##    convenga recomprarla seguido.

enum Kind {
	HAT,        ## cosmetico permanente, se equipa en la cabeza
	SUIT,       ## cosmetico permanente, traje + capa
	SOCKS,      ## cosmetico permanente, se equipa en las 4 patas
	CONSUMABLE, ## se gasta al empezar el proximo nivel
	AMMO,       ## suma municion del ataque especial
}

const ITEMS := [
	{
		"id": "hat_beanie", "icon": "res://assets/items/Shop/hat_beanie.png", "kind": Kind.HAT, "price": 20,
		"name": "Gorro de lana",
		"desc": "El clasico gorrito del barrio. Abriga y queda bien.",
	},
	{
		"id": "hat_explorer", "icon": "res://assets/items/Shop/hat_explorer.png", "kind": Kind.HAT, "price": 35,
		"name": "Sombrero de explorador",
		"desc": "Para cruzar selvas, mares y templos sin despeinarse.",
	},
	{
		"id": "hat_tophat", "icon": "res://assets/items/Shop/hat_tophat.png", "kind": Kind.HAT, "price": 50,
		"name": "Galera elegante",
		"desc": "Luke de etiqueta. Ideal para enfrentar politicos.",
	},
	{
		"id": "hat_crown", "icon": "res://assets/items/Shop/hat_crown.png", "kind": Kind.HAT, "price": 70,
		"name": "Corona dorada",
		"desc": "Porque el perro mas bueno del mundo es de la realeza.",
	},
	{
		"id": "suit_cape", "icon": "res://assets/items/Shop/cape_open.png", "kind": Kind.SUIT, "price": 90,
		"name": "Traje rojo con capa",
		"desc": "Cosmetico. La capa se despliega sola cada vez que saltas.",
	},
	{
		"id": "socks_yellow_black", "icon": "res://assets/items/Shop/socks_yellow_black.png", "kind": Kind.SOCKS, "price": 45,
		"name": "Medias aurinegras",
		"desc": "Cosmetico. Medias a rayas amarillas y negras en las 4 patas.",
	},
	{
		"id": "star", "icon": "res://assets/Tiles/Default/star.png", "kind": Kind.CONSUMABLE, "price": 20,
		"name": "Estrella",
		"desc": "Empezas el proximo nivel invencible durante 12 segundos.",
	},
	{
		"id": "boots", "icon": "res://assets/Tiles/Default/mushroom_red.png", "kind": Kind.CONSUMABLE, "price": 15,
		"name": "Hongo veloz",
		"desc": "Empezas el proximo nivel con el envion de velocidad puesto.",
	},
	{
		"id": "heart", "icon": "res://assets/ui/icon_corazon.png", "kind": Kind.CONSUMABLE, "price": 35,
		"name": "Corazon de repuesto",
		"desc": "Una vida extra, ya cargada al empezar el proximo nivel.",
	},
	{
		"id": "aura", "icon": "res://assets/ui/icon_chaleco.png", "kind": Kind.CONSUMABLE, "price": 25,
		"name": "Aura protectora",
		"desc": "Arrancas el nivel con el aura puesta: aguanta un golpe.",
	},
	{
		"id": "bark", "icon": "res://assets/items/Shop/bark_wave_2.png", "kind": Kind.AMMO, "price": 25, "amount": 5,
		"name": "Ladrido de onda expansiva x5",
		"desc": "Mas rapido que el huesito, atraviesa y pega a todo lo que toca. Doble toque de ataque.",
	},
]

static func get_item(id: String) -> Dictionary:
	for item in ITEMS:
		if item.id == id:
			return item
	return {}

## Los sombreros y el traje se compran una sola vez; despues se equipan y se
## sacan gratis.
static func is_permanent(item: Dictionary) -> bool:
	return item.kind == Kind.HAT or item.kind == Kind.SUIT or item.kind == Kind.SOCKS

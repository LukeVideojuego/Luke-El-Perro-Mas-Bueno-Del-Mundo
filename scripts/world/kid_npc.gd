class_name KidNpc
extends Interactable

## A6: reemplaza al cartel de madera del inicio de cada nivel regular por
## uno de los 7 (ahora 8, con Franca) chicos que ya aparecen en la pantalla
## de cierre del Mundo 1. A diferencia del cartel (Interactable normal, que
## muestra su hint apenas Luke entra en el area), el globo de dialogo del
## chico SOLO aparece si Luke aprieta un boton estando cerca -- y desaparece
## apenas Luke se aleja, para no quedar molestando todo el tiempo que Luke
## este cerca.
##
## interaction_text (heredado de Interactable) sigue siendo donde vive el
## texto real: level_base.gd ya lo pisa con mission_text del nivel (mismo
## mecanismo que el cartel viejo). Cada nivel pone ahi la frase YA
## formateada con el nombre adelante ("Zoe: Hola Luke, ..."), asi que el
## globo la muestra tal cual -- kid_name no se vuelve a anteponer aca (si
## no, quedaba "Zoe: Zoe: Hola Luke...").

@export var kid_name := ""

## Acciones del control del juego: cualquiera de estas cuenta como "aprieta
## cualquier boton".
const WATCHED_ACTIONS := [
	"interact", "attack", "jump", "run", "move_left", "move_right",
]

var _bubble_shown := false

func _ready() -> void:
	super._ready()
	if hint_label != null:
		hint_label.visible = false

## Interactable._on_body_entered() hace visible el hint apenas Luke entra en
## el area (asi se comportaba el cartel de madera viejo) -- eso es
## justamente lo que A6 pide evitar, asi que se pisa para solo guardar quien
## esta cerca, sin mostrar nada todavia.
func _on_body_entered(body: Node2D) -> void:
	if body is Luke:
		nearby_player = body

func _process(_delta: float) -> void:
	if nearby_player == null:
		return
	if not _bubble_shown:
		for action in WATCHED_ACTIONS:
			if Input.is_action_just_pressed(action):
				_show_bubble()
				break

func _show_bubble() -> void:
	if hint_label == null:
		return
	_bubble_shown = true
	hint_label.text = interaction_text
	hint_label.visible = true
	interacted.emit(nearby_player)

func _on_body_exited(body: Node2D) -> void:
	super._on_body_exited(body)
	_bubble_shown = false

extends CanvasLayer

## C3: tienda de monedas. Aparece antes de cada nivel a partir del nivel 2.
##
## Las filas se arman por codigo desde ShopCatalog para que agregar un item
## nuevo sea una sola entrada en el catalogo y no haya que tocar la escena.
## Muestra precio, saldo actual y estado de cada cosa (comprable, sin plata,
## ya comprado, equipado), y siempre se puede saltear con el boton de jugar.

signal closed

@onready var coins_label: Label = $Panel/Header/CoinsLabel
@onready var level_label: Label = $Panel/Header/LevelLabel
@onready var list: VBoxContainer = $Panel/Scroll/List
@onready var skip_button: Button = $Panel/Footer/SkipButton
@onready var save_button: Button = $Panel/Footer/SaveButton
@onready var status_label: Label = $Panel/Footer/StatusLabel

var _rows: Array = []
## F4: nivel al que se va a entrar DESPUES de la tienda (el que recibe
## setup()). GameState.current_level_id todavia apunta al nivel recien
## completado mientras la tienda esta abierta (recien se actualiza cuando
## el nivel siguiente arranca de verdad, en level_base._ready() ->
## begin_level()) -- "GUARDAR PARTIDA" desde aca tiene que guardar ESTE,
## no el viejo, para que "CARGAR PARTIDA" vuelva al punto correcto.
var _next_level_id := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	skip_button.pressed.connect(func() -> void: closed.emit())
	save_button.pressed.connect(_on_save_pressed)
	GameState.shop_changed.connect(_refresh)
	_build_rows()
	_refresh()
	skip_button.grab_focus()

func setup(level_id: String) -> void:
	_next_level_id = level_id
	var world := LevelProgression.get_world(level_id)
	var order := LevelProgression.get_order(level_id)
	var where := "%s · NIVEL %d" % [LevelProgression.get_world_name(world), order]
	if order >= 4:
		where = "%s · %s" % [LevelProgression.get_world_name(world), LevelProgression.get_boss_name(world)]
	level_label.text = "Antes de entrar a %s" % where

## F4: guarda el progreso tal cual esta en la tienda (monedas, vidas,
## continues, compras, sombrero equipado) apuntando al nivel que la tienda
## esta por mostrar, no al que ya se completo.
func _on_save_pressed() -> void:
	GameState.current_level_id = _next_level_id
	GameState.checkpoint_id = "start"
	GameState.checkpoint_position = Vector2.ZERO
	SaveManager.save_game()
	AudioDirector.play_event(&"coin_pickup")
	_set_status("Partida guardada")

func _build_rows() -> void:
	for item in ShopCatalog.ITEMS:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0.0, 92.0)
		row.add_theme_constant_override("separation", 18)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(86.0, 86.0)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.texture = load(String(item.icon))
		row.add_child(icon)

		var texts := VBoxContainer.new()
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texts.add_theme_constant_override("separation", 2)
		var name_label := Label.new()
		name_label.text = String(item.name)
		name_label.add_theme_font_size_override("font_size", 26)
		name_label.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
		texts.add_child(name_label)
		var desc_label := Label.new()
		desc_label.text = String(item.desc)
		desc_label.add_theme_font_size_override("font_size", 18)
		desc_label.add_theme_color_override("font_color", Color(0.78, 0.82, 0.92))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texts.add_child(desc_label)
		row.add_child(texts)

		var price_label := Label.new()
		price_label.custom_minimum_size = Vector2(150.0, 0.0)
		price_label.add_theme_font_size_override("font_size", 26)
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(price_label)

		var button := Button.new()
		button.custom_minimum_size = Vector2(190.0, 62.0)
		button.add_theme_font_size_override("font_size", 22)
		button.pressed.connect(_on_item_pressed.bind(String(item.id)))
		row.add_child(button)

		list.add_child(row)
		var separator := HSeparator.new()
		list.add_child(separator)
		_rows.append({"item": item, "button": button, "price": price_label, "icon": icon})

func _on_item_pressed(item_id: String) -> void:
	var item := ShopCatalog.get_item(item_id)
	if ShopCatalog.is_permanent(item) and GameState.owned_items.has(item_id):
		GameState.toggle_equipped(item_id)
		_set_status("%s %s" % [item.name, "equipado" if _is_equipped(item) else "guardado"])
		return
	if GameState.buy_item(item_id):
		AudioDirector.play_event(&"coin_pickup")
		_set_status("¡Compraste %s!" % item.name)
	else:
		AudioDirector.play_event(&"aura_lost")
		_set_status("Te faltan monedas para %s (cuesta %d, tenés %d)" % [item.name, item.price, GameState.coins])

func _is_equipped(item: Dictionary) -> bool:
	if item.kind == ShopCatalog.Kind.HAT:
		return GameState.equipped_hat == item.id
	if item.kind == ShopCatalog.Kind.SUIT:
		return GameState.suit_equipped
	if item.kind == ShopCatalog.Kind.SOCKS:
		return GameState.socks_equipped
	return false

func _refresh() -> void:
	coins_label.text = "MONEDAS: %d" % GameState.coins
	for row in _rows:
		var item: Dictionary = row.item
		var button: Button = row.button
		var price_label: Label = row.price
		var owned: bool = GameState.owned_items.has(String(item.id))
		price_label.text = "%d 🪙" % int(item.price)
		price_label.add_theme_color_override("font_color",
			Color(0.6, 1, 0.65) if GameState.coins >= int(item.price) else Color(1, 0.55, 0.55))
		if ShopCatalog.is_permanent(item) and owned:
			price_label.text = "comprado"
			price_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
			button.disabled = false
			button.text = "SACAR" if _is_equipped(item) else "PONER"
		else:
			button.disabled = GameState.coins < int(item.price)
			button.text = "COMPRAR"
		if item.kind == ShopCatalog.Kind.AMMO:
			button.text = "COMPRAR (tenés %d)" % GameState.bark_ammo
		elif item.kind == ShopCatalog.Kind.CONSUMABLE:
			var pending := _pending_count(String(item.id))
			if pending > 0:
				button.text = "COMPRAR (listo x%d)" % pending

func _pending_count(item_id: String) -> int:
	match item_id:
		"star": return 1 if GameState.pending_star else 0
		"boots": return 1 if GameState.pending_boots else 0
		"aura": return 1 if GameState.pending_aura else 0
		"heart": return GameState.pending_hearts
	return 0

func _set_status(text: String) -> void:
	status_label.text = text
	_refresh()

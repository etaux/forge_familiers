class_name MarketPage
extends MarginContainer

signal buy_pressed(listing_id: String)
signal cancel_pressed(listing_id: String)

var kit: UIKit
var title_label: Label
var help_label: Label
var coins_chip: PanelContainer
var coins_label: Label
var count_label: Label
var status_label: Label
var connect_button: Button
var refresh_button: Button
var list: VBoxContainer
var _busy: bool = false

func setup(ui: UIKit) -> void:
	kit = ui
	kit.set_margins(self, 14, 14, 14, 12)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	add_child(content)
	var heading := HBoxContainer.new()
	content.add_child(heading)
	var title_group := VBoxContainer.new()
	title_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title_group)
	title_label = kit.label(Loc.t("market_title"), 23, UIKit.COLOR_TEXT)
	title_group.add_child(title_label)
	count_label = kit.label(Loc.t("offers_one") % 0, 11, UIKit.COLOR_MUTED)
	title_group.add_child(count_label)
	coins_chip = kit.stat_chip(Loc.t("tokens"), Color("ffd266"))
	coins_label = coins_chip.get_meta("value_label")
	heading.add_child(coins_chip)

	help_label = kit.label(Loc.t("market_help"), 11, UIKit.COLOR_MUTED)
	help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(help_label)

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 8)
	content.add_child(toolbar)
	status_label = kit.label(Loc.t("market_offline"), 10, UIKit.COLOR_MUTED)
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toolbar.add_child(status_label)
	refresh_button = Button.new()
	refresh_button.text = Loc.t("market_refresh")
	refresh_button.custom_minimum_size = Vector2(108, 44)
	refresh_button.add_theme_font_size_override("font_size", 10)
	kit.style_action_button(refresh_button, UIKit.COLOR_CYAN, false)
	refresh_button.pressed.connect(_on_refresh_pressed)
	toolbar.add_child(refresh_button)
	connect_button = Button.new()
	connect_button.text = Loc.t("market_connect")
	connect_button.custom_minimum_size = Vector2(118, 44)
	connect_button.add_theme_font_size_override("font_size", 10)
	kit.style_action_button(connect_button, Color("ffd266"), true)
	connect_button.pressed.connect(_on_connect_pressed)
	toolbar.add_child(connect_button)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	rebuild()

func apply_locale() -> void:
	if title_label:
		title_label.text = Loc.t("market_title")
	if help_label:
		help_label.text = Loc.t("market_online_hint") if GameState.is_market_online() else Loc.t("market_help")
	if coins_chip:
		var chip_title: Label = coins_chip.get_child(0).get_child(0)
		chip_title.text = Loc.t("tokens")
	if refresh_button:
		refresh_button.text = Loc.t("market_refresh")
	rebuild()

func rebuild() -> void:
	if list == null:
		return
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	if coins_label:
		coins_label.text = CardDatabase.format_number(GameState.market_coins)
	var listings: Array = GameState.get_market_listings()
	if count_label:
		var listing_count := listings.size()
		count_label.text = (Loc.t("offers_many") if listing_count > 1 else Loc.t("offers_one")) % listing_count
	_refresh_status()
	if listings.is_empty():
		var empty := kit.label(Loc.t("market_empty"), 13, UIKit.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		empty.custom_minimum_size.y = 120
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(empty)
		return
	for listing in listings:
		var card := CardDatabase.get_card(str(listing.card_id))
		if card.is_empty():
			continue
		var rarity_data: Dictionary = CardDatabase.RARITIES[card.rarity]
		var panel := PanelContainer.new()
		panel.custom_minimum_size.y = 105
		panel.add_theme_stylebox_override("panel", kit.box(Color(0.052, 0.062, 0.13, 0.97), 17, Color(rarity_data.color, 0.34), 1, 8))
		list.add_child(panel)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 9)
		panel.add_child(row)
		row.add_child(kit.mini_art(card.art, rarity_data.color))
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(details)
		var name_label := kit.label("%s  ×%s" % [card.name, CardDatabase.format_number(int(listing.quantity))], 13, rarity_data.glow)
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		details.add_child(name_label)
		var seller_name := Loc.t("market_you") if bool(listing.get("is_player", false)) else str(listing.seller)
		details.add_child(kit.label(Loc.t("seller") % seller_name, 10, UIKit.COLOR_MUTED))
		var total := int(listing.quantity) * int(listing.unit_price)
		details.add_child(kit.label(Loc.t("tokens_total") % CardDatabase.format_number(total), 11, Color("ffd266")))
		var action := Button.new()
		action.custom_minimum_size = Vector2(105, 54)
		action.add_theme_font_size_override("font_size", 10)
		if bool(listing.get("is_player", false)):
			action.text = Loc.t("cancel_offer")
			kit.style_action_button(action, Color("ff8b9d"), false)
			action.pressed.connect(func() -> void: cancel_pressed.emit(str(listing.id)))
		else:
			action.text = Loc.t("buy_listing") % CardDatabase.format_number(total)
			kit.style_action_button(action, Color("ffd266"), true)
			action.disabled = GameState.market_coins < total
			action.pressed.connect(func() -> void: buy_pressed.emit(str(listing.id)))
		row.add_child(action)

func _refresh_status() -> void:
	if status_label == null or connect_button == null or refresh_button == null:
		return
	if help_label:
		help_label.text = Loc.t("market_online_hint") if GameState.is_market_online() else Loc.t("market_help")
	refresh_button.visible = GameState.market_online
	if GameState.is_market_online():
		var who := GameState.public_name if not GameState.public_name.is_empty() else Loc.t("market_you")
		status_label.text = Loc.t("market_connected") % who
		status_label.add_theme_color_override("font_color", Color("78e6a0"))
		connect_button.text = Loc.t("market_disconnect")
		kit.style_action_button(connect_button, Color("ff8b9d"), false)
	elif GameState.market_online:
		status_label.text = Loc.t("market_no_network")
		status_label.add_theme_color_override("font_color", Color("ff8b9d"))
		connect_button.text = Loc.t("market_connect")
		kit.style_action_button(connect_button, Color("ffd266"), true)
	else:
		status_label.text = Loc.t("market_offline")
		status_label.add_theme_color_override("font_color", UIKit.COLOR_MUTED)
		connect_button.text = Loc.t("market_connect")
		kit.style_action_button(connect_button, Color("ffd266"), true)

func _on_refresh_pressed() -> void:
	if _busy:
		return
	AudioManager.play("click")
	_busy = true
	refresh_button.disabled = true
	await GameState.refresh_market_listings()
	refresh_button.disabled = false
	_busy = false
	rebuild()

func _on_connect_pressed() -> void:
	if _busy:
		return
	AudioManager.play("click")
	if GameState.is_market_online():
		GameState.disconnect_market()
		rebuild()
		return
	_busy = true
	connect_button.disabled = true
	status_label.text = Loc.t("market_connecting")
	var result: Dictionary = await GameState.connect_market()
	connect_button.disabled = false
	_busy = false
	rebuild()
	if not bool(result.get("ok", false)):
		status_label.text = str(result.get("error", Loc.t("market_no_network")))
		status_label.add_theme_color_override("font_color", Color("ff8b9d"))

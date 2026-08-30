extends Control
## Coque mobile V24 : header, navigation, pages et overlays.

const WINDOW_TITLE := "Forge des Familiers — Bêta"
const BackgroundFX := preload("res://scripts/background_fx.gd")
const FarmPageScript := preload("res://scripts/pages/farm_page.gd")
const CollectionPageScript := preload("res://scripts/pages/collection_page.gd")
const AlbumsPageScript := preload("res://scripts/pages/albums_page.gd")
const FusionPageScript := preload("res://scripts/pages/fusion_page.gd")
const MarketPageScript := preload("res://scripts/pages/market_page.gd")
const OverlayHostScript := preload("res://scripts/ui/overlay_host.gd")
const UIKitScript := preload("res://scripts/ui/ui_kit.gd")

var kit: UIKit
var overlays: OverlayHost
var farm_page: FarmPage
var collection_page: CollectionPage
var albums_page: AlbumsPage
var fusion_page: FusionPage
var market_page: MarketPage

var _essence_label: Label
var _essence_title: Label
var _cards_label: Label
var _cards_title: Label
var _brand_name: Label
var _page_host: Control
var _pages: Dictionary = {}
var _nav_buttons: Dictionary = {}
var _current_page: String = "farm"
var _ui_tick_accumulator := 0.0

func _ready() -> void:
	_apply_window_title()
	call_deferred("_apply_window_title")
	kit = UIKitScript.new()
	theme = kit.make_theme()
	_build_background()
	_build_shell()
	GameState.essence_changed.connect(_on_essence_changed)
	GameState.coins_changed.connect(func(_v: int) -> void: market_page.rebuild())
	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.market_changed.connect(func() -> void: market_page.rebuild())
	GameState.farm_state_changed.connect(func() -> void: farm_page.refresh_progression())
	GameState.missions_changed.connect(func() -> void: farm_page.refresh_progression())
	GameState.expedition_changed.connect(func() -> void: farm_page.refresh_progression())
	GameState.dust_changed.connect(func(_v: int) -> void: albums_page.rebuild())
	GameState.collections_changed.connect(_on_collections_changed)
	GameState.mastery_changed.connect(func() -> void: collection_page.refresh_counts())
	Loc.changed.connect(_apply_locale)
	_on_essence_changed(GameState.essence)
	_apply_locale()
	_switch_page("farm")
	set_process(true)
	var offline_reward := GameState.consume_offline_reward()
	if offline_reward > 0:
		call_deferred("_toast", "+%s essences gagnées hors ligne." % CardDatabase.format_number(offline_reward), UIKit.COLOR_CYAN)
	if not GameState.is_guide_complete():
		call_deferred("_nudge_guide")

func _nudge_guide() -> void:
	overlays.show_tutorial()

func _build_background() -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.48, 1.0])
	gradient.colors = PackedColorArray([Color("11163a"), Color("080d24"), Color("050714")])
	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 540
	gradient_texture.height = 960
	gradient_texture.fill_from = Vector2(0.12, 0.0)
	gradient_texture.fill_to = Vector2(0.88, 1.0)
	var background := TextureRect.new()
	background.texture = gradient_texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var effects := BackgroundFX.new()
	effects.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(effects)

func _build_shell() -> void:
	var safe_area := MarginContainer.new()
	safe_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_area.add_theme_constant_override("margin_left", 16)
	safe_area.add_theme_constant_override("margin_right", 16)
	safe_area.add_theme_constant_override("margin_top", 14)
	safe_area.add_theme_constant_override("margin_bottom", 14)
	add_child(safe_area)
	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", 11)
	safe_area.add_child(shell)
	_build_header(shell)
	var content_panel := PanelContainer.new()
	content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var content_style := kit.box(Color(0.045, 0.062, 0.135, 0.97), 30, Color(0.48, 0.40, 0.82, 0.40), 1, 0)
	content_style.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	content_style.shadow_size = 10
	content_style.shadow_offset = Vector2(0, 5)
	content_panel.add_theme_stylebox_override("panel", content_style)
	shell.add_child(content_panel)
	_page_host = Control.new()
	_page_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_panel.add_child(_page_host)
	_build_pages()
	_build_navigation(shell)
	overlays = OverlayHostScript.new()
	add_child(overlays)
	overlays.setup(kit)

func _build_header(parent: Control) -> void:
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 72
	header.add_theme_constant_override("separation", 10)
	parent.add_child(header)
	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.add_theme_constant_override("separation", -3)
	header.add_child(brand)
	brand.add_child(kit.label("FORGE", 11, UIKit.COLOR_CYAN))
	_brand_name = kit.label(Loc.t("brand_sub"), 20, UIKit.COLOR_TEXT)
	_brand_name.add_theme_constant_override("outline_size", 2)
	_brand_name.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.30, 0.85))
	brand.add_child(_brand_name)
	var essence_chip := kit.stat_chip(Loc.t("essence"), UIKit.COLOR_ACCENT_LIGHT)
	_essence_label = essence_chip.get_meta("value_label")
	_essence_title = essence_chip.get_child(0).get_child(0)
	header.add_child(essence_chip)
	var cards_chip := kit.stat_chip(Loc.t("cards"), UIKit.COLOR_CYAN)
	_cards_label = cards_chip.get_meta("value_label")
	_cards_title = cards_chip.get_child(0).get_child(0)
	header.add_child(cards_chip)
	var settings_btn := Button.new()
	settings_btn.custom_minimum_size = Vector2(46, 46)
	settings_btn.icon = load("res://assets/ui/icon_settings.svg")
	settings_btn.expand_icon = true
	settings_btn.add_theme_constant_override("icon_max_width", 22)
	settings_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	kit.style_action_button(settings_btn, UIKit.COLOR_ACCENT, false)
	settings_btn.pressed.connect(func() -> void: AudioManager.play("click"); overlays.show_settings())
	header.add_child(settings_btn)

func _build_pages() -> void:
	farm_page = FarmPageScript.new()
	collection_page = CollectionPageScript.new()
	albums_page = AlbumsPageScript.new()
	fusion_page = FusionPageScript.new()
	market_page = MarketPageScript.new()
	for page in [farm_page, collection_page, albums_page, fusion_page, market_page]:
		page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_page_host.add_child(page)
	farm_page.setup(kit)
	collection_page.setup(kit)
	albums_page.setup(kit)
	fusion_page.setup(kit)
	market_page.setup(kit)
	_pages = {
		"farm": farm_page,
		"collection": collection_page,
		"albums": albums_page,
		"fusion": fusion_page,
		"market": market_page
	}
	farm_page.missions_pressed.connect(func() -> void: overlays.show_missions())
	farm_page.expeditions_pressed.connect(func() -> void: overlays.show_expeditions())
	farm_page.upgrades_pressed.connect(func() -> void: overlays.show_upgrades())
	farm_page.crate_opened.connect(func(result: Dictionary) -> void: overlays.show_opening_result(result))
	farm_page.floating_gain.connect(_show_floating_gain)
	collection_page.card_pressed.connect(func(card: Dictionary) -> void: overlays.show_card_details(card))
	albums_page.habitat_claim.connect(_on_claim_habitat)
	albums_page.album_claim.connect(_on_claim_album)
	albums_page.album_open.connect(func(album_id: String) -> void: overlays.show_album_detail(album_id))
	albums_page.craft_pressed.connect(_on_craft)
	albums_page.ultimate_pressed.connect(func() -> void: overlays.show_ultimate())
	fusion_page.fuse_pressed.connect(_on_fuse)
	fusion_page.fuse_all_pressed.connect(_on_fuse_all)
	market_page.buy_pressed.connect(_on_buy)
	market_page.cancel_pressed.connect(_on_cancel)

func _build_navigation(parent: Control) -> void:
	var nav_panel := PanelContainer.new()
	nav_panel.custom_minimum_size.y = 84
	var nav_style := kit.box(Color(0.048, 0.065, 0.14, 0.99), 25, Color(0.38, 0.34, 0.68, 0.52), 1, 7)
	nav_style.shadow_color = Color(0.0, 0.0, 0.0, 0.36)
	nav_style.shadow_size = 7
	nav_style.shadow_offset = Vector2(0, -2)
	nav_panel.add_theme_stylebox_override("panel", nav_style)
	parent.add_child(nav_panel)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 4)
	nav_panel.add_child(nav)
	var entries := {"farm": Loc.t("nav_farm"), "collection": Loc.t("nav_collection"), "albums": Loc.t("nav_albums"), "fusion": Loc.t("nav_fusion"), "market": Loc.t("nav_market")}
	var icons := {
		"farm": "res://assets/ui/nav_farm.svg",
		"collection": "res://assets/ui/nav_cards.svg",
		"albums": "res://assets/ui/nav_albums.svg",
		"fusion": "res://assets/ui/nav_fusion.svg",
		"market": "res://assets/ui/nav_market.svg"
	}
	for page_id in entries:
		var button := Button.new()
		button.text = entries[page_id]
		button.icon = load(icons[page_id])
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 18)
		button.custom_minimum_size.y = 68
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_font_override("font", kit.font_bold)
		button.add_theme_font_size_override("font_size", 10)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_switch_page.bind(page_id))
		nav.add_child(button)
		_nav_buttons[page_id] = button

func _switch_page(page_id: String) -> void:
	if not _pages.has(page_id):
		return
	AudioManager.play("click")
	var changed := _current_page != page_id
	_current_page = page_id
	GameState.note_visit(page_id)
	if page_id == "market" and GameState.market_online:
		GameState.refresh_market_listings()
	for id in _pages:
		_pages[id].visible = str(id) == page_id
	if changed:
		var target: Control = _pages[page_id]
		target.modulate.a = 0.0
		create_tween().tween_property(target, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for id in _nav_buttons:
		var button: Button = _nav_buttons[id]
		var active: bool = str(id) == page_id
		var accent: Color = UIKit.PAGE_ACCENTS.get(str(id), UIKit.COLOR_ACCENT)
		button.add_theme_color_override("font_color", Color.WHITE if active else UIKit.COLOR_MUTED)
		button.add_theme_color_override("icon_normal_color", accent if active else UIKit.COLOR_MUTED)
		if active:
			var active_style := kit.box(Color(accent.darkened(0.62), 0.98), 17, Color(accent, 0.78), 1, 5)
			active_style.border_width_bottom = 4
			button.add_theme_stylebox_override("normal", active_style)
		else:
			button.add_theme_stylebox_override("normal", kit.box(Color.TRANSPARENT, 17, Color.TRANSPARENT, 0, 5))
		button.add_theme_stylebox_override("hover", kit.box(Color(accent.darkened(0.70), 0.72), 17, Color(accent, 0.48), 1, 5))

func _on_essence_changed(value: int) -> void:
	if _essence_label:
		_essence_label.text = CardDatabase.format_number(value)
	farm_page.refresh_open_button()

func _on_inventory_changed() -> void:
	if _cards_label:
		_cards_label.text = CardDatabase.format_number(GameState.get_total_cards())
	collection_page.refresh_counts()
	fusion_page.refresh_rows()
	farm_page.refresh()

func _on_collections_changed() -> void:
	_on_inventory_changed()
	albums_page.rebuild()

func _apply_window_title() -> void:
	var win := get_window()
	if win:
		win.title = WINDOW_TITLE
	DisplayServer.window_set_title(WINDOW_TITLE)

func _process(delta: float) -> void:
	if get_window().title != WINDOW_TITLE:
		_apply_window_title()
	_ui_tick_accumulator += delta
	if _ui_tick_accumulator < 0.25:
		return
	_ui_tick_accumulator = 0.0
	farm_page.refresh_progression()

func _on_claim_habitat(habitat_id: String) -> void:
	var result := GameState.claim_habitat(habitat_id)
	if not result.ok:
		_toast(result.error, Color("ff8b9d"))
		return
	AudioManager.play("mission")
	_toast("Habitat restauré : +%s poussières et +%d %% aux expéditions." % [CardDatabase.format_number(int(result.reward)), int(result.bonus)], Color("73d6a4"))

func _on_claim_album(album_id: String) -> void:
	var result := GameState.claim_album(album_id)
	if not result.ok:
		_toast(result.error, Color("ff8b9d"))
		return
	AudioManager.play("mission")
	_toast("Album terminé : récompenses ajoutées.", Color("ffd266"))

func _apply_locale() -> void:
	if _brand_name:
		_brand_name.text = Loc.t("brand_sub")
	if _essence_title:
		_essence_title.text = Loc.t("essence")
	if _cards_title:
		_cards_title.text = Loc.t("cards")
	var nav_keys := {"farm": "nav_farm", "collection": "nav_collection", "albums": "nav_albums", "fusion": "nav_fusion", "market": "nav_market"}
	for id in nav_keys:
		if _nav_buttons.has(id):
			_nav_buttons[id].text = Loc.t(str(nav_keys[id]))
	if farm_page and farm_page.has_method("apply_locale"):
		farm_page.apply_locale()
	if collection_page and collection_page.has_method("apply_locale"):
		collection_page.apply_locale()
	elif collection_page:
		collection_page.refresh_counts()
	if albums_page and albums_page.has_method("apply_locale"):
		albums_page.apply_locale()
	if fusion_page and fusion_page.has_method("apply_locale"):
		fusion_page.apply_locale()
	elif fusion_page:
		fusion_page.hint_label.text = Loc.t("fusion_hint")
		fusion_page.fuse_all_button.text = Loc.t("fuse_all")
	if market_page and market_page.has_method("apply_locale"):
		market_page.apply_locale()
	elif market_page:
		market_page.rebuild()

func _on_craft(amount: int = 1) -> void:
	var result: Dictionary = GameState.craft_commons(amount)
	if not result.ok:
		_toast(result.error, Color("ff8b9d"))
		return
	overlays.show_craft_batch(result)

func _on_fuse(card_id: String) -> void:
	var result := GameState.fuse(card_id)
	if not result.ok:
		_toast(result.error, Color("ff8b9d"))
		AudioManager.play("error")
		return
	AudioManager.play("fusion")
	overlays.show_reward_card(result.card, "FUSION RÉUSSIE", "%s × %s  →  1 nouvelle carte" % [CardDatabase.format_number(int(result.spent)), result.source.name])

func _on_fuse_all() -> void:
	var result := GameState.fuse_all()
	if not result.ok:
		_toast(result.error, Color("ffcf73"))
		return
	AudioManager.play("fusion")
	var pieces: Array[String] = []
	for rarity in CardDatabase.RARITY_ORDER:
		var amount := int(result.produced.get(rarity, 0))
		if amount > 0:
			pieces.append("%s ×%s" % [CardDatabase.RARITIES[rarity].label, CardDatabase.format_number(amount)])
	overlays.show_reward_card(result.last_card, "FUSION EN CASCADE", "  ·  ".join(pieces))

func _on_buy(listing_id: String) -> void:
	var result: Dictionary = await GameState.buy_market_listing(listing_id)
	if not result.ok:
		_toast(str(result.error), Color("ff8b9d"))
		return
	_toast(Loc.t("market_bought"), Color("78e6a0"))

func _on_cancel(listing_id: String) -> void:
	var result: Dictionary = await GameState.cancel_market_listing(listing_id)
	if not result.ok:
		_toast(str(result.error), Color("ff8b9d"))
		return
	_toast(Loc.t("market_cancelled"), UIKit.COLOR_CYAN)

func _toast(message: String, accent: Color) -> void:
	overlays.show_toast(message, accent)

func _show_floating_gain(amount: int) -> void:
	if farm_page.farm_world == null:
		return
	var gain := kit.label("+%d" % amount, 25, UIKit.COLOR_CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	gain.custom_minimum_size = Vector2(120, 40)
	gain.z_index = 50
	gain.add_theme_constant_override("outline_size", 7)
	gain.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.09, 0.95))
	add_child(gain)
	var global_center := farm_page.farm_world.get_global_rect().get_center()
	gain.position = global_center - get_global_rect().position - Vector2(60, 20)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(gain, "position:y", gain.position.y - 90.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(gain, "modulate:a", 0.0, 0.65).set_delay(0.12)
	tween.finished.connect(gain.queue_free)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("farm") and _current_page == "farm":
		farm_page._on_farm_pressed()

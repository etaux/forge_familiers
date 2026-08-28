extends Control
## Écran principal du prototype mobile.

const CreatureCardScene := preload("res://scripts/card_view.gd")
const CrateViewScene := preload("res://scripts/crate_view.gd")
const BackgroundFX := preload("res://scripts/background_fx.gd")
const FontKit := preload("res://scripts/ui_fonts.gd")

const COLOR_BG := Color("060918")
const COLOR_PANEL := Color("0d1530")
const COLOR_PANEL_SOFT := Color("162044")
const COLOR_TEXT := Color("f7f9ff")
const COLOR_MUTED := Color("aab4cc")
const COLOR_ACCENT := Color("8d70ff")
const COLOR_ACCENT_LIGHT := Color("d2c4ff")
const COLOR_CYAN := Color("62e4ff")
const COLOR_GOLD := Color("ffd36a")
const COLOR_GREEN := Color("76e5ac")
const PAGE_ACCENTS := {
	"farm": Color("62e4ff"),
	"collection": Color("6fa8ff"),
	"albums": Color("ffd36a"),
	"fusion": Color("b983ff"),
	"market": Color("ffb563")
}
const COLLECTION_PAGE_SIZE := 12
const FUSION_PAGE_SIZE := 8
const ULTIMATE_REQUIREMENTS_PAGE_SIZE := 12
const FUSION_RARITIES: Array[String] = ["common", "rare", "epic", "legendary"]

var _selected_crate: String = "small"
var _current_page: String = "farm"
var _font_regular: Font
var _font_semibold: Font
var _font_bold: Font
var _font_extrabold: Font

var _essence_label: Label
var _cards_label: Label
var _page_host: Control
var _pages: Dictionary = {}
var _nav_buttons: Dictionary = {}

var _crate_view: OriginCrateView
var _crate_title_label: Label
var _crate_detail_label: Label
var _crate_buttons: Dictionary = {}
var _farm_button: Button
var _open_button: Button
var _income_label: Label
var _missions_button: Button
var _expedition_button: Button
var _ui_tick_accumulator := 0.0

var _collection_progress_label: Label
var _collection_total_label: Label
var _collection_search: LineEdit
var _collection_filter: OptionButton
var _collection_grid: GridContainer
var _collection_scroll: ScrollContainer
var _collection_page_label: Label
var _collection_prev_button: Button
var _collection_next_button: Button
var _collection_page := 0
var _filtered_collection_ids: Array[String] = []
var _collection_views: Dictionary = {}

var _dust_label: Label
var _collections_list: VBoxContainer
var _craft_common_button: Button
var _ultimate_goal_button: Button
var _ultimate_progress_label: Label

var _fusion_rows: Dictionary = {}
var _fuse_all_button: Button
var _fusion_hint_label: Label
var _fusion_search: LineEdit
var _fusion_filter: OptionButton
var _fusion_scroll: ScrollContainer
var _fusion_recipe_list: VBoxContainer
var _fusion_page_label: Label
var _fusion_prev_button: Button
var _fusion_next_button: Button
var _fusion_page := 0
var _filtered_fusion_ids: Array[String] = []

var _market_coins_label: Label
var _market_count_label: Label
var _market_list: VBoxContainer

func _ready() -> void:
	_setup_ui_theme()
	_build_background()
	_build_interface()

	GameState.essence_changed.connect(_on_essence_changed)
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.market_changed.connect(_on_market_changed)
	GameState.farm_state_changed.connect(_refresh_progression_buttons)
	GameState.missions_changed.connect(_refresh_progression_buttons)
	GameState.expedition_changed.connect(_refresh_progression_buttons)
	GameState.dust_changed.connect(_on_dust_changed)
	GameState.collections_changed.connect(_on_collections_changed)
	_selected_crate = GameState.selected_crate
	if not CardDatabase.CRATES.has(_selected_crate):
		_selected_crate = "small"

	_select_crate(_selected_crate)
	_refresh_everything()
	_switch_page("farm")
	set_process(true)
	var offline_reward := GameState.consume_offline_reward()
	if offline_reward > 0:
		call_deferred("_show_toast", "+%s essences gagnées hors ligne." % CardDatabase.format_number(offline_reward), COLOR_CYAN)

func _setup_ui_theme() -> void:
	_font_regular = FontKit.make(500.0)
	_font_semibold = FontKit.make(650.0)
	_font_bold = FontKit.make(750.0)
	_font_extrabold = FontKit.make(900.0)
	var app_theme := Theme.new()
	app_theme.default_font = _font_regular
	app_theme.default_font_size = 14
	app_theme.set_font(&"font", &"Label", _font_regular)
	app_theme.set_font(&"font", &"Button", _font_bold)
	app_theme.set_font(&"font", &"LineEdit", _font_semibold)
	app_theme.set_font(&"font", &"OptionButton", _font_bold)
	app_theme.set_font(&"font", &"SpinBox", _font_semibold)
	app_theme.set_font_size(&"font_size", &"Button", 14)
	app_theme.set_font_size(&"font_size", &"LineEdit", 14)
	app_theme.set_font_size(&"font_size", &"OptionButton", 14)
	app_theme.set_font_size(&"font_size", &"SpinBox", 14)
	app_theme.set_color(&"font_color", &"LineEdit", COLOR_TEXT)
	app_theme.set_color(&"font_placeholder_color", &"LineEdit", Color(COLOR_MUTED, 0.72))
	var scroll_track := _box(Color(0.035, 0.045, 0.095, 0.60), 7)
	var scroll_grabber := _box(Color(0.35, 0.31, 0.62, 0.78), 7)
	var scroll_hover := _box(Color(0.48, 0.41, 0.82, 0.95), 7)
	for scroll_type in [&"VScrollBar", &"HScrollBar"]:
		app_theme.set_stylebox(&"scroll", scroll_type, scroll_track)
		app_theme.set_stylebox(&"scroll_focus", scroll_type, scroll_track)
		app_theme.set_stylebox(&"grabber", scroll_type, scroll_grabber)
		app_theme.set_stylebox(&"grabber_highlight", scroll_type, scroll_hover)
		app_theme.set_stylebox(&"grabber_pressed", scroll_type, scroll_hover)
	app_theme.set_stylebox(&"background", &"ProgressBar", _box(Color(0.035, 0.05, 0.11, 0.95), 7, Color(0.22, 0.26, 0.43, 0.7), 1))
	app_theme.set_stylebox(&"fill", &"ProgressBar", _box(Color(0.38, 0.72, 0.94, 0.95), 7))
	theme = app_theme

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

func _build_interface() -> void:
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
	var content_style := _box(Color(0.045, 0.062, 0.135, 0.97), 30, Color(0.48, 0.40, 0.82, 0.40), 1, 0)
	content_style.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	content_style.shadow_size = 10
	content_style.shadow_offset = Vector2(0, 5)
	content_panel.add_theme_stylebox_override("panel", content_style)
	shell.add_child(content_panel)

	_page_host = Control.new()
	_page_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_panel.add_child(_page_host)

	_build_farm_page()
	_build_collection_page()
	_build_albums_page()
	_build_fusion_page()
	_build_market_page()
	_build_navigation(shell)

func _build_header(parent: Control) -> void:
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 72
	header.add_theme_constant_override("separation", 10)
	parent.add_child(header)

	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.add_theme_constant_override("separation", -3)
	header.add_child(brand)

	var brand_top := _label("FORGE", 11, COLOR_CYAN)
	brand.add_child(brand_top)
	var brand_name := _label("DES FAMILIERS", 22, COLOR_TEXT)
	brand_name.add_theme_constant_override("outline_size", 2)
	brand_name.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.30, 0.85))
	brand.add_child(brand_name)

	var essence_chip := _make_stat_chip("ESSENCE", COLOR_ACCENT_LIGHT)
	_essence_label = essence_chip.get_meta("value_label")
	header.add_child(essence_chip)

	var cards_chip := _make_stat_chip("CARTES", COLOR_CYAN)
	_cards_label = cards_chip.get_meta("value_label")
	header.add_child(cards_chip)

func _make_stat_chip(title: String, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(112, 60)
	var stat_style := _box(Color(0.075, 0.10, 0.205, 0.98), 19, Color(accent, 0.58), 1, 10)
	stat_style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	stat_style.shadow_size = 5
	stat_style.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", stat_style)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", -3)
	panel.add_child(content)

	var title_label := _label(title, 10, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(title_label)
	var value_label := _label("0", 18, accent, HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(value_label)
	panel.set_meta("value_label", value_label)
	return panel

func _build_farm_page() -> void:
	var page := MarginContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_set_margins(page, 14, 14, 12, 12)
	_page_host.add_child(page)
	_pages["farm"] = page

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	page.add_child(content)

	var series_row := HBoxContainer.new()
	content.add_child(series_row)
	var series := _chip("SÉRIE 01  ·  CAISSE ORIGINE", COLOR_ACCENT)
	series_row.add_child(series)
	var series_spacer := Control.new()
	series_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	series_row.add_child(series_spacer)
	var idle := _chip("+1 / 10 SEC", COLOR_CYAN)
	series_row.add_child(idle)

	var progression_row := HBoxContainer.new()
	progression_row.add_theme_constant_override("separation", 8)
	content.add_child(progression_row)
	_missions_button = Button.new()
	_missions_button.text = "MISSIONS\n0 / 3 PRÊTES"
	_missions_button.custom_minimum_size = Vector2(0, 50)
	_missions_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_missions_button.add_theme_font_size_override("font_size", 11)
	_style_action_button(_missions_button, Color("ffd266"), false)
	_missions_button.pressed.connect(_show_missions_overlay)
	progression_row.add_child(_missions_button)
	_expedition_button = Button.new()
	_expedition_button.text = "EXPÉDITIONS\nDISPONIBLES"
	_expedition_button.custom_minimum_size = Vector2(0, 50)
	_expedition_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_expedition_button.add_theme_font_size_override("font_size", 11)
	_style_action_button(_expedition_button, Color("73d6a4"), false)
	_expedition_button.pressed.connect(_show_expeditions_overlay)
	progression_row.add_child(_expedition_button)

	_crate_view = CrateViewScene.new()
	_crate_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_crate_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_crate_view)

	_crate_title_label = _label("PETITE CAISSE", 22, COLOR_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(_crate_title_label)
	_crate_detail_label = _label("10 cartes · 100 essences", 12, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(_crate_detail_label)

	var selector_title := _label("CHOISIR LA TAILLE", 11, COLOR_MUTED)
	content.add_child(selector_title)

	var crate_grid := GridContainer.new()
	crate_grid.columns = 2
	crate_grid.add_theme_constant_override("h_separation", 8)
	crate_grid.add_theme_constant_override("v_separation", 8)
	content.add_child(crate_grid)

	for crate_id in CardDatabase.CRATE_ORDER:
		var crate: Dictionary = CardDatabase.CRATES[crate_id]
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 65)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = "%s\n%s cartes  ·  %s" % [crate.label, CardDatabase.format_number(int(crate.cards)), CardDatabase.format_number(int(crate.cost))]
		button.add_theme_font_size_override("font_size", 12)
		button.pressed.connect(_select_crate.bind(crate_id))
		crate_grid.add_child(button)
		_crate_buttons[crate_id] = button

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 9)
	content.add_child(actions)

	_farm_button = Button.new()
	_farm_button.custom_minimum_size = Vector2(0, 66)
	_farm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_farm_button.text = "RÉCOLTER\n+%d ESSENCES" % GameState.FARM_REWARD
	_farm_button.add_theme_font_size_override("font_size", 14)
	_style_action_button(_farm_button, COLOR_CYAN, false)
	_farm_button.pressed.connect(_on_farm_pressed)
	actions.add_child(_farm_button)

	_open_button = Button.new()
	_open_button.custom_minimum_size = Vector2(0, 66)
	_open_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_open_button.add_theme_font_size_override("font_size", 14)
	_open_button.pressed.connect(_on_open_pressed)
	actions.add_child(_open_button)

	_income_label = _label("Récolte manuelle toutes les 10 secondes · gain hors ligne limité à 8 h.", 11, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(_income_label)

func _build_collection_page() -> void:
	var page := MarginContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_set_margins(page, 14, 14, 14, 12)
	_page_host.add_child(page)
	_pages["collection"] = page

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	page.add_child(content)

	var heading := HBoxContainer.new()
	content.add_child(heading)
	var heading_text := VBoxContainer.new()
	heading_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(heading_text)
	var title := _label("COLLECTION", 25, COLOR_TEXT)
	heading_text.add_child(title)
	_collection_total_label = _label("0 cartes possédées", 11, COLOR_MUTED)
	heading_text.add_child(_collection_total_label)
	var progress_chip := _chip("0 / %d" % CardDatabase.CARD_ORDER.size(), COLOR_CYAN)
	_collection_progress_label = progress_chip.get_meta("value_label")
	heading.add_child(progress_chip)

	var hint := _label("Plus la carte est rare, plus son cadre et ses effets sont riches.", 12, COLOR_MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint)

	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 8)
	content.add_child(filters)
	_collection_search = LineEdit.new()
	_collection_search.placeholder_text = "Rechercher une créature…"
	_collection_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_collection_search.custom_minimum_size.y = 50
	_style_line_edit(_collection_search, Color("6fa8ff"))
	_collection_search.text_changed.connect(_on_collection_search_changed)
	filters.add_child(_collection_search)
	_collection_filter = OptionButton.new()
	_collection_filter.custom_minimum_size = Vector2(145, 50)
	_style_option_button(_collection_filter, Color("6fa8ff"))
	_collection_filter.add_item("TOUTES")
	for rarity in CardDatabase.RARITY_ORDER:
		_collection_filter.add_item(CardDatabase.RARITIES[rarity].label)
	_collection_filter.item_selected.connect(_on_collection_filter_changed)
	filters.add_child(_collection_filter)

	_collection_scroll = ScrollContainer.new()
	_collection_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_collection_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(_collection_scroll)

	_collection_grid = GridContainer.new()
	_collection_grid.columns = 2
	_collection_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_collection_grid.add_theme_constant_override("h_separation", 11)
	_collection_grid.add_theme_constant_override("v_separation", 13)
	_collection_scroll.add_child(_collection_grid)

	var pagination := HBoxContainer.new()
	pagination.add_theme_constant_override("separation", 8)
	content.add_child(pagination)
	_collection_prev_button = Button.new()
	_collection_prev_button.text = "‹  PRÉCÉDENTE"
	_collection_prev_button.custom_minimum_size = Vector2(130, 48)
	_style_action_button(_collection_prev_button, Color("6fa8ff"), false)
	_collection_prev_button.pressed.connect(_on_collection_previous_page)
	pagination.add_child(_collection_prev_button)
	_collection_page_label = _label("PAGE 1 / 1", 11, COLOR_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_collection_page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pagination.add_child(_collection_page_label)
	_collection_next_button = Button.new()
	_collection_next_button.text = "SUIVANTE  ›"
	_collection_next_button.custom_minimum_size = Vector2(130, 48)
	_style_action_button(_collection_next_button, Color("6fa8ff"), false)
	_collection_next_button.pressed.connect(_on_collection_next_page)
	pagination.add_child(_collection_next_button)
	_rebuild_collection_grid()

func _on_collection_search_changed(_new_text: String) -> void:
	_collection_page = 0
	_rebuild_collection_grid()

func _on_collection_filter_changed(_index: int) -> void:
	_collection_page = 0
	_rebuild_collection_grid()

func _on_collection_previous_page() -> void:
	_collection_page = maxi(0, _collection_page - 1)
	_rebuild_collection_grid()

func _on_collection_next_page() -> void:
	_collection_page += 1
	_rebuild_collection_grid()

func _rebuild_collection_grid() -> void:
	if _collection_grid == null or _collection_search == null or _collection_filter == null:
		return
	for child in _collection_grid.get_children():
		_collection_grid.remove_child(child)
		child.queue_free()
	_collection_views.clear()
	_filtered_collection_ids.clear()
	var query := _collection_search.text.strip_edges().to_lower()
	var rarity_filter := ""
	if _collection_filter.selected > 0:
		rarity_filter = CardDatabase.RARITY_ORDER[_collection_filter.selected - 1]
	for card_id in CardDatabase.CARD_ORDER:
		var card := CardDatabase.get_card(card_id)
		var matches_name: bool = query.is_empty() or str(card.name).to_lower().contains(query) or str(card.title).to_lower().contains(query)
		var matches_rarity: bool = rarity_filter.is_empty() or str(card.rarity) == rarity_filter
		if matches_name and matches_rarity:
			_filtered_collection_ids.append(card_id)
	var total_pages := maxi(1, ceili(float(_filtered_collection_ids.size()) / float(COLLECTION_PAGE_SIZE)))
	_collection_page = clampi(_collection_page, 0, total_pages - 1)
	var start_index := _collection_page * COLLECTION_PAGE_SIZE
	var end_index := mini(start_index + COLLECTION_PAGE_SIZE, _filtered_collection_ids.size())
	for index in range(start_index, end_index):
		var card_id := _filtered_collection_ids[index]
		var card := CardDatabase.get_card(card_id)
		var view := CreatureCardScene.new()
		view.custom_minimum_size = Vector2(210, 310)
		view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_collection_grid.add_child(view)
		view.configure(card, GameState.get_card_count(card_id), not GameState.is_card_discovered(card_id), true)
		view.card_pressed.connect(_on_collection_card_pressed)
		_collection_views[card_id] = view
	if _filtered_collection_ids.is_empty():
		var empty := _label("AUCUNE CARTE NE CORRESPOND À LA RECHERCHE", 12, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		empty.custom_minimum_size = Vector2(430, 120)
		_collection_grid.add_child(empty)
	_collection_page_label.text = "PAGE %d / %d  ·  %s CARTES" % [_collection_page + 1, total_pages, CardDatabase.format_number(_filtered_collection_ids.size())]
	_collection_prev_button.disabled = _collection_page <= 0
	_collection_next_button.disabled = _collection_page >= total_pages - 1
	if _collection_scroll != null:
		_collection_scroll.scroll_vertical = 0

func _build_albums_page() -> void:
	var page := MarginContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_set_margins(page, 14, 14, 14, 12)
	_page_host.add_child(page)
	_pages["albums"] = page

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 9)
	page.add_child(content)
	var heading := HBoxContainer.new()
	content.add_child(heading)
	var title_group := VBoxContainer.new()
	title_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title_group)
	title_group.add_child(_label("HABITATS & ALBUMS", 23, COLOR_TEXT))
	title_group.add_child(_label("Complétez des ensembles permanents.", 11, COLOR_MUTED))
	var dust_chip := _make_stat_chip("POUSSIÈRES", Color("73d6a4"))
	_dust_label = dust_chip.get_meta("value_label")
	heading.add_child(dust_chip)

	var bonus_panel := PanelContainer.new()
	bonus_panel.add_theme_stylebox_override("panel", _box(Color(0.045, 0.085, 0.10, 0.96), 15, Color("73d6a4"), 1, 9))
	content.add_child(bonus_panel)
	var bonus_label := _label("BONUS D’EXPÉDITION ACTIF : +%d %%" % GameState.get_expedition_bonus_percent(), 11, Color("8cf0b5"), HORIZONTAL_ALIGNMENT_CENTER)
	bonus_label.name = "BonusLabel"
	bonus_panel.add_child(bonus_label)

	var ultimate_panel := PanelContainer.new()
	var ultimate_style := _box(Color(0.095, 0.065, 0.025, 0.98), 18, Color("ffe08a"), 2, 11)
	ultimate_style.shadow_color = Color(0.0, 0.0, 0.0, 0.32)
	ultimate_style.shadow_size = 5
	ultimate_style.shadow_offset = Vector2(0, 3)
	ultimate_panel.add_theme_stylebox_override("panel", ultimate_style)
	content.add_child(ultimate_panel)
	var ultimate_row := HBoxContainer.new()
	ultimate_row.add_theme_constant_override("separation", 10)
	ultimate_panel.add_child(ultimate_row)
	var ultimate_text := VBoxContainer.new()
	ultimate_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ultimate_row.add_child(ultimate_text)
	ultimate_text.add_child(_label("OBJECTIF ULTIME", 15, Color("fff0b0")))
	_ultimate_progress_label = _label("0 / 0 UNIQUES DÉCOUVERTES", 10, COLOR_MUTED)
	ultimate_text.add_child(_ultimate_progress_label)
	_ultimate_goal_button = Button.new()
	_ultimate_goal_button.text = "VOIR L’OBJECTIF"
	_ultimate_goal_button.custom_minimum_size = Vector2(132, 54)
	_ultimate_goal_button.add_theme_font_size_override("font_size", 11)
	_style_action_button(_ultimate_goal_button, Color("ffe08a"), true)
	_ultimate_goal_button.pressed.connect(_show_ultimate_goal_overlay)
	ultimate_row.add_child(_ultimate_goal_button)
	_refresh_ultimate_goal_ui()

	_craft_common_button = Button.new()
	_craft_common_button.text = "INVOQUER UNE COMMUNE MANQUANTE  ·  %s POUSSIÈRES" % CardDatabase.format_number(GameState.CRAFT_MISSING_COMMON_COST)
	_craft_common_button.custom_minimum_size.y = 52
	_craft_common_button.add_theme_font_size_override("font_size", 11)
	_style_action_button(_craft_common_button, Color("73d6a4"), true)
	_craft_common_button.pressed.connect(_on_craft_missing_common)
	content.add_child(_craft_common_button)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	_collections_list = VBoxContainer.new()
	_collections_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_collections_list.add_theme_constant_override("separation", 9)
	scroll.add_child(_collections_list)
	_rebuild_collections_page()

func _rebuild_collections_page() -> void:
	if _collections_list == null:
		return
	for child in _collections_list.get_children():
		_collections_list.remove_child(child)
		child.queue_free()
	var page: Control = _pages.get("albums")
	if page != null:
		var bonus_label := page.find_child("BonusLabel", true, false) as Label
		if bonus_label != null:
			bonus_label.text = "BONUS D’EXPÉDITION ACTIF : +%d %%" % GameState.get_expedition_bonus_percent()
	if _craft_common_button != null:
		_craft_common_button.disabled = GameState.dust < GameState.CRAFT_MISSING_COMMON_COST
		var missing_count := 0
		for card in CardDatabase.get_cards_for_rarity("common"):
			if not GameState.is_card_discovered(str(card.id)):
				missing_count += 1
		_craft_common_button.text = ("INVOQUER UNE COMMUNE MANQUANTE" if missing_count > 0 else "INVOQUER UNE COMMUNE ALÉATOIRE") + "  ·  %s POUSSIÈRES" % CardDatabase.format_number(GameState.CRAFT_MISSING_COMMON_COST)

	var habitat_title := _label("HABITATS", 17, Color("8cf0b5"))
	habitat_title.custom_minimum_size.y = 34
	_collections_list.add_child(habitat_title)
	for habitat_id in CardDatabase.HABITAT_ORDER:
		var habitat := CardDatabase.get_habitat(habitat_id)
		var progress_data := GameState.get_habitat_progress(habitat_id)
		var claimed := GameState.claimed_habitats.has(habitat_id)
		var accent := Color(str(habitat.color))
		var panel := PanelContainer.new()
		panel.custom_minimum_size.y = 142
		panel.add_theme_stylebox_override("panel", _box(Color(0.05, 0.065, 0.125, 0.98), 18, Color(accent, 0.42), 1, 10))
		_collections_list.add_child(panel)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		panel.add_child(row)
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(details)
		details.add_child(_label(str(habitat.label), 14, accent))
		var description := _label(str(habitat.description), 10, COLOR_MUTED)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_child(description)
		var progress_bar := ProgressBar.new()
		progress_bar.min_value = 0
		progress_bar.max_value = int(progress_data.total)
		progress_bar.value = int(progress_data.discovered)
		progress_bar.show_percentage = false
		progress_bar.custom_minimum_size.y = 11
		details.add_child(progress_bar)
		details.add_child(_label("%d / %d créatures · +%d %% expédition" % [int(progress_data.discovered), int(progress_data.total), int(habitat.expedition_bonus_percent)], 10, COLOR_MUTED))
		var claim := Button.new()
		claim.custom_minimum_size = Vector2(112, 58)
		claim.add_theme_font_size_override("font_size", 9)
		claim.text = "RESTAURÉ\nBONUS ACTIF" if claimed else ("ACTIVER\n+%s POUSSIÈRES" % CardDatabase.format_number(int(habitat.reward_dust)) if bool(progress_data.complete) else "%d / %d" % [int(progress_data.discovered), int(progress_data.total)])
		claim.disabled = claimed or not bool(progress_data.complete)
		_style_action_button(claim, accent, true)
		claim.pressed.connect(_on_claim_habitat.bind(str(habitat_id)))
		row.add_child(claim)

	var album_title := _label("ALBUMS", 17, Color("ffd266"))
	album_title.custom_minimum_size.y = 42
	_collections_list.add_child(album_title)
	for album_id in CardDatabase.ALBUM_ORDER:
		var album := CardDatabase.get_album(album_id)
		var progress_data := GameState.get_album_progress(album_id)
		var claimed := GameState.claimed_albums.has(album_id)
		var panel := PanelContainer.new()
		panel.custom_minimum_size.y = 170
		panel.add_theme_stylebox_override("panel", _box(Color(0.07, 0.06, 0.125, 0.98), 18, Color(0.78, 0.58, 0.25, 0.42), 1, 10))
		_collections_list.add_child(panel)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		panel.add_child(row)
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(details)
		details.add_child(_label(str(album.label), 14, Color("ffd88a")))
		details.add_child(_label(str(album.description), 10, COLOR_MUTED))
		var progress_bar := ProgressBar.new()
		progress_bar.min_value = 0
		progress_bar.max_value = int(progress_data.total)
		progress_bar.value = int(progress_data.discovered)
		progress_bar.show_percentage = false
		progress_bar.custom_minimum_size.y = 11
		details.add_child(progress_bar)
		details.add_child(_label("%d / %d · Récompense : %s E  ·  %s J  ·  %s P" % [int(progress_data.discovered), int(progress_data.total), CardDatabase.format_number(int(album.reward_essence)), CardDatabase.format_number(int(album.reward_coins)), CardDatabase.format_number(int(album.reward_dust))], 9, COLOR_MUTED))
		var missing := _get_missing_card_names(album.card_ids)
		if not missing.is_empty():
			var missing_label := _label("Manque : %s" % missing, 9, Color("c2a7dc"))
			missing_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			details.add_child(missing_label)
		var album_actions := VBoxContainer.new()
		album_actions.custom_minimum_size.x = 112
		album_actions.add_theme_constant_override("separation", 7)
		row.add_child(album_actions)
		var consult := Button.new()
		consult.text = "CONSULTER\nLES %d CARTES" % int(progress_data.total)
		consult.custom_minimum_size = Vector2(112, 56)
		consult.add_theme_font_size_override("font_size", 9)
		_style_action_button(consult, COLOR_ACCENT, false)
		consult.pressed.connect(_show_album_detail.bind(str(album_id)))
		album_actions.add_child(consult)
		var claim := Button.new()
		claim.custom_minimum_size = Vector2(112, 50)
		claim.add_theme_font_size_override("font_size", 9)
		claim.text = "RÉCUPÉRÉ" if claimed else ("RÉCUPÉRER" if bool(progress_data.complete) else "%d / %d" % [int(progress_data.discovered), int(progress_data.total)])
		claim.disabled = claimed or not bool(progress_data.complete)
		_style_action_button(claim, Color("ffd266"), true)
		claim.pressed.connect(_on_claim_album.bind(str(album_id)))
		album_actions.add_child(claim)

func _show_album_detail(album_id: String) -> void:
	var album := CardDatabase.get_album(album_id)
	if album.is_empty():
		_show_toast("Album introuvable.", Color("ff8b9d"))
		return
	var progress_data := GameState.get_album_progress(album_id)
	var claimed := GameState.claimed_albums.has(album_id)
	var overlay := _new_overlay()
	var panel := _overlay_panel(456, 860)
	overlay.get_node("Center").add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	content.add_child(_label(str(album.label), 23, Color("ffd88a"), HORIZONTAL_ALIGNMENT_CENTER))
	var description := _label(str(album.description), 11, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(description)
	var progress_text := "%d / %d CARTES DÉCOUVERTES" % [int(progress_data.discovered), int(progress_data.total)]
	content.add_child(_label(progress_text, 12, Color("ffd266"), HORIZONTAL_ALIGNMENT_CENTER))
	var reward_panel := PanelContainer.new()
	reward_panel.add_theme_stylebox_override("panel", _box(Color(0.085, 0.065, 0.12, 0.95), 13, Color(0.78, 0.58, 0.25, 0.35), 1, 7))
	content.add_child(reward_panel)
	var reward_text := "RÉCOMPENSE  ·  %s ESSENCES  ·  %s JETONS  ·  %s POUSSIÈRES" % [CardDatabase.format_number(int(album.reward_essence)), CardDatabase.format_number(int(album.reward_coins)), CardDatabase.format_number(int(album.reward_dust))]
	reward_panel.add_child(_label(reward_text, 9, Color("e8d3a0"), HORIZONTAL_ALIGNMENT_CENTER))
	content.add_child(_label("Touchez une carte pour ouvrir sa fiche complète.", 10, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var grid := GridContainer.new()
	grid.name = "AlbumCardsGrid"
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	for card_id in album.card_ids:
		var card := CardDatabase.get_card(str(card_id))
		var view := CreatureCardScene.new()
		view.custom_minimum_size = Vector2(188, 278)
		view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(view)
		view.configure(card, GameState.get_card_count(str(card_id)), not GameState.is_card_discovered(str(card_id)), true)
		view.card_pressed.connect(_open_album_card_details.bind(overlay))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 9)
	content.add_child(actions)
	var close := Button.new()
	close.text = "FERMER"
	close.custom_minimum_size.y = 54
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_action_button(close, COLOR_ACCENT, false)
	close.pressed.connect(_close_overlay.bind(overlay))
	actions.add_child(close)
	var claim := Button.new()
	claim.text = "RÉCOMPENSE RÉCUPÉRÉE" if claimed else "RÉCUPÉRER LA RÉCOMPENSE"
	claim.custom_minimum_size.y = 54
	claim.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	claim.disabled = claimed or not bool(progress_data.complete)
	claim.add_theme_font_size_override("font_size", 10)
	_style_action_button(claim, Color("ffd266"), true)
	claim.pressed.connect(_on_claim_album_from_detail.bind(album_id, overlay))
	actions.add_child(claim)
	overlay.modulate.a = 0.0
	create_tween().tween_property(overlay, "modulate:a", 1.0, 0.16)

func _open_album_card_details(card: Dictionary, album_overlay: Control) -> void:
	if is_instance_valid(album_overlay):
		album_overlay.queue_free()
	_show_card_details(card)

func _on_claim_album_from_detail(album_id: String, overlay: Control) -> void:
	var result := GameState.claim_album(album_id)
	if not result.ok:
		_show_toast(result.error, Color("ff8b9d"))
		return
	if is_instance_valid(overlay):
		overlay.queue_free()
	_show_toast("Album terminé : récompenses ajoutées.", Color("ffd266"))

func _get_missing_card_names(card_ids: Array) -> String:
	var names: Array[String] = []
	for card_id in card_ids:
		if not GameState.is_card_discovered(str(card_id)):
			names.append(str(CardDatabase.get_card(str(card_id)).name))
			if names.size() >= 3:
				break
	return ", ".join(names)

func _on_claim_habitat(habitat_id: String) -> void:
	var result := GameState.claim_habitat(habitat_id)
	if not result.ok:
		_show_toast(result.error, Color("ff8b9d"))
		return
	_show_toast("Habitat restauré : +%s poussières et +%d %% aux expéditions." % [CardDatabase.format_number(int(result.reward)), int(result.bonus)], Color("73d6a4"))

func _on_claim_album(album_id: String) -> void:
	var result := GameState.claim_album(album_id)
	if not result.ok:
		_show_toast(result.error, Color("ff8b9d"))
		return
	_show_toast("Album terminé : récompenses ajoutées.", Color("ffd266"))

func _on_craft_missing_common() -> void:
	var result := GameState.craft_missing_common()
	if not result.ok:
		_show_toast(result.error, Color("ff8b9d"))
		return
	var subtitle := "%s poussières transformées · %s" % [CardDatabase.format_number(GameState.CRAFT_MISSING_COMMON_COST), "nouvelle découverte" if bool(result.new) else "exemplaire supplémentaire"]
	_show_reward_card(result.card, "INVOCATION RÉUSSIE", subtitle)

func _refresh_ultimate_goal_ui() -> void:
	if _ultimate_goal_button == null or _ultimate_progress_label == null:
		return
	var progress := GameState.get_ultimate_goal_progress()
	if bool(progress.owned):
		_ultimate_progress_label.text = "OBJECTIF ACCOMPLI · AETERNUM POSSÉDÉE"
		_ultimate_progress_label.add_theme_color_override("font_color", Color("fff0b0"))
		_ultimate_goal_button.text = "CONSULTER"
	elif bool(progress.ready):
		_ultimate_progress_label.text = "%d / %d UNIQUES · FORGE DISPONIBLE" % [int(progress.discovered), int(progress.total)]
		_ultimate_progress_label.add_theme_color_override("font_color", Color("ffe08a"))
		_ultimate_goal_button.text = "FORGER AETERNUM"
	else:
		_ultimate_progress_label.text = "%d / %d UNIQUES DÉCOUVERTES" % [int(progress.discovered), int(progress.total)]
		_ultimate_progress_label.add_theme_color_override("font_color", COLOR_MUTED)
		_ultimate_goal_button.text = "VOIR L’OBJECTIF"

func _show_ultimate_goal_overlay() -> void:
	var ultimate := CardDatabase.get_card(GameState.ULTIMATE_CARD_ID)
	var progress := GameState.get_ultimate_goal_progress()
	var overlay := _new_overlay()
	var panel := _overlay_panel(456, 860)
	overlay.get_node("Center").add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	content.add_child(_label("OBJECTIF ULTIME", 24, Color("fff0b0"), HORIZONTAL_ALIGNMENT_CENTER))
	var explanation := _label("Découvrez les %d cartes Uniques de l’Archive chromatique pour forger AETERNUM." % int(progress.total), 11, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(explanation)

	var card_center := CenterContainer.new()
	card_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(card_center)
	var ultimate_view := CreatureCardScene.new()
	ultimate_view.custom_minimum_size = Vector2(245, 360)
	card_center.add_child(ultimate_view)
	ultimate_view.configure(ultimate, GameState.get_card_count(GameState.ULTIMATE_CARD_ID), not bool(progress.owned), false)

	var state_text := "AETERNUM EST EN VOTRE POSSESSION" if bool(progress.owned) else "%d / %d UNIQUES DÉCOUVERTES" % [int(progress.discovered), int(progress.total)]
	content.add_child(_label(state_text, 13, Color("ffe08a") if bool(progress.ready) or bool(progress.owned) else COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var unique_grid := HFlowContainer.new()
	unique_grid.name = "UltimateUniqueGrid"
	unique_grid.alignment = FlowContainer.ALIGNMENT_CENTER
	unique_grid.add_theme_constant_override("h_separation", 5)
	unique_grid.add_theme_constant_override("v_separation", 5)
	content.add_child(unique_grid)
	var requirements_pagination := HBoxContainer.new()
	requirements_pagination.add_theme_constant_override("separation", 7)
	content.add_child(requirements_pagination)
	var requirements_prev := Button.new()
	requirements_prev.text = "‹"
	requirements_prev.custom_minimum_size = Vector2(54, 40)
	_style_action_button(requirements_prev, Color("ffe08a"), false)
	requirements_pagination.add_child(requirements_prev)
	var requirements_page_label := _label("PAGE 1 / 1", 10, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	requirements_page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	requirements_pagination.add_child(requirements_page_label)
	var requirements_next := Button.new()
	requirements_next.text = "›"
	requirements_next.custom_minimum_size = Vector2(54, 40)
	_style_action_button(requirements_next, Color("ffe08a"), false)
	requirements_pagination.add_child(requirements_next)
	var unique_ids: Array[String] = []
	for card in CardDatabase.get_cards_for_rarity("unique"):
		unique_ids.append(str(card.id))
	overlay.set_meta("ultimate_requirements", {"grid": unique_grid, "page_label": requirements_page_label, "prev": requirements_prev, "next": requirements_next, "page": 0, "ids": unique_ids})
	requirements_prev.pressed.connect(_on_ultimate_requirements_previous.bind(overlay))
	requirements_next.pressed.connect(_on_ultimate_requirements_next.bind(overlay))
	_render_ultimate_requirements_page(overlay)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 9)
	content.add_child(actions)
	var close := Button.new()
	close.text = "FERMER"
	close.custom_minimum_size.y = 54
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_action_button(close, COLOR_MUTED, false)
	close.pressed.connect(_close_overlay.bind(overlay))
	actions.add_child(close)
	var forge := Button.new()
	forge.text = "OBJECTIF ACCOMPLI" if bool(progress.owned) else "FORGER AETERNUM"
	forge.custom_minimum_size.y = 54
	forge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	forge.disabled = bool(progress.owned) or not bool(progress.ready)
	_style_action_button(forge, Color("ffe08a"), true)
	forge.pressed.connect(_on_claim_ultimate.bind(overlay))
	actions.add_child(forge)

func _on_ultimate_requirements_previous(overlay: Control) -> void:
	if not is_instance_valid(overlay) or not overlay.has_meta("ultimate_requirements"):
		return
	var state: Dictionary = overlay.get_meta("ultimate_requirements")
	state.page = maxi(0, int(state.page) - 1)
	_render_ultimate_requirements_page(overlay)

func _on_ultimate_requirements_next(overlay: Control) -> void:
	if not is_instance_valid(overlay) or not overlay.has_meta("ultimate_requirements"):
		return
	var state: Dictionary = overlay.get_meta("ultimate_requirements")
	state.page = int(state.page) + 1
	_render_ultimate_requirements_page(overlay)

func _render_ultimate_requirements_page(overlay: Control) -> void:
	if not is_instance_valid(overlay) or not overlay.has_meta("ultimate_requirements"):
		return
	var state: Dictionary = overlay.get_meta("ultimate_requirements")
	var grid: HFlowContainer = state.grid
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	var ids: Array = state.ids
	var total_pages := maxi(1, ceili(float(ids.size()) / float(ULTIMATE_REQUIREMENTS_PAGE_SIZE)))
	state.page = clampi(int(state.page), 0, total_pages - 1)
	var start_index := int(state.page) * ULTIMATE_REQUIREMENTS_PAGE_SIZE
	var end_index := mini(start_index + ULTIMATE_REQUIREMENTS_PAGE_SIZE, ids.size())
	for index in range(start_index, end_index):
		var card := CardDatabase.get_card(str(ids[index]))
		var discovered := GameState.is_card_discovered(str(card.id))
		var rarity_data: Dictionary = CardDatabase.RARITIES.unique
		var icon := _mini_art(card.art, rarity_data.color)
		icon.custom_minimum_size = Vector2(58, 66)
		icon.modulate = Color.WHITE if discovered else Color(0.24, 0.27, 0.35, 0.55)
		icon.tooltip_text = "%s · %s" % [card.name, "DÉCOUVERTE" if discovered else "MANQUANTE"]
		grid.add_child(icon)
	var page_label: Label = state.page_label
	var prev: Button = state.prev
	var next: Button = state.next
	page_label.text = "UNIQUES  ·  PAGE %d / %d" % [int(state.page) + 1, total_pages]
	prev.disabled = int(state.page) <= 0
	next.disabled = int(state.page) >= total_pages - 1

func _on_claim_ultimate(overlay: Control) -> void:
	var result := GameState.claim_ultimate_goal()
	if not result.ok:
		_show_toast(result.error, Color("ff8b9d"))
		return
	if is_instance_valid(overlay):
		overlay.queue_free()
	_show_reward_card(result.card, "CARTE ULTIME OBTENUE", "Objectif permanent accompli · AETERNUM est liée à votre compte")

func _build_fusion_page() -> void:
	var page := MarginContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_set_margins(page, 14, 14, 14, 12)
	_page_host.add_child(page)
	_pages["fusion"] = page

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 9)
	page.add_child(content)

	var heading := HBoxContainer.new()
	content.add_child(heading)
	var title_group := VBoxContainer.new()
	title_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title_group)
	var title := _label("ATELIER DE FUSION", 24, COLOR_TEXT)
	title_group.add_child(title)
	_fusion_hint_label = _label("Seuls les exemplaires strictement identiques peuvent fusionner.", 11, COLOR_MUTED)
	_fusion_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_group.add_child(_fusion_hint_label)

	_fuse_all_button = Button.new()
	_fuse_all_button.text = "TOUT\nFUSIONNER"
	_fuse_all_button.custom_minimum_size = Vector2(112, 56)
	_fuse_all_button.add_theme_font_size_override("font_size", 11)
	_style_action_button(_fuse_all_button, COLOR_ACCENT, true)
	_fuse_all_button.pressed.connect(_on_fuse_all_pressed)
	heading.add_child(_fuse_all_button)

	var info_panel := PanelContainer.new()
	info_panel.add_theme_stylebox_override("panel", _box(Color(0.08, 0.07, 0.17, 0.95), 15, Color(COLOR_ACCENT, 0.35), 1, 10))
	content.add_child(info_panel)
	var info := _label("Commune ×10  ·  Bleue ×500  ·  Épique ×1 000  ·  Légendaire ×10 000", 11, COLOR_ACCENT_LIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_panel.add_child(info)

	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 8)
	content.add_child(filters)
	_fusion_search = LineEdit.new()
	_fusion_search.placeholder_text = "Rechercher une recette…"
	_fusion_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fusion_search.custom_minimum_size.y = 48
	_style_line_edit(_fusion_search, Color("b983ff"))
	_fusion_search.text_changed.connect(_on_fusion_search_changed)
	filters.add_child(_fusion_search)
	_fusion_filter = OptionButton.new()
	_fusion_filter.custom_minimum_size = Vector2(145, 48)
	_style_option_button(_fusion_filter, Color("b983ff"))
	_fusion_filter.add_item("TOUTES")
	for rarity in FUSION_RARITIES:
		_fusion_filter.add_item(CardDatabase.RARITIES[rarity].label)
	_fusion_filter.item_selected.connect(_on_fusion_filter_changed)
	filters.add_child(_fusion_filter)

	_fusion_scroll = ScrollContainer.new()
	_fusion_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_fusion_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(_fusion_scroll)
	_fusion_recipe_list = VBoxContainer.new()
	_fusion_recipe_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fusion_recipe_list.add_theme_constant_override("separation", 9)
	_fusion_scroll.add_child(_fusion_recipe_list)

	var pagination := HBoxContainer.new()
	pagination.add_theme_constant_override("separation", 8)
	content.add_child(pagination)
	_fusion_prev_button = Button.new()
	_fusion_prev_button.text = "‹  PRÉCÉDENTE"
	_fusion_prev_button.custom_minimum_size = Vector2(130, 48)
	_style_action_button(_fusion_prev_button, Color("b983ff"), false)
	_fusion_prev_button.pressed.connect(_on_fusion_previous_page)
	pagination.add_child(_fusion_prev_button)
	_fusion_page_label = _label("PAGE 1 / 1", 11, COLOR_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_fusion_page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pagination.add_child(_fusion_page_label)
	_fusion_next_button = Button.new()
	_fusion_next_button.text = "SUIVANTE  ›"
	_fusion_next_button.custom_minimum_size = Vector2(130, 48)
	_style_action_button(_fusion_next_button, Color("b983ff"), false)
	_fusion_next_button.pressed.connect(_on_fusion_next_page)
	pagination.add_child(_fusion_next_button)
	_rebuild_fusion_recipes()

func _on_fusion_search_changed(_new_text: String) -> void:
	_fusion_page = 0
	_rebuild_fusion_recipes()

func _on_fusion_filter_changed(_index: int) -> void:
	_fusion_page = 0
	_rebuild_fusion_recipes()

func _on_fusion_previous_page() -> void:
	_fusion_page = maxi(0, _fusion_page - 1)
	_rebuild_fusion_recipes()

func _on_fusion_next_page() -> void:
	_fusion_page += 1
	_rebuild_fusion_recipes()

func _rebuild_fusion_recipes() -> void:
	if _fusion_recipe_list == null or _fusion_search == null or _fusion_filter == null:
		return
	for child in _fusion_recipe_list.get_children():
		_fusion_recipe_list.remove_child(child)
		child.queue_free()
	_fusion_rows.clear()
	_filtered_fusion_ids.clear()
	var query := _fusion_search.text.strip_edges().to_lower()
	var rarity_filter := ""
	if _fusion_filter.selected > 0:
		rarity_filter = FUSION_RARITIES[_fusion_filter.selected - 1]
	for card_id in CardDatabase.CARD_ORDER:
		var card := CardDatabase.get_card(card_id)
		if CardDatabase.get_fusion_cost(str(card.rarity)) <= 0:
			continue
		var matches_name: bool = query.is_empty() or str(card.name).to_lower().contains(query) or str(card.title).to_lower().contains(query)
		var matches_rarity: bool = rarity_filter.is_empty() or str(card.rarity) == rarity_filter
		if matches_name and matches_rarity:
			_filtered_fusion_ids.append(card_id)
	var total_pages := maxi(1, ceili(float(_filtered_fusion_ids.size()) / float(FUSION_PAGE_SIZE)))
	_fusion_page = clampi(_fusion_page, 0, total_pages - 1)
	var start_index := _fusion_page * FUSION_PAGE_SIZE
	var end_index := mini(start_index + FUSION_PAGE_SIZE, _filtered_fusion_ids.size())
	for index in range(start_index, end_index):
		_build_fusion_recipe(_fusion_recipe_list, CardDatabase.get_card(_filtered_fusion_ids[index]))
	if _filtered_fusion_ids.is_empty():
		var empty := _label("AUCUNE RECETTE NE CORRESPOND À LA RECHERCHE", 12, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		empty.custom_minimum_size.y = 120
		_fusion_recipe_list.add_child(empty)
	_fusion_page_label.text = "PAGE %d / %d  ·  %s RECETTES" % [_fusion_page + 1, total_pages, CardDatabase.format_number(_filtered_fusion_ids.size())]
	_fusion_prev_button.disabled = _fusion_page <= 0
	_fusion_next_button.disabled = _fusion_page >= total_pages - 1
	if _fusion_scroll != null:
		_fusion_scroll.scroll_vertical = 0
	_refresh_visible_fusion_rows()

func _refresh_visible_fusion_rows() -> void:
	for card_id in _fusion_rows:
		var count := GameState.get_card_count(str(card_id))
		var row: Dictionary = _fusion_rows[card_id]
		var cost := int(row.cost)
		var count_label: Label = row.count
		var button: Button = row.button
		count_label.text = "Possédées : %s / %s" % [CardDatabase.format_number(count), CardDatabase.format_number(cost)]
		button.disabled = count < cost

func _has_any_fusion_available() -> bool:
	for card_id in CardDatabase.CARD_ORDER:
		var card := CardDatabase.get_card(card_id)
		var cost := CardDatabase.get_fusion_cost(str(card.rarity))
		if cost > 0 and GameState.get_card_count(card_id) >= cost:
			return true
	return false

func _build_fusion_recipe(parent: Control, source: Dictionary) -> void:
	var rarity: String = source.rarity
	var next_rarity := CardDatabase.get_next_rarity(rarity)
	var target := CardDatabase.get_card_for_rarity(next_rarity)
	var cost := CardDatabase.get_fusion_cost(rarity)
	var source_rarity: Dictionary = CardDatabase.RARITIES[rarity]
	var target_rarity: Dictionary = CardDatabase.RARITIES[next_rarity]

	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 112
	panel.add_theme_stylebox_override("panel", _box(Color(0.055, 0.065, 0.135, 0.96), 18, Color(source_rarity.color, 0.35), 1, 9))
	parent.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	row.add_child(_mini_art(source.art, source_rarity.color))

	var text_group := VBoxContainer.new()
	text_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_group.alignment = BoxContainer.ALIGNMENT_CENTER
	text_group.add_theme_constant_override("separation", 1)
	row.add_child(text_group)
	var recipe_name := _label("%s × %s" % [CardDatabase.format_number(cost), source.name], 12, source_rarity.glow)
	recipe_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text_group.add_child(recipe_name)
	var arrow_text := _label("VERS UNE %s ALÉATOIRE" % target_rarity.label, 9, target_rarity.glow)
	text_group.add_child(arrow_text)
	var count_label := _label("Possédées : 0 / %s" % CardDatabase.format_number(cost), 10, COLOR_MUTED)
	text_group.add_child(count_label)

	row.add_child(_mini_art(target.art, target_rarity.color))
	var button := Button.new()
	button.text = "FUSIONNER"
	button.custom_minimum_size = Vector2(96, 52)
	button.add_theme_font_size_override("font_size", 10)
	_style_action_button(button, target_rarity.color, true)
	button.pressed.connect(_on_fuse_pressed.bind(str(source.id)))
	row.add_child(button)

	_fusion_rows[source.id] = {"count": count_label, "button": button, "cost": cost}

func _mini_art(path: String, color: Color) -> PanelContainer:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(70, 84)
	frame.add_theme_stylebox_override("panel", _box(Color(0.02, 0.025, 0.07, 1.0), 13, color, 2, 4))
	var art := TextureRect.new()
	art.texture = load(path)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(art)
	return frame

func _build_market_page() -> void:
	var page := MarginContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_set_margins(page, 14, 14, 14, 12)
	_page_host.add_child(page)
	_pages["market"] = page

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	page.add_child(content)

	var heading := HBoxContainer.new()
	content.add_child(heading)
	var title_group := VBoxContainer.new()
	title_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title_group)
	title_group.add_child(_label("MARCHÉ DES JOUEURS", 23, COLOR_TEXT))
	_market_count_label = _label("0 offre disponible", 11, COLOR_MUTED)
	title_group.add_child(_market_count_label)
	var coin_chip := _make_stat_chip("JETONS", Color("ffd266"))
	_market_coins_label = coin_chip.get_meta("value_label")
	heading.add_child(coin_chip)

	var server_panel := PanelContainer.new()
	server_panel.add_theme_stylebox_override("panel", _box(Color(0.10, 0.075, 0.12, 0.96), 16, Color("ffb45e"), 1, 10))
	content.add_child(server_panel)
	var server_row := HBoxContainer.new()
	server_row.add_theme_constant_override("separation", 8)
	server_panel.add_child(server_row)
	var server_text := _label("ARGENT RÉEL\nServeur sécurisé et validation des boutiques requis", 10, Color("ffd09a"))
	server_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	server_row.add_child(server_text)
	var locked_button := Button.new()
	locked_button.text = "NON ACTIVÉ"
	locked_button.disabled = true
	locked_button.custom_minimum_size = Vector2(98, 44)
	server_row.add_child(locked_button)

	var help := _label("Achetez avec les jetons ou mettez une carte en vente depuis sa fiche dans Collection.", 11, COLOR_MUTED)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(help)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	_market_list = VBoxContainer.new()
	_market_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_market_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_market_list)
	_rebuild_market_list()

func _rebuild_market_list() -> void:
	if _market_list == null:
		return
	for child in _market_list.get_children():
		_market_list.remove_child(child)
		child.queue_free()
	if _market_count_label != null:
		_market_count_label.text = "%d offre%s disponible%s" % [GameState.market_listings.size(), "s" if GameState.market_listings.size() > 1 else "", "s" if GameState.market_listings.size() > 1 else ""]
	if GameState.market_listings.is_empty():
		var empty := _label("Le marché est vide. Mettez une carte en vente depuis votre collection.", 13, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		empty.custom_minimum_size.y = 120
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_market_list.add_child(empty)
		return

	for listing in GameState.market_listings:
		var card := CardDatabase.get_card(str(listing.card_id))
		if card.is_empty():
			continue
		var rarity_data: Dictionary = CardDatabase.RARITIES[card.rarity]
		var panel := PanelContainer.new()
		panel.custom_minimum_size.y = 105
		panel.add_theme_stylebox_override("panel", _box(Color(0.052, 0.062, 0.13, 0.97), 17, Color(rarity_data.color, 0.34), 1, 8))
		_market_list.add_child(panel)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 9)
		panel.add_child(row)
		row.add_child(_mini_art(card.art, rarity_data.color))

		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(details)
		var name_label := _label("%s  ×%s" % [card.name, CardDatabase.format_number(int(listing.quantity))], 13, rarity_data.glow)
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		details.add_child(name_label)
		details.add_child(_label("Vendeur : %s" % str(listing.seller), 10, COLOR_MUTED))
		var total := int(listing.quantity) * int(listing.unit_price)
		details.add_child(_label("%s jetons au total" % CardDatabase.format_number(total), 11, Color("ffd266")))

		var action := Button.new()
		action.custom_minimum_size = Vector2(105, 54)
		action.add_theme_font_size_override("font_size", 10)
		if bool(listing.get("is_player", false)):
			action.text = "ANNULER\nL’OFFRE"
			_style_action_button(action, Color("ff8b9d"), false)
			action.pressed.connect(_on_cancel_listing.bind(str(listing.id)))
		else:
			action.text = "ACHETER\n%s" % CardDatabase.format_number(total)
			_style_action_button(action, Color("ffd266"), true)
			action.disabled = GameState.market_coins < total
			action.pressed.connect(_on_buy_listing.bind(str(listing.id)))
		row.add_child(action)

func _build_navigation(parent: Control) -> void:
	var nav_panel := PanelContainer.new()
	nav_panel.custom_minimum_size.y = 84
	var nav_style := _box(Color(0.048, 0.065, 0.14, 0.99), 25, Color(0.38, 0.34, 0.68, 0.52), 1, 7)
	nav_style.shadow_color = Color(0.0, 0.0, 0.0, 0.36)
	nav_style.shadow_size = 7
	nav_style.shadow_offset = Vector2(0, -2)
	nav_panel.add_theme_stylebox_override("panel", nav_style)
	parent.add_child(nav_panel)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 4)
	nav_panel.add_child(nav)
	var entries := {
		"farm": "FERME",
		"collection": "CARTES",
		"albums": "ALBUMS",
		"fusion": "FUSION",
		"market": "MARCHÉ"
	}
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
		button.add_theme_font_override("font", _font_bold)
		button.add_theme_font_size_override("font_size", 11)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_switch_page.bind(page_id))
		nav.add_child(button)
		_nav_buttons[page_id] = button

func _select_crate(crate_id: String) -> void:
	if not CardDatabase.CRATES.has(crate_id):
		return
	_selected_crate = crate_id
	GameState.selected_crate = crate_id
	if _crate_view != null:
		_crate_view.set_crate(crate_id)
	var crate: Dictionary = CardDatabase.CRATES[crate_id]
	if _crate_title_label != null:
		_crate_title_label.text = "CAISSE ORIGINE  ·  %s" % crate.label
		_crate_detail_label.text = "%s cartes  ·  %s essences  ·  %s" % [CardDatabase.format_number(int(crate.cards)), CardDatabase.format_number(int(crate.cost)), crate.subtitle]
	_update_crate_buttons()
	_refresh_farm_action()

func _update_crate_buttons() -> void:
	for crate_id in _crate_buttons:
		var button: Button = _crate_buttons[crate_id]
		var selected: bool = str(crate_id) == _selected_crate
		var accent := COLOR_ACCENT_LIGHT if selected else Color("444d70")
		var background := Color(0.20, 0.14, 0.43, 0.96) if selected else Color(0.055, 0.065, 0.14, 0.9)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_override("font", _font_bold)
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_color_override("font_color", COLOR_TEXT if selected else COLOR_MUTED)
		button.add_theme_color_override("font_hover_color", COLOR_TEXT)
		var normal_style := _box(background, 16, Color(accent, 0.78 if selected else 0.40), 2 if selected else 1, 8)
		if selected:
			normal_style.shadow_color = Color(0.0, 0.0, 0.0, 0.26)
			normal_style.shadow_size = 4
			normal_style.shadow_offset = Vector2(0, 2)
		button.add_theme_stylebox_override("normal", normal_style)
		button.add_theme_stylebox_override("hover", _box(background.lightened(0.08), 16, COLOR_ACCENT_LIGHT, 2, 8))
		button.add_theme_stylebox_override("pressed", _box(background.darkened(0.08), 16, COLOR_ACCENT, 2, 8))

func _switch_page(page_id: String) -> void:
	if not _pages.has(page_id):
		return
	var changed := _current_page != page_id
	_current_page = page_id
	for id in _pages:
		_pages[id].visible = str(id) == page_id
	if changed:
		var target: Control = _pages[page_id]
		target.modulate.a = 0.0
		create_tween().tween_property(target, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for id in _nav_buttons:
		var button: Button = _nav_buttons[id]
		var active: bool = str(id) == page_id
		var accent: Color = PAGE_ACCENTS.get(str(id), COLOR_ACCENT)
		button.add_theme_color_override("font_color", Color.WHITE if active else COLOR_MUTED)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("icon_normal_color", accent if active else COLOR_MUTED)
		button.add_theme_color_override("icon_hover_color", accent.lightened(0.16))
		button.add_theme_color_override("icon_pressed_color", accent)
		if active:
			var active_style := _box(Color(accent.darkened(0.62), 0.98), 17, Color(accent, 0.78), 1, 5)
			active_style.border_width_bottom = 4
			button.add_theme_stylebox_override("normal", active_style)
		else:
			button.add_theme_stylebox_override("normal", _box(Color.TRANSPARENT, 17, Color.TRANSPARENT, 0, 5))
		button.add_theme_stylebox_override("hover", _box(Color(accent.darkened(0.70), 0.72), 17, Color(accent, 0.48), 1, 5))
		button.add_theme_stylebox_override("pressed", _box(Color(accent.darkened(0.76), 0.96), 17, accent, 2, 5))
		button.add_theme_stylebox_override("focus", _box(Color.TRANSPARENT, 17, Color(accent, 0.75), 2, 4))

func _refresh_everything() -> void:
	_on_essence_changed(GameState.essence)
	_on_coins_changed(GameState.market_coins)
	_on_inventory_changed()
	_on_market_changed()
	_on_dust_changed(GameState.dust)
	_refresh_progression_buttons()
	_refresh_ultimate_goal_ui()

func _on_essence_changed(value: int) -> void:
	if _essence_label != null:
		_essence_label.text = CardDatabase.format_number(value)
	_refresh_farm_action()

func _on_coins_changed(value: int) -> void:
	if _market_coins_label != null:
		_market_coins_label.text = CardDatabase.format_number(value)
	_rebuild_market_list()

func _on_market_changed() -> void:
	_rebuild_market_list()

func _on_dust_changed(value: int) -> void:
	if _dust_label != null:
		_dust_label.text = CardDatabase.format_number(value)
	_rebuild_collections_page()

func _on_collections_changed() -> void:
	_on_inventory_changed()
	_rebuild_collections_page()
	_refresh_ultimate_goal_ui()

func _on_inventory_changed() -> void:
	if _cards_label != null:
		_cards_label.text = CardDatabase.format_number(GameState.get_total_cards())
	if _collection_progress_label != null:
		_collection_progress_label.text = "%d / %d" % [GameState.get_discovered_count(), CardDatabase.CARD_ORDER.size()]
	if _collection_total_label != null:
		_collection_total_label.text = "%s cartes possédées" % CardDatabase.format_number(GameState.get_total_cards())

	for card_id in _collection_views:
		var view: CreatureCard = _collection_views[card_id]
		view.set_quantity(GameState.get_card_count(card_id), GameState.is_card_discovered(str(card_id)))

	_refresh_visible_fusion_rows()
	if _fuse_all_button != null:
		_fuse_all_button.disabled = not _has_any_fusion_available()

func _process(delta: float) -> void:
	_ui_tick_accumulator += delta
	if _ui_tick_accumulator < 0.25:
		return
	_ui_tick_accumulator = 0.0
	_refresh_progression_buttons()

func _refresh_progression_buttons() -> void:
	if _farm_button != null:
		var remaining := GameState.get_farm_cooldown()
		_farm_button.disabled = remaining > 0
		_farm_button.text = "RÉCOLTER\n+%d ESSENCES" % GameState.FARM_REWARD if remaining <= 0 else "RECHARGE\n%d SEC" % remaining
	if _missions_button != null:
		var ready := 0
		for mission in GameState.daily_missions:
			if int(mission.progress) >= int(mission.target) and not bool(mission.claimed):
				ready += 1
		_missions_button.text = "MISSIONS\n%d RÉCOMPENSE%s" % [ready, "S" if ready > 1 else ""] if ready > 0 else "MISSIONS\nDU JOUR"
	if _expedition_button != null:
		if GameState.active_expedition.is_empty():
			_expedition_button.text = "EXPÉDITIONS\nDISPONIBLES"
		elif GameState.is_expedition_complete():
			_expedition_button.text = "EXPÉDITION\nRÉCOMPENSE PRÊTE"
		else:
			_expedition_button.text = "EXPÉDITION\n%s" % _format_duration(GameState.get_expedition_remaining())

func _refresh_farm_action() -> void:
	if _open_button == null or not CardDatabase.CRATES.has(_selected_crate):
		return
	var crate: Dictionary = CardDatabase.CRATES[_selected_crate]
	var affordable := GameState.can_afford(_selected_crate)
	_open_button.text = "OUVRIR %s CARTES\n%s ESSENCES" % [CardDatabase.format_number(int(crate.cards)), CardDatabase.format_number(int(crate.cost))]
	_style_action_button(_open_button, COLOR_ACCENT if affordable else Color("c45f72"), true)
	_open_button.modulate = Color.WHITE if affordable else Color(0.78, 0.80, 0.9, 0.78)

func _on_farm_pressed() -> void:
	var result := GameState.farm()
	if not result.ok:
		return
	_crate_view.punch()
	_show_floating_gain(int(result.amount))
	_refresh_progression_buttons()

func _on_open_pressed() -> void:
	var result := GameState.open_crate(_selected_crate)
	if not result.ok:
		_show_toast(result.error, Color("ff8b9d"))
		_crate_view.punch()
		return
	_crate_view.punch()
	_show_opening_result(result)

func _on_collection_card_pressed(card: Dictionary) -> void:
	_show_card_details(card)

func _on_fuse_pressed(card_id: String) -> void:
	var result := GameState.fuse(card_id)
	if not result.ok:
		_show_toast(result.error, Color("ff8b9d"))
		return
	_show_reward_card(result.card, "FUSION RÉUSSIE", "%s × %s  →  1 nouvelle carte" % [CardDatabase.format_number(int(result.spent)), result.source.name])

func _on_fuse_all_pressed() -> void:
	var result := GameState.fuse_all()
	if not result.ok:
		_show_toast(result.error, Color("ffcf73"))
		return
	var pieces: Array[String] = []
	for rarity in CardDatabase.RARITY_ORDER:
		var amount := int(result.produced.get(rarity, 0))
		if amount > 0:
			pieces.append("%s ×%s" % [CardDatabase.RARITIES[rarity].label, CardDatabase.format_number(amount)])
	var best_card: Dictionary = result.last_card
	_show_reward_card(best_card, "FUSION EN CASCADE", "  ·  ".join(pieces))

func _show_missions_overlay() -> void:
	GameState.get_completed_mission_count()
	var overlay := _new_overlay()
	var panel := _overlay_panel(456, 760)
	overlay.get_node("Center").add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)
	content.add_child(_label("MISSIONS DU JOUR", 24, Color("ffd266"), HORIZONTAL_ALIGNMENT_CENTER))
	content.add_child(_label("Renouvellement quotidien · %s" % GameState.daily_date, 11, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER))

	var list := VBoxContainer.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 9)
	content.add_child(list)
	for mission in GameState.daily_missions:
		var complete: bool = int(mission.progress) >= int(mission.target)
		var claimed: bool = bool(mission.claimed)
		var accent := Color("78e6a0") if complete else COLOR_ACCENT_LIGHT
		var mission_panel := PanelContainer.new()
		mission_panel.custom_minimum_size.y = 125
		mission_panel.add_theme_stylebox_override("panel", _box(Color(0.055, 0.065, 0.135, 0.98), 17, Color(accent, 0.38), 1, 10))
		list.add_child(mission_panel)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		mission_panel.add_child(row)
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(details)
		details.add_child(_label(str(mission.label), 14, accent))
		details.add_child(_label(str(mission.description), 11, COLOR_MUTED))
		var progress := ProgressBar.new()
		progress.min_value = 0
		progress.max_value = int(mission.target)
		progress.value = int(mission.progress)
		progress.show_percentage = false
		progress.custom_minimum_size.y = 12
		details.add_child(progress)
		details.add_child(_label("%s / %s" % [CardDatabase.format_number(int(mission.progress)), CardDatabase.format_number(int(mission.target))], 10, COLOR_MUTED))
		var reward_text := "+%s %s" % [CardDatabase.format_number(int(mission.reward)), "JETONS" if str(mission.reward_type) == "coins" else "ESSENCES"]
		var claim := Button.new()
		claim.text = "RÉCUPÉRÉ" if claimed else reward_text
		claim.custom_minimum_size = Vector2(115, 52)
		claim.disabled = not complete or claimed
		claim.add_theme_font_size_override("font_size", 10)
		_style_action_button(claim, Color("ffd266"), true)
		claim.pressed.connect(_on_claim_mission.bind(str(mission.id), overlay))
		row.add_child(claim)

	var close := Button.new()
	close.text = "FERMER"
	close.custom_minimum_size.y = 55
	_style_action_button(close, COLOR_ACCENT, true)
	close.pressed.connect(_close_overlay.bind(overlay))
	content.add_child(close)

func _on_claim_mission(mission_id: String, overlay: Control) -> void:
	var result := GameState.claim_mission(mission_id)
	if not result.ok:
		_show_toast(result.error, Color("ff8b9d"))
		return
	overlay.queue_free()
	var currency := "jetons" if str(result.reward_type) == "coins" else "essences"
	_show_toast("Mission terminée : +%s %s." % [CardDatabase.format_number(int(result.reward)), currency], Color("ffd266"))
	call_deferred("_show_missions_overlay")

func _show_expeditions_overlay() -> void:
	var overlay := _new_overlay()
	var panel := _overlay_panel(456, 760)
	overlay.get_node("Center").add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 11)
	panel.add_child(content)
	content.add_child(_label("EXPÉDITIONS", 24, Color("73d6a4"), HORIZONTAL_ALIGNMENT_CENTER))

	if GameState.active_expedition.is_empty():
		var intro := _label("Envoyez automatiquement vos meilleures créatures. Elles restent disponibles dans la collection et sur les autres écrans.", 11, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(intro)
		var options := VBoxContainer.new()
		options.size_flags_vertical = Control.SIZE_EXPAND_FILL
		options.add_theme_constant_override("separation", 9)
		content.add_child(options)
		for expedition_id in ["short", "medium", "long"]:
			var definition: Dictionary = GameState.EXPEDITIONS[expedition_id]
			var option := PanelContainer.new()
			option.custom_minimum_size.y = 125
			option.add_theme_stylebox_override("panel", _box(Color(0.05, 0.075, 0.12, 0.98), 18, Color(0.35, 0.75, 0.55, 0.42), 1, 11))
			options.add_child(option)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			option.add_child(row)
			var details := VBoxContainer.new()
			details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(details)
			details.add_child(_label(str(definition.label), 15, Color("8cf0b5")))
			details.add_child(_label("Durée : %s" % str(definition.duration_label), 11, COLOR_MUTED))
			details.add_child(_label("Équipe : %d créature%s différente%s" % [int(definition.cards_required), "s" if int(definition.cards_required) > 1 else "", "s" if int(definition.cards_required) > 1 else ""], 10, COLOR_MUTED))
			var start := Button.new()
			start.text = "LANCER\n+%s ESSENCES" % CardDatabase.format_number(GameState.get_expedition_reward(str(expedition_id)))
			start.custom_minimum_size = Vector2(130, 58)
			start.disabled = GameState.get_discovered_count() < int(definition.cards_required)
			start.add_theme_font_size_override("font_size", 10)
			_style_action_button(start, Color("73d6a4"), true)
			start.pressed.connect(_on_start_expedition.bind(str(expedition_id), overlay))
			row.add_child(start)
	else:
		var expedition: Dictionary = GameState.active_expedition
		var definition: Dictionary = GameState.EXPEDITIONS[str(expedition.id)]
		content.add_child(_label(str(definition.label), 19, Color("8cf0b5"), HORIZONTAL_ALIGNMENT_CENTER))
		var status_text := "TERMINÉE · RÉCOMPENSE PRÊTE" if GameState.is_expedition_complete() else "RETOUR DANS %s" % _format_duration(GameState.get_expedition_remaining())
		content.add_child(_label(status_text, 14, Color("ffd266") if GameState.is_expedition_complete() else COLOR_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
		var team_title := _label("ÉQUIPE EN EXPLORATION", 11, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		content.add_child(team_title)
		var team := HFlowContainer.new()
		team.alignment = FlowContainer.ALIGNMENT_CENTER
		team.size_flags_vertical = Control.SIZE_EXPAND_FILL
		team.add_theme_constant_override("h_separation", 8)
		team.add_theme_constant_override("v_separation", 8)
		content.add_child(team)
		for card_id in expedition.team:
			var card := CardDatabase.get_card(str(card_id))
			var rarity_data: Dictionary = CardDatabase.RARITIES[card.rarity]
			var member := VBoxContainer.new()
			member.custom_minimum_size.x = 78
			member.add_child(_mini_art(card.art, rarity_data.color))
			var member_name := _label(str(card.name), 8, rarity_data.glow, HORIZONTAL_ALIGNMENT_CENTER)
			member_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			member.add_child(member_name)
			team.add_child(member)
		var claim := Button.new()
		claim.text = "RÉCUPÉRER +%s ESSENCES" % CardDatabase.format_number(int(expedition.reward)) if GameState.is_expedition_complete() else "EXPÉDITION EN COURS"
		claim.custom_minimum_size.y = 60
		claim.disabled = not GameState.is_expedition_complete()
		_style_action_button(claim, Color("73d6a4"), true)
		claim.pressed.connect(_on_claim_expedition.bind(overlay))
		content.add_child(claim)

	var close := Button.new()
	close.text = "FERMER"
	close.custom_minimum_size.y = 54
	_style_action_button(close, COLOR_ACCENT, false)
	close.pressed.connect(_close_overlay.bind(overlay))
	content.add_child(close)

func _on_start_expedition(expedition_id: String, overlay: Control) -> void:
	var result := GameState.start_expedition(expedition_id)
	if not result.ok:
		_show_toast(result.error, Color("ff8b9d"))
		return
	overlay.queue_free()
	_show_toast("Expédition lancée avec succès.", Color("73d6a4"))

func _on_claim_expedition(overlay: Control) -> void:
	var result := GameState.claim_expedition()
	if not result.ok:
		_show_toast(result.error, Color("ff8b9d"))
		return
	overlay.queue_free()
	_show_toast("Expédition terminée : +%s essences." % CardDatabase.format_number(int(result.reward)), Color("73d6a4"))

func _format_duration(total_seconds: int) -> String:
	var seconds := maxi(0, total_seconds)
	var hours := int(seconds / 3600)
	var minutes := int((seconds % 3600) / 60)
	var remaining_seconds := seconds % 60
	if hours > 0:
		return "%d H %02d MIN" % [hours, minutes]
	return "%02d:%02d" % [minutes, remaining_seconds]

func _show_opening_result(result: Dictionary) -> void:
	var overlay := _new_overlay()
	var panel := _overlay_panel(456, 840)
	overlay.get_node("Center").add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	content.add_child(_label("OUVERTURE · CAISSE ORIGINE", 11, COLOR_ACCENT_LIGHT, HORIZONTAL_ALIGNMENT_CENTER))
	var title := _label("PRÉPAREZ-VOUS", 24, COLOR_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(title)
	var progress := _label("0 / %d" % int(result.amount), 12, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(progress)

	var card_center := CenterContainer.new()
	card_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(card_center)
	var card_view := CreatureCardScene.new()
	card_view.custom_minimum_size = Vector2(270, 397)
	card_view.show_quantity = false
	card_center.add_child(card_view)

	var status := _label("Touchez le bouton pour révéler la première carte.", 11, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(status)

	var summary := VBoxContainer.new()
	summary.visible = false
	summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary.alignment = BoxContainer.ALIGNMENT_CENTER
	summary.add_theme_constant_override("separation", 12)
	content.add_child(summary)
	var discovery_count := int(result.newly_discovered.size())
	var discovery_text := "%d nouvelle%s carte%s découverte%s" % [discovery_count, "s" if discovery_count > 1 else "", "s" if discovery_count > 1 else "", "s" if discovery_count > 1 else ""]
	summary.add_child(_label(discovery_text, 17, COLOR_CYAN, HORIZONTAL_ALIGNMENT_CENTER))
	var counts := GridContainer.new()
	counts.columns = 2
	counts.add_theme_constant_override("h_separation", 10)
	counts.add_theme_constant_override("v_separation", 10)
	summary.add_child(counts)
	for rarity in CardDatabase.RARITY_ORDER:
		var amount := int(result.rarity_counts[rarity])
		if amount <= 0:
			continue
		var rarity_data: Dictionary = CardDatabase.RARITIES[rarity]
		var count_label := _label("%s\n×%s" % [rarity_data.label, CardDatabase.format_number(amount)], 14, rarity_data.glow, HORIZONTAL_ALIGNMENT_CENTER)
		count_label.custom_minimum_size = Vector2(180, 62)
		counts.add_child(count_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 9)
	content.add_child(actions)
	var skip := Button.new()
	skip.text = "TOUT RÉVÉLER"
	skip.custom_minimum_size = Vector2(140, 58)
	skip.add_theme_font_size_override("font_size", 11)
	_style_action_button(skip, COLOR_MUTED, false)
	actions.add_child(skip)
	var next := Button.new()
	next.text = "RÉVÉLER LA PREMIÈRE"
	next.custom_minimum_size.y = 58
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next.add_theme_font_size_override("font_size", 12)
	_style_action_button(next, COLOR_ACCENT, true)
	actions.add_child(next)

	var state := {
		"result": result,
		"pulls": result.pulls,
		"index": -1,
		"summary_shown": false,
		"seen_new": {},
		"title": title,
		"progress": progress,
		"status": status,
		"card_center": card_center,
		"card": card_view,
		"summary": summary,
		"skip": skip,
		"next": next
	}
	overlay.set_meta("reveal_state", state)
	next.pressed.connect(_advance_reveal.bind(overlay))
	skip.pressed.connect(_skip_reveal.bind(overlay))
	overlay.modulate.a = 0.0
	create_tween().tween_property(overlay, "modulate:a", 1.0, 0.18)
	_advance_reveal(overlay)

func _advance_reveal(overlay: Control) -> void:
	if not is_instance_valid(overlay) or not overlay.has_meta("reveal_state"):
		return
	var state: Dictionary = overlay.get_meta("reveal_state")
	if bool(state.summary_shown):
		_close_overlay(overlay)
		return
	state.index = int(state.index) + 1
	var pulls: Array = state.pulls
	if int(state.index) >= pulls.size():
		_show_reveal_summary(overlay)
		return

	var card_id := str(pulls[int(state.index)])
	var card := CardDatabase.get_card(card_id)
	var rarity_data: Dictionary = CardDatabase.RARITIES[card.rarity]
	var card_view: CreatureCard = state.card
	card_view.visible = true
	card_view.configure(card, 1, false, false)
	state.title.text = card.name
	state.title.add_theme_color_override("font_color", rarity_data.glow)
	state.progress.text = "CARTE %d / %d" % [int(state.index) + 1, pulls.size()]
	var is_new: bool = result_has_new_card(state.result, card_id) and not state.seen_new.has(card_id)
	if is_new:
		state.seen_new[card_id] = true
		state.status.text = "NOUVELLE DÉCOUVERTE  ·  %s" % rarity_data.label
		state.status.add_theme_color_override("font_color", COLOR_CYAN)
	else:
		state.status.text = "%s  ·  Exemplaire supplémentaire" % rarity_data.label
		state.status.add_theme_color_override("font_color", rarity_data.glow)
	state.next.text = "VOIR LE RÉCAPITULATIF" if int(state.index) == pulls.size() - 1 else "RÉVÉLER LA SUIVANTE"
	_animate_single_reveal(card_view)

func result_has_new_card(result: Dictionary, card_id: String) -> bool:
	return result.newly_discovered.has(card_id)

func _skip_reveal(overlay: Control) -> void:
	if not is_instance_valid(overlay) or not overlay.has_meta("reveal_state"):
		return
	_show_reveal_summary(overlay)

func _show_reveal_summary(overlay: Control) -> void:
	var state: Dictionary = overlay.get_meta("reveal_state")
	state.summary_shown = true
	state.card_center.visible = false
	state.status.visible = false
	state.summary.visible = true
	state.title.text = "%s CARTES AJOUTÉES" % CardDatabase.format_number(int(state.result.amount))
	state.title.add_theme_color_override("font_color", COLOR_TEXT)
	state.progress.text = "OUVERTURE TERMINÉE"
	state.skip.visible = false
	state.next.text = "CONTINUER"

func _animate_single_reveal(card: Control) -> void:
	card.scale = Vector2(0.58, 0.58)
	card.rotation = -0.075
	call_deferred("_run_single_reveal_tween", card)

func _run_single_reveal_tween(card: Control) -> void:
	if not is_instance_valid(card):
		return
	card.pivot_offset = card.size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "scale", Vector2.ONE, 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "rotation", 0.0, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _show_card_details(card: Dictionary) -> void:
	var owned := GameState.get_card_count(card.id)
	var locked := not GameState.is_card_discovered(str(card.id))
	var rarity_data: Dictionary = CardDatabase.RARITIES[card.rarity]
	var overlay := _new_overlay()
	var panel := _overlay_panel(456, 850)
	overlay.get_node("Center").add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 9)
	panel.add_child(content)
	var card_rate := CardDatabase.get_card_drop_rate(str(card.id))
	var rarity_header := "ULTIME  ·  OBJECTIF PERMANENT  ·  LIÉE AU COMPTE" if str(card.rarity) == "ultimate" else "%s  ·  RANG %s  ·  CARTE %s" % [rarity_data.label, CardDatabase.format_rate(float(rarity_data.drop_rate)), CardDatabase.format_rate(card_rate)]
	var rarity_label := _label(rarity_header, 10, rarity_data.glow, HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(rarity_label)

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(center)
	var card_view := CreatureCardScene.new()
	card_view.custom_minimum_size = Vector2(285, 418)
	center.add_child(card_view)
	card_view.configure(card, owned, locked, false)

	var lore_panel := PanelContainer.new()
	lore_panel.add_theme_stylebox_override("panel", _box(Color(0.04, 0.05, 0.115, 0.95), 14, Color(rarity_data.color, 0.25), 1, 10))
	content.add_child(lore_panel)
	var lore := _label("“%s”" % card.lore, 12, Color("cbd2e6"), HORIZONTAL_ALIGNMENT_CENTER)
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_panel.add_child(lore)

	var status_text := "NON DÉCOUVERTE" if locked else ("DÉCOUVERTE · AUCUN EXEMPLAIRE DISPONIBLE" if owned <= 0 else "%s exemplaire%s possédé%s" % [CardDatabase.format_number(owned), "s" if owned > 1 else "", "s" if owned > 1 else ""])
	var status := _label(status_text, 12, Color("ffb0c0") if locked else rarity_data.glow, HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(status)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 7)
	content.add_child(actions)
	if owned > 0 and bool(card.get("tradable", true)) and str(card.rarity) != "ultimate":
		var sell := Button.new()
		sell.text = "VENDRE"
		sell.custom_minimum_size.y = 55
		sell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sell.add_theme_font_size_override("font_size", 10)
		_style_action_button(sell, Color("ffd266"), false)
		sell.pressed.connect(_open_sell_from_details.bind(card, overlay))
		actions.add_child(sell)
	if GameState.get_recyclable_count(str(card.id)) > 0:
		var recycle := Button.new()
		recycle.text = "RECYCLER"
		recycle.custom_minimum_size.y = 55
		recycle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		recycle.add_theme_font_size_override("font_size", 10)
		_style_action_button(recycle, Color("73d6a4"), false)
		recycle.pressed.connect(_open_recycle_from_details.bind(card, overlay))
		actions.add_child(recycle)
	var close := Button.new()
	close.text = "FERMER"
	close.custom_minimum_size.y = 55
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close.add_theme_font_size_override("font_size", 13)
	_style_action_button(close, rarity_data.color, true)
	close.pressed.connect(_close_overlay.bind(overlay))
	actions.add_child(close)
	_animate_overlay(overlay, card_view)

func _open_recycle_from_details(card: Dictionary, details_overlay: Control) -> void:
	_close_overlay(details_overlay)
	_show_recycle_overlay(card)

func _show_recycle_overlay(card: Dictionary) -> void:
	var recyclable := GameState.get_recyclable_count(str(card.id))
	if recyclable <= 0:
		_show_toast("Aucun doublon recyclable.", Color("ff8b9d"))
		return
	var rarity_data: Dictionary = CardDatabase.RARITIES[card.rarity]
	var unit_value := GameState.get_recycle_value(str(card.id))
	var overlay := _new_overlay()
	var panel := _overlay_panel(430, 620)
	overlay.get_node("Center").add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	content.add_child(_label("RECYCLER LES DOUBLONS", 22, Color("73d6a4"), HORIZONTAL_ALIGNMENT_CENTER))
	content.add_child(_label(str(card.name), 17, rarity_data.glow, HORIZONTAL_ALIGNMENT_CENTER))
	var preview_center := CenterContainer.new()
	preview_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(preview_center)
	preview_center.add_child(_mini_art(card.art, rarity_data.color))
	content.add_child(_label("%s doublon%s disponible%s · 1 exemplaire protégé" % [CardDatabase.format_number(recyclable), "s" if recyclable > 1 else "", "s" if recyclable > 1 else ""], 11, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER))

	var quantity_row := HBoxContainer.new()
	content.add_child(quantity_row)
	var quantity_title := _label("QUANTITÉ", 12, COLOR_TEXT)
	quantity_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quantity_row.add_child(quantity_title)
	var quantity := SpinBox.new()
	quantity.min_value = 1
	quantity.max_value = recyclable
	quantity.value = 1
	quantity.allow_greater = false
	quantity.custom_minimum_size = Vector2(170, 48)
	_style_spin_box(quantity, COLOR_GREEN)
	quantity_row.add_child(quantity)
	var reward_label := _label("GAIN : %s POUSSIÈRE%s" % [CardDatabase.format_number(unit_value), "S" if unit_value > 1 else ""], 14, Color("73d6a4"), HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(reward_label)
	quantity.value_changed.connect(_update_recycle_yield.bind(reward_label, unit_value))
	var warning := _label("Le recyclage est définitif. La première copie ne peut jamais être recyclée.", 10, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(warning)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 9)
	content.add_child(actions)
	var cancel := Button.new()
	cancel.text = "ANNULER"
	cancel.custom_minimum_size.y = 54
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_action_button(cancel, COLOR_MUTED, false)
	cancel.pressed.connect(_close_overlay.bind(overlay))
	actions.add_child(cancel)
	var confirm := Button.new()
	confirm.text = "RECYCLER"
	confirm.custom_minimum_size.y = 54
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_action_button(confirm, Color("73d6a4"), true)
	confirm.pressed.connect(_submit_recycle.bind(str(card.id), quantity, overlay))
	actions.add_child(confirm)

func _update_recycle_yield(value: float, label: Label, unit_value: int) -> void:
	var total := int(value) * unit_value
	label.text = "GAIN : %s POUSSIÈRE%s" % [CardDatabase.format_number(total), "S" if total > 1 else ""]

func _submit_recycle(card_id: String, quantity: SpinBox, overlay: Control) -> void:
	var result := GameState.recycle_duplicates(card_id, int(quantity.value))
	if not result.ok:
		_show_toast(result.error, Color("ff8b9d"))
		return
	_close_overlay(overlay)
	_show_toast("%s doublon%s recyclé%s : +%s poussières." % [CardDatabase.format_number(int(result.amount)), "s" if int(result.amount) > 1 else "", "s" if int(result.amount) > 1 else "", CardDatabase.format_number(int(result.reward))], Color("73d6a4"))

func _open_sell_from_details(card: Dictionary, details_overlay: Control) -> void:
	_close_overlay(details_overlay)
	_show_sell_overlay(card)

func _show_sell_overlay(card: Dictionary) -> void:
	var owned := GameState.get_card_count(card.id)
	if owned <= 0:
		_show_toast("Vous ne possédez pas cette carte.", Color("ff8b9d"))
		return
	var rarity_data: Dictionary = CardDatabase.RARITIES[card.rarity]
	var overlay := _new_overlay()
	var panel := _overlay_panel(430, 650)
	overlay.get_node("Center").add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	content.add_child(_label("METTRE EN VENTE", 23, Color("ffd266"), HORIZONTAL_ALIGNMENT_CENTER))
	content.add_child(_label(card.name, 18, rarity_data.glow, HORIZONTAL_ALIGNMENT_CENTER))

	var preview_center := CenterContainer.new()
	preview_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(preview_center)
	preview_center.add_child(_mini_art(card.art, rarity_data.color))
	content.add_child(_label("Possédées : %s" % CardDatabase.format_number(owned), 11, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER))

	var quantity_row := HBoxContainer.new()
	content.add_child(quantity_row)
	var quantity_label := _label("QUANTITÉ", 12, COLOR_TEXT)
	quantity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quantity_row.add_child(quantity_label)
	var quantity := SpinBox.new()
	quantity.min_value = 1
	quantity.max_value = owned
	quantity.value = 1
	quantity.allow_greater = false
	quantity.custom_minimum_size = Vector2(160, 48)
	_style_spin_box(quantity, COLOR_GOLD)
	quantity_row.add_child(quantity)

	var price_row := HBoxContainer.new()
	content.add_child(price_row)
	var price_label := _label("PRIX PAR CARTE", 12, COLOR_TEXT)
	price_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	price_row.add_child(price_label)
	var price := SpinBox.new()
	price.min_value = 1
	price.max_value = 10000000
	var defaults := {"common": 75, "rare": 2500, "epic": 25000, "legendary": 250000, "unique": 1000000}
	price.value = int(defaults[card.rarity])
	price.step = 5
	price.suffix = " jetons"
	price.allow_greater = false
	price.custom_minimum_size = Vector2(200, 48)
	_style_spin_box(price, COLOR_GOLD)
	price_row.add_child(price)

	var warning := _label("La carte est retirée de l’inventaire et placée en séquestre local. L’argent réel reste désactivé sans serveur sécurisé.", 10, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(warning)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 9)
	content.add_child(actions)
	var cancel := Button.new()
	cancel.text = "ANNULER"
	cancel.custom_minimum_size.y = 54
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_action_button(cancel, COLOR_MUTED, false)
	cancel.pressed.connect(_close_overlay.bind(overlay))
	actions.add_child(cancel)
	var confirm := Button.new()
	confirm.text = "PUBLIER L’OFFRE"
	confirm.custom_minimum_size.y = 54
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_action_button(confirm, Color("ffd266"), true)
	confirm.pressed.connect(_submit_listing.bind(str(card.id), quantity, price, overlay))
	actions.add_child(confirm)

func _submit_listing(card_id: String, quantity: SpinBox, price: SpinBox, overlay: Control) -> void:
	var result := GameState.create_market_listing(card_id, int(quantity.value), int(price.value))
	if not result.ok:
		_show_toast(result.error, Color("ff8b9d"))
		return
	_close_overlay(overlay)
	_switch_page("market")
	_show_toast("Offre publiée sur le marché.", Color("ffd266"))

func _on_buy_listing(listing_id: String) -> void:
	var result := GameState.buy_market_listing(listing_id)
	if not result.ok:
		_show_toast(result.error, Color("ff8b9d"))
		return
	_show_toast("Achat effectué : carte ajoutée à la collection.", Color("78e6a0"))

func _on_cancel_listing(listing_id: String) -> void:
	var result := GameState.cancel_market_listing(listing_id)
	if not result.ok:
		_show_toast(result.error, Color("ff8b9d"))
		return
	_show_toast("Offre annulée : carte rendue à la collection.", COLOR_CYAN)

func _show_reward_card(card: Dictionary, title_text: String, subtitle_text: String) -> void:
	var rarity_data: Dictionary = CardDatabase.RARITIES[card.rarity]
	var overlay := _new_overlay()
	var panel := _overlay_panel(440, 760)
	overlay.get_node("Center").add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)
	content.add_child(_label(title_text, 25, rarity_data.glow, HORIZONTAL_ALIGNMENT_CENTER))
	var subtitle := _label(subtitle_text, 11, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(subtitle)

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(center)
	var card_view := CreatureCardScene.new()
	card_view.custom_minimum_size = Vector2(270, 397)
	center.add_child(card_view)
	card_view.configure(card, 1, false, false)

	var close := Button.new()
	close.text = "CONTINUER"
	close.custom_minimum_size.y = 56
	close.add_theme_font_size_override("font_size", 13)
	_style_action_button(close, rarity_data.color, true)
	close.pressed.connect(_close_overlay.bind(overlay))
	content.add_child(close)
	_animate_overlay(overlay, card_view)

func _new_overlay() -> ColorRect:
	var overlay := ColorRect.new()
	overlay.name = "Overlay"
	overlay.color = Color(0.008, 0.012, 0.035, 0.93)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	add_child(overlay)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 20
	center.offset_right = -20
	center.offset_top = 20
	center.offset_bottom = -20
	overlay.add_child(center)
	return overlay

func _overlay_panel(min_width: float, min_height: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(min_width, min_height)
	var overlay_style := _box(Color(0.055, 0.072, 0.155, 1.0), 30, Color(0.58, 0.48, 0.98, 0.68), 2, 20)
	overlay_style.shadow_color = Color(0.0, 0.0, 0.0, 0.58)
	overlay_style.shadow_size = 14
	overlay_style.shadow_offset = Vector2(0, 7)
	panel.add_theme_stylebox_override("panel", overlay_style)
	return panel

func _animate_overlay(overlay: Control, card: Control) -> void:
	overlay.modulate = Color(1, 1, 1, 0)
	card.scale = Vector2(0.55, 0.55)
	card.rotation = -0.09
	call_deferred("_run_overlay_tween", overlay, card)

func _run_overlay_tween(overlay: Control, card: Control) -> void:
	if not is_instance_valid(overlay) or not is_instance_valid(card):
		return
	card.pivot_offset = card.size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(overlay, "modulate:a", 1.0, 0.20)
	tween.tween_property(card, "scale", Vector2.ONE, 0.50).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "rotation", 0.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _close_overlay(overlay: Control) -> void:
	if not is_instance_valid(overlay):
		return
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 0.16)
	tween.finished.connect(overlay.queue_free)

func _show_floating_gain(amount: int) -> void:
	if _crate_view == null:
		return
	var gain := _label("+%d" % amount, 25, COLOR_CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	gain.custom_minimum_size = Vector2(120, 40)
	gain.z_index = 50
	gain.add_theme_constant_override("outline_size", 7)
	gain.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.09, 0.95))
	add_child(gain)
	var global_center := _crate_view.get_global_rect().get_center()
	gain.position = global_center - get_global_rect().position - Vector2(60, 20)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(gain, "position:y", gain.position.y - 90.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(gain, "modulate:a", 0.0, 0.65).set_delay(0.12)
	tween.finished.connect(gain.queue_free)

func _show_toast(message: String, accent: Color) -> void:
	var toast := PanelContainer.new()
	toast.custom_minimum_size = Vector2(390, 54)
	toast.anchor_left = 0.5
	toast.anchor_right = 0.5
	toast.anchor_top = 0.84
	toast.anchor_bottom = 0.84
	toast.offset_left = -195
	toast.offset_right = 195
	toast.offset_top = -27
	toast.offset_bottom = 27
	toast.add_theme_stylebox_override("panel", _box(Color(0.055, 0.06, 0.13, 0.98), 18, accent, 2, 10))
	toast.z_index = 200
	add_child(toast)
	var label := _label(message, 12, accent, HORIZONTAL_ALIGNMENT_CENTER)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.add_child(label)
	toast.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(toast, "modulate:a", 1.0, 0.16)
	tween.tween_interval(1.8)
	tween.tween_property(toast, "modulate:a", 0.0, 0.22)
	tween.finished.connect(toast.queue_free)

func _style_line_edit(input: LineEdit, accent: Color) -> void:
	input.add_theme_font_override("font", _font_semibold)
	input.add_theme_font_size_override("font_size", 14)
	input.add_theme_color_override("font_color", COLOR_TEXT)
	input.add_theme_color_override("font_placeholder_color", Color(COLOR_MUTED, 0.70))
	input.add_theme_color_override("caret_color", accent)
	input.add_theme_stylebox_override("normal", _box(Color(0.055, 0.075, 0.15, 0.98), 16, Color(0.32, 0.38, 0.58, 0.68), 1, 12))
	input.add_theme_stylebox_override("focus", _box(Color(0.065, 0.085, 0.175, 1.0), 16, accent, 2, 11))
	input.add_theme_stylebox_override("read_only", _box(Color(0.045, 0.055, 0.11, 0.9), 16, Color(0.22, 0.25, 0.35, 0.7), 1, 12))

func _style_option_button(button: OptionButton, accent: Color) -> void:
	button.add_theme_font_override("font", _font_bold)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _box(Color(0.065, 0.085, 0.17, 0.98), 16, Color(accent, 0.62), 1, 10))
	button.add_theme_stylebox_override("hover", _box(Color(0.085, 0.105, 0.205, 1.0), 16, accent, 2, 9))
	button.add_theme_stylebox_override("pressed", _box(Color(0.05, 0.065, 0.14, 1.0), 16, accent, 2, 9))
	button.add_theme_stylebox_override("focus", _box(Color.TRANSPARENT, 16, accent, 2, 9))

func _style_spin_box(spin: SpinBox, accent: Color) -> void:
	var input := spin.get_line_edit()
	input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_line_edit(input, accent)

func _style_action_button(button: Button, accent: Color, filled: bool) -> void:
	var background := Color(accent.darkened(0.54), 0.98) if filled else Color(0.055, 0.085, 0.165, 0.98)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", _font_bold)
	button.add_theme_font_size_override("font_size", maxi(12, button.get_theme_font_size("font_size")))
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.56, 0.60, 0.72, 0.72))
	var normal := _box(background, 18, Color(accent, 0.86), 2, 9)
	normal.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
	normal.shadow_size = 5
	normal.shadow_offset = Vector2(0, 3)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", _box(background.lightened(0.10), 18, accent.lightened(0.18), 2, 9))
	button.add_theme_stylebox_override("pressed", _box(background.darkened(0.10), 18, accent, 2, 9))
	button.add_theme_stylebox_override("focus", _box(Color.TRANSPARENT, 18, Color(accent, 0.95), 3, 8))
	button.add_theme_stylebox_override("disabled", _box(Color(0.055, 0.065, 0.115, 0.80), 18, Color(0.28, 0.30, 0.40, 0.70), 1, 9))

func _chip(text: String, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var chip_style := _box(Color(accent.darkened(0.68), 0.88), 14, Color(accent, 0.62), 1, 0)
	chip_style.content_margin_left = 11
	chip_style.content_margin_right = 11
	chip_style.content_margin_top = 5
	chip_style.content_margin_bottom = 5
	panel.add_theme_stylebox_override("panel", chip_style)
	var value_label := _label(text, 10, accent, HORIZONTAL_ALIGNMENT_CENTER)
	panel.add_child(value_label)
	panel.set_meta("value_label", value_label)
	return panel

func _label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FontKit.readable_size(font_size))
	if font_size >= 20:
		label.add_theme_font_override("font", _font_extrabold)
	elif font_size >= 14:
		label.add_theme_font_override("font", _font_bold)
	elif font_size >= 10:
		label.add_theme_font_override("font", _font_semibold)
	else:
		label.add_theme_font_override("font", _font_regular)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _set_margins(container: MarginContainer, left: int, right: int, top: int, bottom: int) -> void:
	container.add_theme_constant_override("margin_left", left)
	container.add_theme_constant_override("margin_right", right)
	container.add_theme_constant_override("margin_top", top)
	container.add_theme_constant_override("margin_bottom", bottom)

func _box(background: Color, radius: int, border: Color = Color.TRANSPARENT, border_width: int = 0, content_margin: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	if border_width > 0:
		style.border_color = border
		style.border_width_left = border_width
		style.border_width_top = border_width
		style.border_width_right = border_width
		style.border_width_bottom = border_width
	if content_margin > 0:
		style.content_margin_left = content_margin
		style.content_margin_right = content_margin
		style.content_margin_top = content_margin
		style.content_margin_bottom = content_margin
	return style

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("farm") and _current_page == "farm":
		_on_farm_pressed()

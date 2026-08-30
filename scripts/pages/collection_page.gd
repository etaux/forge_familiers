class_name CollectionPage
extends MarginContainer

const CreatureCardScene := preload("res://scripts/card_view.gd")
const PAGE_SIZE := 12

signal card_pressed(card: Dictionary)

var kit: UIKit
var title_label: Label
var hint_label: Label
var progress_label: Label
var total_label: Label
var search: LineEdit
var filter: OptionButton
var grid: GridContainer
var scroll: ScrollContainer
var page_label: Label
var prev_button: Button
var next_button: Button
var page := 0
var filtered_ids: Array[String] = []
var views: Dictionary = {}

func setup(ui: UIKit) -> void:
	kit = ui
	kit.set_margins(self, 14, 14, 14, 12)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	add_child(content)

	var heading := HBoxContainer.new()
	content.add_child(heading)
	var heading_text := VBoxContainer.new()
	heading_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(heading_text)
	title_label = kit.label(Loc.t("collection"), 25, UIKit.COLOR_TEXT)
	heading_text.add_child(title_label)
	total_label = kit.label(Loc.t("owned_cards") % "0", 11, UIKit.COLOR_MUTED)
	heading_text.add_child(total_label)
	var progress_chip := kit.chip("0 / %d" % CardDatabase.CARD_ORDER.size(), UIKit.COLOR_CYAN)
	progress_label = progress_chip.get_meta("value_label")
	heading.add_child(progress_chip)

	hint_label = kit.label(Loc.t("collection_hint"), 12, UIKit.COLOR_MUTED)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint_label)

	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 8)
	content.add_child(filters)
	search = LineEdit.new()
	search.placeholder_text = Loc.t("search_creature")
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.custom_minimum_size.y = 50
	kit.style_line_edit(search, Color("6fa8ff"))
	search.text_changed.connect(func(_t: String) -> void: page = 0; rebuild())
	filters.add_child(search)
	filter = OptionButton.new()
	filter.custom_minimum_size = Vector2(145, 50)
	kit.style_option_button(filter, Color("6fa8ff"))
	_fill_rarity_filter()
	filter.item_selected.connect(func(_i: int) -> void: page = 0; rebuild())
	filters.add_child(filter)

	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 11)
	grid.add_theme_constant_override("v_separation", 13)
	scroll.add_child(grid)

	var pagination := HBoxContainer.new()
	pagination.add_theme_constant_override("separation", 8)
	content.add_child(pagination)
	prev_button = Button.new()
	prev_button.text = Loc.t("prev_page")
	prev_button.custom_minimum_size = Vector2(130, 48)
	kit.style_action_button(prev_button, Color("6fa8ff"), false)
	prev_button.pressed.connect(func() -> void: page = maxi(0, page - 1); rebuild())
	pagination.add_child(prev_button)
	page_label = kit.label("PAGE 1 / 1", 11, UIKit.COLOR_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pagination.add_child(page_label)
	next_button = Button.new()
	next_button.text = Loc.t("next_page")
	next_button.custom_minimum_size = Vector2(130, 48)
	kit.style_action_button(next_button, Color("6fa8ff"), false)
	next_button.pressed.connect(func() -> void: page += 1; rebuild())
	pagination.add_child(next_button)
	rebuild()

func apply_locale() -> void:
	if title_label:
		title_label.text = Loc.t("collection")
	if hint_label:
		hint_label.text = Loc.t("collection_hint")
	if search:
		search.placeholder_text = Loc.t("search_creature")
	if prev_button:
		prev_button.text = Loc.t("prev_page")
	if next_button:
		next_button.text = Loc.t("next_page")
	_fill_rarity_filter()
	rebuild()

func _fill_rarity_filter() -> void:
	if filter == null:
		return
	var selected := filter.selected
	filter.set_block_signals(true)
	filter.clear()
	filter.add_item(Loc.t("all_filter"))
	for rarity in CardDatabase.RARITY_ORDER:
		filter.add_item(Loc.rarity(str(rarity)))
	if selected >= 0 and selected < filter.item_count:
		filter.select(selected)
	filter.set_block_signals(false)

func rebuild() -> void:
	if grid == null:
		return
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	views.clear()
	filtered_ids.clear()
	var query := search.text.strip_edges().to_lower()
	var rarity_filter := ""
	if filter.selected > 0:
		rarity_filter = CardDatabase.RARITY_ORDER[filter.selected - 1]
	for card_id in CardDatabase.CARD_ORDER:
		var card := CardDatabase.get_card(card_id)
		var matches_name: bool = query.is_empty() or str(card.name).to_lower().contains(query) or str(card.title).to_lower().contains(query)
		var matches_rarity: bool = rarity_filter.is_empty() or str(card.rarity) == rarity_filter
		if matches_name and matches_rarity:
			filtered_ids.append(card_id)
	var total_pages := maxi(1, ceili(float(filtered_ids.size()) / float(PAGE_SIZE)))
	page = clampi(page, 0, total_pages - 1)
	var start_index := page * PAGE_SIZE
	var end_index := mini(start_index + PAGE_SIZE, filtered_ids.size())
	for index in range(start_index, end_index):
		var card_id := filtered_ids[index]
		var card := CardDatabase.get_card(card_id)
		var view := CreatureCardScene.new()
		view.custom_minimum_size = Vector2(210, 310)
		view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(view)
		view.configure(card, GameState.get_card_count(card_id), not GameState.is_card_discovered(card_id), true)
		view.card_pressed.connect(func(data: Dictionary) -> void: card_pressed.emit(data))
		views[card_id] = view
	if filtered_ids.is_empty():
		var empty := kit.label(Loc.t("no_cards_search"), 12, UIKit.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		empty.custom_minimum_size = Vector2(430, 120)
		grid.add_child(empty)
	page_label.text = "PAGE %d / %d  ·  %s CARTES" % [page + 1, total_pages, CardDatabase.format_number(filtered_ids.size())]
	prev_button.disabled = page <= 0
	next_button.disabled = page >= total_pages - 1
	if scroll:
		scroll.scroll_vertical = 0
	refresh_counts()

func refresh_counts() -> void:
	if progress_label:
		progress_label.text = "%d / %d" % [GameState.get_discovered_count(), CardDatabase.CARD_ORDER.size()]
	if total_label:
		total_label.text = Loc.t("owned_cards") % CardDatabase.format_number(GameState.get_total_cards())
	for card_id in views:
		var view: CreatureCard = views[card_id]
		view.set_quantity(GameState.get_card_count(card_id), GameState.is_card_discovered(str(card_id)))

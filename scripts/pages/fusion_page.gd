class_name FusionPage
extends MarginContainer

const PAGE_SIZE := 8
const FUSION_RARITIES: Array[String] = ["common", "rare", "epic", "legendary"]

signal fuse_pressed(card_id: String)
signal fuse_all_pressed

var kit: UIKit
var rows: Dictionary = {}
var title_label: Label
var costs_label: Label
var fuse_all_button: Button
var hint_label: Label
var search: LineEdit
var filter: OptionButton
var scroll: ScrollContainer
var recipe_list: VBoxContainer
var page_label: Label
var prev_button: Button
var next_button: Button
var page := 0
var filtered_ids: Array[String] = []

func setup(ui: UIKit) -> void:
	kit = ui
	kit.set_margins(self, 14, 14, 14, 12)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 9)
	add_child(content)

	var heading := HBoxContainer.new()
	content.add_child(heading)
	var title_group := VBoxContainer.new()
	title_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title_group)
	title_label = kit.label(Loc.t("fusion_title"), 24, UIKit.COLOR_TEXT)
	title_group.add_child(title_label)
	hint_label = kit.label(Loc.t("fusion_hint"), 11, UIKit.COLOR_MUTED)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_group.add_child(hint_label)
	fuse_all_button = Button.new()
	fuse_all_button.text = Loc.t("fuse_all")
	fuse_all_button.custom_minimum_size = Vector2(112, 56)
	fuse_all_button.add_theme_font_size_override("font_size", 11)
	kit.style_action_button(fuse_all_button, UIKit.COLOR_ACCENT, true)
	fuse_all_button.pressed.connect(func() -> void: fuse_all_pressed.emit())
	heading.add_child(fuse_all_button)

	var info_panel := PanelContainer.new()
	info_panel.add_theme_stylebox_override("panel", kit.box(Color(0.08, 0.07, 0.17, 0.95), 15, Color(UIKit.COLOR_ACCENT, 0.35), 1, 10))
	content.add_child(info_panel)
	costs_label = kit.label(Loc.t("fusion_costs"), 11, UIKit.COLOR_ACCENT_LIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	costs_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_panel.add_child(costs_label)

	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 8)
	content.add_child(filters)
	search = LineEdit.new()
	search.placeholder_text = Loc.t("search_recipe")
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.custom_minimum_size.y = 48
	kit.style_line_edit(search, Color("b983ff"))
	search.text_changed.connect(func(_t: String) -> void: page = 0; rebuild())
	filters.add_child(search)
	filter = OptionButton.new()
	filter.custom_minimum_size = Vector2(145, 48)
	kit.style_option_button(filter, Color("b983ff"))
	_fill_rarity_filter()
	filter.item_selected.connect(func(_i: int) -> void: page = 0; rebuild())
	filters.add_child(filter)

	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	recipe_list = VBoxContainer.new()
	recipe_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipe_list.add_theme_constant_override("separation", 9)
	scroll.add_child(recipe_list)

	var pagination := HBoxContainer.new()
	pagination.add_theme_constant_override("separation", 8)
	content.add_child(pagination)
	prev_button = Button.new()
	prev_button.text = Loc.t("prev_page")
	prev_button.custom_minimum_size = Vector2(130, 48)
	kit.style_action_button(prev_button, Color("b983ff"), false)
	prev_button.pressed.connect(func() -> void: page = maxi(0, page - 1); rebuild())
	pagination.add_child(prev_button)
	page_label = kit.label("PAGE 1 / 1", 11, UIKit.COLOR_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pagination.add_child(page_label)
	next_button = Button.new()
	next_button.text = Loc.t("next_page")
	next_button.custom_minimum_size = Vector2(130, 48)
	kit.style_action_button(next_button, Color("b983ff"), false)
	next_button.pressed.connect(func() -> void: page += 1; rebuild())
	pagination.add_child(next_button)
	rebuild()

func apply_locale() -> void:
	if title_label:
		title_label.text = Loc.t("fusion_title")
	if hint_label:
		hint_label.text = Loc.t("fusion_hint")
	if costs_label:
		costs_label.text = Loc.t("fusion_costs")
	if fuse_all_button:
		fuse_all_button.text = Loc.t("fuse_all")
	if search:
		search.placeholder_text = Loc.t("search_recipe")
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
	for rarity in FUSION_RARITIES:
		filter.add_item(Loc.rarity(str(rarity)))
	if selected >= 0 and selected < filter.item_count:
		filter.select(selected)
	filter.set_block_signals(false)

func rebuild() -> void:
	if recipe_list == null:
		return
	for child in recipe_list.get_children():
		recipe_list.remove_child(child)
		child.queue_free()
	rows.clear()
	filtered_ids.clear()
	var query := search.text.strip_edges().to_lower()
	var rarity_filter := ""
	if filter.selected > 0:
		rarity_filter = FUSION_RARITIES[filter.selected - 1]
	for card_id in CardDatabase.CARD_ORDER:
		var card := CardDatabase.get_card(card_id)
		if CardDatabase.get_fusion_cost(str(card.rarity)) <= 0:
			continue
		var matches_name: bool = query.is_empty() or str(card.name).to_lower().contains(query) or str(card.title).to_lower().contains(query)
		var matches_rarity: bool = rarity_filter.is_empty() or str(card.rarity) == rarity_filter
		if matches_name and matches_rarity:
			filtered_ids.append(card_id)
	var total_pages := maxi(1, ceili(float(filtered_ids.size()) / float(PAGE_SIZE)))
	page = clampi(page, 0, total_pages - 1)
	var start_index := page * PAGE_SIZE
	var end_index := mini(start_index + PAGE_SIZE, filtered_ids.size())
	for index in range(start_index, end_index):
		_build_recipe(CardDatabase.get_card(filtered_ids[index]))
	if filtered_ids.is_empty():
		var empty := kit.label(Loc.t("no_recipes_search"), 12, UIKit.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		empty.custom_minimum_size.y = 120
		recipe_list.add_child(empty)
	page_label.text = Loc.t("page_recipes") % [page + 1, total_pages, CardDatabase.format_number(filtered_ids.size())]
	prev_button.disabled = page <= 0
	next_button.disabled = page >= total_pages - 1
	if scroll:
		scroll.scroll_vertical = 0
	refresh_rows()

func _build_recipe(source: Dictionary) -> void:
	var rarity: String = source.rarity
	var next_rarity := CardDatabase.get_next_rarity(rarity)
	var target := CardDatabase.get_card_for_rarity(next_rarity)
	var cost := CardDatabase.get_fusion_cost(rarity)
	var source_rarity: Dictionary = CardDatabase.RARITIES[rarity]
	var target_rarity: Dictionary = CardDatabase.RARITIES[next_rarity]
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 112
	panel.add_theme_stylebox_override("panel", kit.box(Color(0.055, 0.065, 0.135, 0.96), 18, Color(source_rarity.color, 0.35), 1, 9))
	recipe_list.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	row.add_child(kit.mini_art(source.art, source_rarity.color))
	var text_group := VBoxContainer.new()
	text_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_group.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(text_group)
	var recipe_name := kit.label("%s × %s" % [CardDatabase.format_number(cost), source.name], 12, source_rarity.glow)
	recipe_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text_group.add_child(recipe_name)
	text_group.add_child(kit.label(Loc.t("fusion_towards") % Loc.rarity(next_rarity), 9, target_rarity.glow))
	var count_label := kit.label(Loc.t("available_count") % ["0", CardDatabase.format_number(cost)], 10, UIKit.COLOR_MUTED)
	text_group.add_child(count_label)
	row.add_child(kit.mini_art(target.art, target_rarity.color))
	var button := Button.new()
	button.text = "FUSIONNER"
	button.custom_minimum_size = Vector2(96, 52)
	button.add_theme_font_size_override("font_size", 10)
	kit.style_action_button(button, target_rarity.color, true)
	button.pressed.connect(func() -> void: fuse_pressed.emit(str(source.id)))
	row.add_child(button)
	rows[source.id] = {"count": count_label, "button": button, "cost": cost}

func refresh_rows() -> void:
	for card_id in rows:
		var count := GameState.get_available_count(str(card_id))
		var row: Dictionary = rows[card_id]
		var cost := int(row.cost)
		row.count.text = Loc.t("available_count") % [CardDatabase.format_number(count), CardDatabase.format_number(cost)]
		row.button.disabled = count < cost
	if fuse_all_button:
		fuse_all_button.disabled = not _has_any()

func _has_any() -> bool:
	for card_id in CardDatabase.CARD_ORDER:
		var card := CardDatabase.get_card(card_id)
		var cost := CardDatabase.get_fusion_cost(str(card.rarity))
		if cost > 0 and GameState.get_available_count(card_id) >= cost:
			return true
	return false

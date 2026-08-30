class_name AlbumsPage
extends MarginContainer

signal habitat_claim(habitat_id: String)
signal album_claim(album_id: String)
signal album_open(album_id: String)
signal craft_pressed(amount: int)
signal ultimate_pressed

var kit: UIKit
var dust_label: Label
var collections_list: VBoxContainer
var craft_button: Button
var craft_x10: Button
var craft_x50: Button
var craft_max: Button
var ultimate_button: Button
var ultimate_progress: Label
var bonus_label: Label
var title_label: Label
var subtitle_label: Label
var habitats_heading: Label
var albums_heading: Label
var ultimate_title: Label

func setup(ui: UIKit) -> void:
	kit = ui
	kit.set_margins(self, 14, 14, 14, 12)
	clip_contents = true
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 9)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(content)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 8)
	content.add_child(heading)
	var title_group := VBoxContainer.new()
	title_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title_group)
	title_label = kit.label(Loc.t("habitats_albums"), 20, UIKit.COLOR_TEXT)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_group.add_child(title_label)
	subtitle_label = kit.label(Loc.t("habitats_hint"), 11, UIKit.COLOR_MUTED)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_group.add_child(subtitle_label)
	var dust_chip := kit.stat_chip(Loc.t("dust"), Color("73d6a4"))
	dust_label = dust_chip.get_meta("value_label")
	heading.add_child(dust_chip)

	var bonus_panel := PanelContainer.new()
	bonus_panel.add_theme_stylebox_override("panel", kit.box(Color(0.045, 0.085, 0.10, 0.96), 15, Color("73d6a4"), 1, 9))
	content.add_child(bonus_panel)
	bonus_label = kit.label("BONUS D’EXPÉDITION ACTIF : +%d %%" % GameState.get_expedition_bonus_percent(), 11, Color("8cf0b5"), HORIZONTAL_ALIGNMENT_CENTER)
	bonus_panel.add_child(bonus_label)

	var ultimate_panel := PanelContainer.new()
	var ultimate_style := kit.box(Color(0.095, 0.065, 0.025, 0.98), 18, Color("ffe08a"), 2, 11)
	ultimate_panel.add_theme_stylebox_override("panel", ultimate_style)
	content.add_child(ultimate_panel)
	var ultimate_row := HBoxContainer.new()
	ultimate_row.add_theme_constant_override("separation", 10)
	ultimate_panel.add_child(ultimate_row)
	var ultimate_text := VBoxContainer.new()
	ultimate_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ultimate_row.add_child(ultimate_text)
	ultimate_title = kit.label(Loc.t("ultimate"), 15, Color("fff0b0"))
	ultimate_text.add_child(ultimate_title)
	ultimate_progress = kit.label("0 / 0", 10, UIKit.COLOR_MUTED)
	ultimate_text.add_child(ultimate_progress)
	ultimate_button = Button.new()
	ultimate_button.text = Loc.t("see_goal")
	ultimate_button.custom_minimum_size = Vector2(132, 54)
	ultimate_button.add_theme_font_size_override("font_size", 11)
	kit.style_action_button(ultimate_button, Color("ffe08a"), true)
	ultimate_button.pressed.connect(func() -> void: ultimate_pressed.emit())
	ultimate_row.add_child(ultimate_button)

	craft_button = Button.new()
	craft_button.custom_minimum_size.y = 54
	craft_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	craft_button.add_theme_font_size_override("font_size", 11)
	craft_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kit.style_action_button(craft_button, Color("73d6a4"), true)
	craft_button.pressed.connect(func() -> void: craft_pressed.emit(1))
	content.add_child(craft_button)
	var batch := HBoxContainer.new()
	batch.add_theme_constant_override("separation", 8)
	content.add_child(batch)
	craft_x10 = _make_batch_button(Loc.t("craft_x10"), 10, batch)
	craft_x50 = _make_batch_button(Loc.t("craft_x50"), 50, batch)
	craft_max = _make_batch_button(Loc.t("craft_max"), -1, batch)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	collections_list = VBoxContainer.new()
	collections_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collections_list.add_theme_constant_override("separation", 9)
	scroll.add_child(collections_list)
	rebuild()

func _make_batch_button(caption: String, amount: int, parent: Control) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 46
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 12)
	kit.style_action_button(button, Color("73d6a4"), false)
	button.pressed.connect(func() -> void: craft_pressed.emit(amount))
	parent.add_child(button)
	return button

func apply_locale() -> void:
	if title_label:
		title_label.text = Loc.t("habitats_albums")
	if subtitle_label:
		subtitle_label.text = Loc.t("habitats_hint")
	if ultimate_title:
		ultimate_title.text = Loc.t("ultimate")
	if craft_x10:
		craft_x10.text = Loc.t("craft_x10")
	if craft_x50:
		craft_x50.text = Loc.t("craft_x50")
	if craft_max:
		craft_max.text = Loc.t("craft_max")
	rebuild()

func rebuild() -> void:

	if collections_list == null:
		return
	for child in collections_list.get_children():
		collections_list.remove_child(child)
		child.queue_free()
	if dust_label:
		dust_label.text = CardDatabase.format_number(GameState.dust)
	if bonus_label:
		bonus_label.text = Loc.t("expedition_bonus") % GameState.get_expedition_bonus_percent()
	_refresh_ultimate()
	if craft_button:
		craft_button.disabled = GameState.dust < GameState.CRAFT_MISSING_COMMON_COST
		var missing_count := 0
		for card in CardDatabase.get_cards_for_rarity("common"):
			if not GameState.is_card_discovered(str(card.id)):
				missing_count += 1
		var craft_kind := Loc.t("craft_missing") if missing_count > 0 else Loc.t("craft_random")
		craft_button.text = "%s\n%s" % [craft_kind, Loc.t("craft_cost") % CardDatabase.format_number(GameState.CRAFT_MISSING_COMMON_COST)]
		var can_craft := GameState.dust >= GameState.CRAFT_MISSING_COMMON_COST
		if craft_x10:
			craft_x10.disabled = GameState.get_max_craft_count() < 10
		if craft_x50:
			craft_x50.disabled = GameState.get_max_craft_count() < 50
		if craft_max:
			craft_max.disabled = not can_craft
			craft_max.text = "%s · %d" % [Loc.t("craft_max"), GameState.get_max_craft_count()] if can_craft else Loc.t("craft_max")

	habitats_heading = kit.label(Loc.t("habitats"), 17, Color("8cf0b5"))
	collections_list.add_child(habitats_heading)
	for habitat_id in CardDatabase.HABITAT_ORDER:
		var habitat := CardDatabase.get_habitat(habitat_id)
		var progress_data := GameState.get_habitat_progress(habitat_id)
		var claimed := GameState.claimed_habitats.has(habitat_id)
		var accent := Color(str(habitat.color))
		var panel := PanelContainer.new()
		panel.custom_minimum_size.y = 142
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.clip_contents = true
		panel.add_theme_stylebox_override("panel", kit.box(Color(0.05, 0.065, 0.125, 0.98), 18, Color(accent, 0.42), 1, 12))
		collections_list.add_child(panel)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		panel.add_child(row)
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(details)
		var habitat_title := kit.label(str(habitat.label), 14, accent)
		habitat_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_child(habitat_title)
		var description := kit.label(str(habitat.description), 10, UIKit.COLOR_MUTED)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.add_child(description)
		var progress_bar := ProgressBar.new()
		progress_bar.min_value = 0
		progress_bar.max_value = int(progress_data.total)
		progress_bar.value = int(progress_data.discovered)
		progress_bar.show_percentage = false
		progress_bar.custom_minimum_size.y = 11
		details.add_child(progress_bar)
		var habitat_meta := kit.label(Loc.t("creatures_bonus") % [int(progress_data.discovered), int(progress_data.total), int(habitat.expedition_bonus_percent)], 10, UIKit.COLOR_MUTED)
		habitat_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		habitat_meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.add_child(habitat_meta)
		var claim := Button.new()
		claim.custom_minimum_size = Vector2(108, 58)
		claim.clip_text = true
		claim.add_theme_font_size_override("font_size", 9)
		claim.text = Loc.t("restored") if claimed else (Loc.t("activate") % CardDatabase.format_number(int(habitat.reward_dust)) if bool(progress_data.complete) else "%d / %d" % [int(progress_data.discovered), int(progress_data.total)])
		claim.disabled = claimed or not bool(progress_data.complete)
		kit.style_action_button(claim, accent, true)
		claim.pressed.connect(func() -> void: habitat_claim.emit(str(habitat_id)))
		row.add_child(claim)

	albums_heading = kit.label(Loc.t("albums"), 17, Color("ffd266"))
	albums_heading.custom_minimum_size.y = 42
	collections_list.add_child(albums_heading)
	for album_id in CardDatabase.ALBUM_ORDER:
		var album := CardDatabase.get_album(album_id)
		var progress_data := GameState.get_album_progress(album_id)
		var claimed := GameState.claimed_albums.has(album_id)
		var panel := PanelContainer.new()
		panel.custom_minimum_size.y = 176
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.clip_contents = true
		panel.add_theme_stylebox_override("panel", kit.box(Color(0.07, 0.06, 0.125, 0.98), 18, Color(0.78, 0.58, 0.25, 0.42), 1, 12))
		collections_list.add_child(panel)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		panel.add_child(row)
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(details)
		var album_name := kit.label(str(album.label), 14, Color("ffd88a"))
		album_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		album_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.add_child(album_name)
		var album_desc := kit.label(str(album.description), 10, UIKit.COLOR_MUTED)
		album_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		album_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.add_child(album_desc)
		var progress_bar := ProgressBar.new()
		progress_bar.min_value = 0
		progress_bar.max_value = int(progress_data.total)
		progress_bar.value = int(progress_data.discovered)
		progress_bar.show_percentage = false
		progress_bar.custom_minimum_size.y = 11
		details.add_child(progress_bar)
		var reward := kit.label("%d / %d · %s E · %s J · %s P" % [int(progress_data.discovered), int(progress_data.total), CardDatabase.format_number(int(album.reward_essence)), CardDatabase.format_number(int(album.reward_coins)), CardDatabase.format_number(int(album.reward_dust))], 9, UIKit.COLOR_MUTED)
		reward.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reward.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.add_child(reward)
		var missing := _missing_names(album.card_ids)
		if not missing.is_empty():
			var missing_label := kit.label(Loc.t("missing") % missing, 9, Color("c2a7dc"))
			missing_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			missing_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			missing_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			details.add_child(missing_label)
		var album_actions := VBoxContainer.new()
		album_actions.custom_minimum_size.x = 108
		album_actions.add_theme_constant_override("separation", 7)
		row.add_child(album_actions)
		var consult := Button.new()
		consult.text = Loc.t("consult_cards") % int(progress_data.total)
		consult.custom_minimum_size = Vector2(108, 56)
		consult.clip_text = true
		consult.add_theme_font_size_override("font_size", 9)
		kit.style_action_button(consult, UIKit.COLOR_ACCENT, false)
		consult.pressed.connect(func() -> void: album_open.emit(str(album_id)))
		album_actions.add_child(consult)
		var claim := Button.new()
		claim.custom_minimum_size = Vector2(108, 50)
		claim.clip_text = true
		claim.add_theme_font_size_override("font_size", 9)
		claim.text = Loc.t("claimed") if claimed else (Loc.t("claim") if bool(progress_data.complete) else "%d / %d" % [int(progress_data.discovered), int(progress_data.total)])
		claim.disabled = claimed or not bool(progress_data.complete)
		kit.style_action_button(claim, Color("ffd266"), true)
		claim.pressed.connect(func() -> void: album_claim.emit(str(album_id)))
		album_actions.add_child(claim)

func _refresh_ultimate() -> void:
	if ultimate_button == null or ultimate_progress == null:
		return
	var progress := GameState.get_ultimate_goal_progress()
	if bool(progress.owned):
		ultimate_progress.text = Loc.t("ultimate_done")
		ultimate_progress.add_theme_color_override("font_color", Color("fff0b0"))
		ultimate_button.text = Loc.t("consult")
	elif bool(progress.ready):
		ultimate_progress.text = Loc.t("uniques_ready") % [int(progress.discovered), int(progress.total)]
		ultimate_progress.add_theme_color_override("font_color", Color("ffe08a"))
		ultimate_button.text = Loc.t("forge_aeternum")
	else:
		ultimate_progress.text = Loc.t("uniques_found") % [int(progress.discovered), int(progress.total)]
		ultimate_progress.add_theme_color_override("font_color", UIKit.COLOR_MUTED)
		ultimate_button.text = Loc.t("see_goal")

func _missing_names(card_ids: Array) -> String:
	var names: Array[String] = []
	for card_id in card_ids:
		if not GameState.is_card_discovered(str(card_id)):
			names.append(str(CardDatabase.get_card(str(card_id)).name))
			if names.size() >= 3:
				break
	return ", ".join(names)

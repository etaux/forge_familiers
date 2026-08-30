class_name FarmPage
extends MarginContainer

signal missions_pressed
signal expeditions_pressed
signal upgrades_pressed
signal crate_opened(result: Dictionary)
signal floating_gain(amount: int)

var kit: UIKit
var farm_world: FarmWorld
var crate_title_label: Label
var crate_detail_label: Label
var pity_label: Label
var farm_button: Button
var open_button: Button
var income_label: Label
var missions_button: Button
var expedition_button: Button
var upgrades_button: Button
var quest_title_label: Label
var quest_hint_label: Label
var series_chip: PanelContainer
var size_heading: Label
var passive_chip: PanelContainer
var crate_buttons: Dictionary = {}
var _selected_crate: String = "small"

func setup(ui: UIKit) -> void:
	kit = ui
	kit.set_margins(self, 14, 14, 12, 12)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	add_child(content)

	var series_row := HBoxContainer.new()
	content.add_child(series_row)
	series_chip = kit.chip(Loc.t("series"), UIKit.COLOR_ACCENT)
	series_row.add_child(series_chip)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	series_row.add_child(spacer)
	passive_chip = kit.chip("+1 / 10 SEC", UIKit.COLOR_CYAN)
	series_row.add_child(passive_chip)

	var quest_banner := PanelContainer.new()
	quest_banner.add_theme_stylebox_override("panel", kit.box(Color(0.08, 0.07, 0.16, 0.96), 14, Color(1.0, 0.82, 0.4, 0.45), 1, 8))
	content.add_child(quest_banner)
	var quest_col := VBoxContainer.new()
	quest_col.add_theme_constant_override("separation", 1)
	quest_banner.add_child(quest_col)
	quest_title_label = kit.label(Loc.t("quest_banner"), 12, Color("ffd266"))
	quest_col.add_child(quest_title_label)
	quest_hint_label = kit.label("", 11, UIKit.COLOR_MUTED)
	quest_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_col.add_child(quest_hint_label)

	var progression_row := HBoxContainer.new()
	progression_row.add_theme_constant_override("separation", 6)
	content.add_child(progression_row)
	missions_button = Button.new()
	missions_button.text = Loc.t("quests")
	missions_button.custom_minimum_size = Vector2(0, 50)
	missions_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	missions_button.add_theme_font_size_override("font_size", 10)
	kit.style_action_button(missions_button, Color("ffd266"), false)
	missions_button.pressed.connect(func() -> void: AudioManager.play("click"); missions_pressed.emit())
	progression_row.add_child(missions_button)
	expedition_button = Button.new()
	expedition_button.text = Loc.t("expeditions")
	expedition_button.custom_minimum_size = Vector2(0, 50)
	expedition_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	expedition_button.add_theme_font_size_override("font_size", 10)
	kit.style_action_button(expedition_button, Color("73d6a4"), false)
	expedition_button.pressed.connect(func() -> void: AudioManager.play("click"); expeditions_pressed.emit())
	progression_row.add_child(expedition_button)
	upgrades_button = Button.new()
	upgrades_button.text = Loc.t("upgrades")
	upgrades_button.custom_minimum_size = Vector2(0, 50)
	upgrades_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrades_button.add_theme_font_size_override("font_size", 10)
	kit.style_action_button(upgrades_button, Color("7ad7ff"), false)
	upgrades_button.pressed.connect(func() -> void: AudioManager.play("click"); upgrades_pressed.emit())
	progression_row.add_child(upgrades_button)

	farm_world = FarmWorld.new()
	farm_world.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	farm_world.size_flags_vertical = Control.SIZE_EXPAND_FILL
	farm_world.harvest_tapped.connect(_on_farm_pressed)
	content.add_child(farm_world)

	crate_title_label = kit.label("PETITE CAISSE", 22, UIKit.COLOR_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(crate_title_label)
	crate_detail_label = kit.label("6 cartes · 150 essences", 12, UIKit.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(crate_detail_label)
	pity_label = kit.label("PITY UNIQUE  ·  8 000", 11, Color("ffe08a"), HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(pity_label)

	size_heading = kit.label(Loc.t("choose_size"), 11, UIKit.COLOR_MUTED)
	content.add_child(size_heading)
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
		button.text = Loc.t("crate_button") % [crate.label, CardDatabase.format_number(int(crate.cards)), Loc.t("cards_word"), CardDatabase.format_number(int(crate.cost))]
		button.add_theme_font_size_override("font_size", 12)
		button.pressed.connect(select_crate.bind(str(crate_id)))
		crate_grid.add_child(button)
		crate_buttons[crate_id] = button

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 9)
	content.add_child(actions)
	farm_button = Button.new()
	farm_button.custom_minimum_size = Vector2(0, 66)
	farm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	farm_button.add_theme_font_size_override("font_size", 14)
	kit.style_action_button(farm_button, UIKit.COLOR_CYAN, false)
	farm_button.pressed.connect(_on_farm_pressed)
	actions.add_child(farm_button)
	open_button = Button.new()
	open_button.custom_minimum_size = Vector2(0, 66)
	open_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	open_button.add_theme_font_size_override("font_size", 14)
	open_button.pressed.connect(_on_open_pressed)
	actions.add_child(open_button)

	income_label = kit.label(Loc.t("farm_hint"), 11, UIKit.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(income_label)

	_selected_crate = GameState.selected_crate
	if not CardDatabase.CRATES.has(_selected_crate):
		_selected_crate = "small"
	select_crate(_selected_crate)
	refresh()

func apply_locale() -> void:
	if missions_button:
		missions_button.text = Loc.t("quests")
	if expedition_button:
		expedition_button.text = Loc.t("expeditions")
	if upgrades_button:
		upgrades_button.text = Loc.t("upgrades")
	if income_label:
		income_label.text = Loc.t("farm_hint")
	if size_heading:
		size_heading.text = Loc.t("choose_size")
	if series_chip and series_chip.has_meta("value_label"):
		var series_label: Label = series_chip.get_meta("value_label")
		series_label.text = Loc.t("series")
	if CardDatabase.CRATES.has(_selected_crate):
		select_crate(_selected_crate)
	refresh()

func select_crate(crate_id: String) -> void:
	if not CardDatabase.CRATES.has(crate_id):
		return
	_selected_crate = crate_id
	GameState.selected_crate = crate_id
	if farm_world:
		farm_world.set_crate(crate_id)
	var crate: Dictionary = CardDatabase.CRATES[crate_id]
	crate_title_label.text = Loc.t("crate_origin") % crate.label
	crate_detail_label.text = Loc.t("crate_detail") % [CardDatabase.format_number(int(crate.cards)), Loc.t("cards_word"), CardDatabase.format_number(int(crate.cost)), Loc.t("essence").to_lower(), crate.subtitle]
	_update_crate_buttons()
	refresh_open_button()

func _update_crate_buttons() -> void:
	for crate_id in crate_buttons:
		var button: Button = crate_buttons[crate_id]
		var selected: bool = str(crate_id) == _selected_crate
		var accent := UIKit.COLOR_ACCENT_LIGHT if selected else Color("444d70")
		var background := Color(0.20, 0.14, 0.43, 0.96) if selected else Color(0.055, 0.065, 0.14, 0.9)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_override("font", kit.font_bold)
		button.add_theme_color_override("font_color", UIKit.COLOR_TEXT if selected else UIKit.COLOR_MUTED)
		var normal := kit.box(background, 16, Color(accent, 0.78 if selected else 0.40), 2 if selected else 1, 8)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", kit.box(background.lightened(0.08), 16, UIKit.COLOR_ACCENT_LIGHT, 2, 8))

func refresh() -> void:
	refresh_open_button()
	refresh_progression()
	refresh_pity()
	if farm_world:
		farm_world.refresh_wanderers()

func refresh_pity() -> void:
	if pity_label == null:
		return
	var unique_left := GameState.get_pity_remaining("unique")
	var rare_left := GameState.get_pity_remaining("rare")
	var chances := CardDatabase.get_rarity_chances(GameState.luck_level)
	pity_label.text = Loc.t("pity_line") % [CardDatabase.format_number(unique_left), CardDatabase.format_number(rare_left), Loc.t("luck_short"), CardDatabase.format_rate(float(chances.rare) * 100.0)]

func refresh_open_button() -> void:
	if open_button == null or not CardDatabase.CRATES.has(_selected_crate):
		return
	var crate: Dictionary = CardDatabase.CRATES[_selected_crate]
	var affordable := GameState.can_afford(_selected_crate)
	open_button.text = "%s %s\n%s %s" % [Loc.t("open_crate"), CardDatabase.format_number(int(crate.cards)), CardDatabase.format_number(int(crate.cost)), Loc.t("essence")]
	kit.style_action_button(open_button, UIKit.COLOR_ACCENT if affordable else Color("c45f72"), true)
	open_button.modulate = Color.WHITE if affordable else Color(0.78, 0.80, 0.9, 0.78)

func refresh_progression() -> void:
	if farm_button != null:
		var remaining := GameState.get_farm_cooldown()
		farm_button.disabled = remaining > 0
		farm_button.text = ("%s\n+%d %s" % [Loc.t("harvest"), GameState.get_farm_reward(), Loc.t("essence")]) if remaining <= 0 else Loc.t("recharge") % remaining
	if missions_button != null:
		var ready := GameState.get_ready_quest_count()
		missions_button.text = Loc.t("quests") if ready <= 0 else "%s\n%d" % [Loc.t("quests").split("\n")[0], ready]
	if upgrades_button != null:
		upgrades_button.text = Loc.t("upgrades")
	if expedition_button != null:
		if GameState.active_expedition.is_empty():
			expedition_button.text = Loc.t("expeditions")
		elif GameState.is_expedition_complete():
			expedition_button.text = Loc.t("expedition_ready")
		else:
			expedition_button.text = "%s\n%s" % [Loc.t("expeditions").split("\n")[0], _format_duration(GameState.get_expedition_remaining())]
	if quest_title_label != null and quest_hint_label != null:
		var tracked := GameState.get_tracked_quest()
		if tracked.is_empty():
			quest_title_label.text = Loc.t("quests_clear")
			quest_hint_label.text = Loc.t("quests_clear_hint")
		else:
			var counts := "%s / %s" % [CardDatabase.format_number(int(tracked.progress)), CardDatabase.format_number(int(tracked.target))]
			quest_title_label.text = "%s  ·  %s" % [str(tracked.label), counts]
			if bool(tracked.complete):
				quest_hint_label.text = Loc.t("quest_claim_hint")
			else:
				quest_hint_label.text = str(tracked.hint) if str(tracked.hint) != "" else str(tracked.description)
	if passive_chip != null and passive_chip.has_meta("value_label"):
		var chip_label: Label = passive_chip.get_meta("value_label")
		chip_label.text = "+%d / 10 SEC" % GameState.get_passive_reward()

func _on_farm_pressed() -> void:
	var result := GameState.farm()
	if not result.ok:
		return
	AudioManager.play("harvest")
	if farm_world:
		farm_world.punch()
	floating_gain.emit(int(result.amount))
	refresh_progression()

func _on_open_pressed() -> void:
	var result := GameState.open_crate(_selected_crate)
	if not result.ok:
		AudioManager.play("error")
		if farm_world:
			farm_world.punch()
		return
	AudioManager.play("crate_open")
	if farm_world:
		farm_world.punch()
	refresh_pity()
	crate_opened.emit(result)

func _format_duration(total_seconds: int) -> String:
	var seconds := maxi(0, total_seconds)
	var hours := int(seconds / 3600)
	var minutes := int((seconds % 3600) / 60)
	if hours > 0:
		return "%d H %02d MIN" % [hours, minutes]
	return "%02d:%02d" % [minutes, seconds % 60]

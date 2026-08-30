class_name OverlayHost
extends Control
## Overlays : quêtes, améliorations, expéditions, caisses, fiches.

const CreatureCardScene := preload("res://scripts/card_view.gd")
const REVEAL_PAGE_SIZE := 4

signal toast(message: String, accent: Color)
signal album_claimed(album_id: String)

var kit: UIKit

func setup(ui: UIKit) -> void:
	kit = ui
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 80

func new_overlay() -> ColorRect:
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

func close_overlay(overlay: Control) -> void:
	if not is_instance_valid(overlay):
		return
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 0.16)
	tween.finished.connect(overlay.queue_free)

func fade_in(overlay: Control) -> void:
	overlay.modulate.a = 0.0
	create_tween().tween_property(overlay, "modulate:a", 1.0, 0.16)

func show_toast(message: String, accent: Color) -> void:
	var toast_panel := PanelContainer.new()
	toast_panel.custom_minimum_size = Vector2(390, 54)
	toast_panel.anchor_left = 0.5
	toast_panel.anchor_right = 0.5
	toast_panel.anchor_top = 0.84
	toast_panel.anchor_bottom = 0.84
	toast_panel.offset_left = -195
	toast_panel.offset_right = 195
	toast_panel.offset_top = -27
	toast_panel.offset_bottom = 27
	toast_panel.add_theme_stylebox_override("panel", kit.box(Color(0.055, 0.06, 0.13, 0.98), 18, accent, 2, 10))
	toast_panel.z_index = 200
	add_child(toast_panel)
	var node := kit.label(message, 12, accent, HORIZONTAL_ALIGNMENT_CENTER)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_panel.add_child(node)
	toast_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(toast_panel, "modulate:a", 1.0, 0.16)
	tween.tween_interval(1.8)
	tween.tween_property(toast_panel, "modulate:a", 0.0, 0.22)
	tween.finished.connect(toast_panel.queue_free)

func show_reward_card(card: Dictionary, title_text: String, subtitle_text: String) -> void:
	var rarity_data: Dictionary = CardDatabase.RARITIES[card.rarity]
	var overlay := new_overlay()
	var panel := kit.overlay_panel(440, 760)
	overlay.get_node("Center").add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)
	content.add_child(kit.label(title_text, 25, rarity_data.glow, HORIZONTAL_ALIGNMENT_CENTER))
	var subtitle := kit.label(subtitle_text, 11, UIKit.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
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
	kit.style_action_button(close, rarity_data.color, true)
	close.pressed.connect(close_overlay.bind(overlay))
	content.add_child(close)
	_animate_card(overlay, card_view)
	AudioManager.play_rarity(str(card.rarity))

func _animate_card(overlay: Control, card: Control) -> void:
	overlay.modulate = Color(1, 1, 1, 0)
	card.scale = Vector2(0.55, 0.55)
	card.rotation = -0.09
	call_deferred("_run_card_tween", overlay, card)

func _run_card_tween(overlay: Control, card: Control) -> void:
	if not is_instance_valid(overlay) or not is_instance_valid(card):
		return
	card.pivot_offset = card.size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(overlay, "modulate:a", 1.0, 0.20)
	tween.tween_property(card, "scale", Vector2.ONE, 0.50).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "rotation", 0.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func show_missions() -> void:
	GameState.get_completed_mission_count()
	var overlay := new_overlay()
	var panel := kit.overlay_panel(456, 820)
	overlay.get_node("Center").add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	content.add_child(kit.label(Loc.t("quests_title"), 24, Color("ffd266"), HORIZONTAL_ALIGNMENT_CENTER))
	var subtitle := kit.label(Loc.t("quests_hint"), 11, UIKit.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(subtitle)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	var last_chapter := ""
	for row_data in GameState.get_quest_board_rows():
		var chapter := str(row_data.chapter)
		if chapter != last_chapter:
			last_chapter = chapter
			var header_key := "quests_guide" if chapter == "guide" else ("quests_story" if chapter == "story" else "quests_daily")
			list.add_child(kit.label(Loc.t(header_key), 12, UIKit.COLOR_CYAN))
		_add_quest_row(list, overlay, row_data)
	var close := Button.new()
	close.text = Loc.t("close")
	close.custom_minimum_size.y = 55
	kit.style_action_button(close, UIKit.COLOR_ACCENT, true)
	close.pressed.connect(close_overlay.bind(overlay))
	content.add_child(close)
	fade_in(overlay)

func _add_quest_row(list: VBoxContainer, overlay: Control, row_data: Dictionary) -> void:
	var claimed: bool = bool(row_data.claimed)
	var locked: bool = bool(row_data.locked)
	var complete: bool = bool(row_data.complete)
	var accent := Color("5a6280") if locked else (Color("78e6a0") if complete else UIKit.COLOR_ACCENT_LIGHT)
	var mission_panel := PanelContainer.new()
	mission_panel.custom_minimum_size.y = 118
	mission_panel.add_theme_stylebox_override("panel", kit.box(Color(0.055, 0.065, 0.135, 0.98), 17, Color(accent, 0.38), 1, 10))
	list.add_child(mission_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	mission_panel.add_child(row)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(details)
	var title := str(row_data.label) if not locked else "???"
	details.add_child(kit.label(title, 14, accent))
	var body := str(row_data.hint) if locked else str(row_data.description)
	var body_label := kit.label(body, 11, UIKit.COLOR_MUTED)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(body_label)
	var progress := ProgressBar.new()
	progress.min_value = 0
	progress.max_value = maxi(1, int(row_data.target))
	progress.value = 0 if locked else int(row_data.progress)
	progress.show_percentage = false
	progress.custom_minimum_size.y = 12
	details.add_child(progress)
	var counts := "—" if locked else "%s / %s" % [CardDatabase.format_number(int(row_data.progress)), CardDatabase.format_number(int(row_data.target))]
	details.add_child(kit.label(counts, 10, UIKit.COLOR_MUTED))
	var reward_text := "+%s %s" % [CardDatabase.format_number(int(row_data.reward)), "JETONS" if str(row_data.reward_type) == "coins" else "ESSENCES"]
	var claim := Button.new()
	if claimed:
		claim.text = Loc.t("claimed")
	elif locked:
		claim.text = Loc.t("locked")
	else:
		claim.text = reward_text
	claim.custom_minimum_size = Vector2(115, 52)
	claim.disabled = locked or claimed or not complete
	claim.add_theme_font_size_override("font_size", 10)
	kit.style_action_button(claim, Color("ffd266"), true)
	claim.pressed.connect(_claim_board_row.bind(str(row_data.kind), str(row_data.id), overlay))
	row.add_child(claim)

func _claim_board_row(kind: String, item_id: String, overlay: Control) -> void:
	var result: Dictionary = GameState.claim_mission(item_id) if kind == "daily" else GameState.claim_quest(item_id)
	if not result.ok:
		show_toast(result.error, Color("ff8b9d"))
		return
	AudioManager.play("mission")
	overlay.queue_free()
	var currency := "jetons" if str(result.reward_type) == "coins" else "essences"
	show_toast("%s +%s %s." % [Loc.t("quest_done"), CardDatabase.format_number(int(result.reward)), currency], Color("ffd266"))
	call_deferred("show_missions")

func _claim_mission(mission_id: String, overlay: Control) -> void:
	_claim_board_row("daily", mission_id, overlay)

func show_upgrades() -> void:
	var overlay := new_overlay()
	var panel := kit.overlay_panel(456, 820)
	overlay.get_node("Center").add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	content.add_child(kit.label(Loc.t("upgrades_title"), 24, Color("73d6a4"), HORIZONTAL_ALIGNMENT_CENTER))
	var hint := kit.label(Loc.t("upgrades_hint"), 11, UIKit.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	list.add_child(kit.label(Loc.t("upgrades_farm"), 12, UIKit.COLOR_CYAN))
	_add_upgrade_row(list, overlay, "yield", Loc.t("upgrade_yield"), Loc.t("upgrade_yield_hint"), Color("73d6a4"))
	_add_upgrade_row(list, overlay, "speed", Loc.t("upgrade_speed"), Loc.t("upgrade_speed_hint"), Color("7ad7ff"))
	_add_upgrade_row(list, overlay, "passive", Loc.t("upgrade_passive"), Loc.t("upgrade_passive_hint"), Color("8cf0b5"))
	list.add_child(kit.label(Loc.t("upgrades_luck"), 12, Color("ffd266")))
	_add_upgrade_row(list, overlay, "luck", Loc.t("upgrade_luck"), Loc.t("upgrade_luck_hint"), Color("ffd266"))
	var chances := CardDatabase.get_rarity_chances(GameState.luck_level)
	var rates := kit.label(Loc.t("luck_rates") % [CardDatabase.format_rate(float(chances.rare) * 100.0), CardDatabase.format_rate(float(chances.epic) * 100.0), CardDatabase.format_rate(float(chances.legendary) * 100.0), CardDatabase.format_rate(float(chances.unique) * 100.0)], 11, Color("ffe08a"), HORIZONTAL_ALIGNMENT_CENTER)
	rates.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(rates)
	var close := Button.new()
	close.text = Loc.t("close")
	close.custom_minimum_size.y = 55
	kit.style_action_button(close, UIKit.COLOR_ACCENT, true)
	close.pressed.connect(close_overlay.bind(overlay))
	content.add_child(close)
	fade_in(overlay)

func _add_upgrade_row(list: VBoxContainer, overlay: Control, upgrade_id: String, title: String, hint_text: String, accent: Color) -> void:
	var level := GameState.get_upgrade_level(upgrade_id)
	var maximum := GameState.get_upgrade_max(upgrade_id)
	var maxed := GameState.is_upgrade_maxed(upgrade_id)
	var preview := GameState.get_upgrade_preview(upgrade_id)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 122
	panel.add_theme_stylebox_override("panel", kit.box(Color(0.05, 0.07, 0.13, 0.98), 17, Color(accent, 0.40), 1, 10))
	list.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(details)
	details.add_child(kit.label("%s  ·  %d / %d" % [title, level, maximum], 14, accent))
	var hint_label := kit.label(hint_text, 11, UIKit.COLOR_MUTED)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(hint_label)
	var values := Loc.t("upgrade_values") % [str(preview.current), str(preview.next)] if not maxed else Loc.t("upgrade_maxed") % str(preview.current)
	details.add_child(kit.label(values, 11, UIKit.COLOR_TEXT))
	var buy := Button.new()
	if maxed:
		buy.text = Loc.t("max")
	else:
		buy.text = "%s\n%s" % [Loc.t("buy"), CardDatabase.format_number(GameState.get_upgrade_cost(upgrade_id))]
	buy.custom_minimum_size = Vector2(118, 56)
	buy.disabled = maxed or GameState.essence < GameState.get_upgrade_cost(upgrade_id)
	buy.add_theme_font_size_override("font_size", 10)
	kit.style_action_button(buy, accent, true)
	buy.pressed.connect(_buy_upgrade.bind(upgrade_id, overlay))
	row.add_child(buy)

func _buy_upgrade(upgrade_id: String, overlay: Control) -> void:
	var result := GameState.buy_upgrade(upgrade_id)
	if not result.ok:
		show_toast(result.error, Color("ff8b9d"))
		AudioManager.play("error")
		return
	AudioManager.play("mission")
	overlay.queue_free()
	show_toast(Loc.t("upgrade_bought"), Color("73d6a4"))
	call_deferred("show_upgrades")

func show_expeditions() -> void:
	var overlay := new_overlay()
	var panel := kit.overlay_panel(456, 820)
	overlay.get_node("Center").add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)
	content.add_child(kit.label("EXPÉDITIONS", 24, Color("73d6a4"), HORIZONTAL_ALIGNMENT_CENTER))
	if GameState.active_expedition.is_empty():
		var intro := kit.label("Choisissez la durée puis composez une équipe. Les créatures partent en séquestre et gagnent de la maîtrise.", 11, UIKit.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(intro)
		for expedition_id in ["short", "medium", "long"]:
			var definition: Dictionary = GameState.EXPEDITIONS[expedition_id]
			var option := PanelContainer.new()
			option.custom_minimum_size.y = 125
			option.add_theme_stylebox_override("panel", kit.box(Color(0.05, 0.075, 0.12, 0.98), 18, Color(0.35, 0.75, 0.55, 0.42), 1, 11))
			content.add_child(option)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			option.add_child(row)
			var details := VBoxContainer.new()
			details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(details)
			details.add_child(kit.label(str(definition.label), 15, Color("8cf0b5")))
			details.add_child(kit.label("Durée : %s  ·  %d créature%s" % [str(definition.duration_label), int(definition.cards_required), "s" if int(definition.cards_required) > 1 else ""], 11, UIKit.COLOR_MUTED))
			details.add_child(kit.label("Base : %s essences" % CardDatabase.format_number(int(definition.reward)), 10, UIKit.COLOR_MUTED))
			var start := Button.new()
			start.text = "COMPOSER\nL’ÉQUIPE"
			start.custom_minimum_size = Vector2(130, 58)
			start.disabled = GameState.get_available_creature_ids().size() < int(definition.cards_required)
			start.add_theme_font_size_override("font_size", 10)
			kit.style_action_button(start, Color("73d6a4"), true)
			start.pressed.connect(_open_team_picker.bind(str(expedition_id), overlay))
			row.add_child(start)
	else:
		_fill_active_expedition(content, overlay)
	var close := Button.new()
	close.text = "FERMER"
	close.custom_minimum_size.y = 54
	kit.style_action_button(close, UIKit.COLOR_ACCENT, false)
	close.pressed.connect(close_overlay.bind(overlay))
	content.add_child(close)
	fade_in(overlay)

func _fill_active_expedition(content: VBoxContainer, overlay: Control) -> void:
	var expedition: Dictionary = GameState.active_expedition
	var definition: Dictionary = GameState.EXPEDITIONS[str(expedition.id)]
	content.add_child(kit.label(str(definition.label), 19, Color("8cf0b5"), HORIZONTAL_ALIGNMENT_CENTER))
	var status_text := "TERMINÉE · RÉCOMPENSE PRÊTE" if GameState.is_expedition_complete() else "RETOUR DANS %s" % _format_duration(GameState.get_expedition_remaining())
	content.add_child(kit.label(status_text, 14, Color("ffd266") if GameState.is_expedition_complete() else UIKit.COLOR_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	content.add_child(kit.label("Bonus habitat +%d %%  ·  maîtrise +%d %%" % [int(expedition.get("habitat_bonus", 0)), int(expedition.get("mastery_bonus", 0))], 11, UIKit.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var team := HFlowContainer.new()
	team.alignment = FlowContainer.ALIGNMENT_CENTER
	team.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(team)
	for card_id in expedition.team:
		var card := CardDatabase.get_card(str(card_id))
		var rarity_data: Dictionary = CardDatabase.RARITIES[card.rarity]
		var member := VBoxContainer.new()
		member.custom_minimum_size.x = 78
		member.add_child(kit.mini_art(card.art, rarity_data.color))
		var member_name := kit.label(str(card.name), 8, rarity_data.glow, HORIZONTAL_ALIGNMENT_CENTER)
		member_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		member.add_child(member_name)
		member.add_child(kit.label(GameState.get_mastery_title(str(card_id)), 8, Color("8cf0b5"), HORIZONTAL_ALIGNMENT_CENTER))
		team.add_child(member)
	var claim := Button.new()
	claim.text = "RÉCUPÉRER +%s ESSENCES" % CardDatabase.format_number(int(expedition.reward)) if GameState.is_expedition_complete() else "EXPÉDITION EN COURS"
	claim.custom_minimum_size.y = 60
	claim.disabled = not GameState.is_expedition_complete()
	kit.style_action_button(claim, Color("73d6a4"), true)
	claim.pressed.connect(_claim_expedition.bind(overlay))
	content.add_child(claim)

func _open_team_picker(expedition_id: String, previous: Control) -> void:
	if is_instance_valid(previous):
		previous.queue_free()
	var definition: Dictionary = GameState.EXPEDITIONS[expedition_id]
	var required := int(definition.cards_required)
	var overlay := new_overlay()
	var panel := kit.overlay_panel(456, 860)
	overlay.get_node("Center").add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	content.add_child(kit.label("ÉQUIPE · %s" % definition.label, 22, Color("8cf0b5"), HORIZONTAL_ALIGNMENT_CENTER))
	var hint := kit.label("Touchez une créature pour l’ajouter ou la retirer. Elles seront séquestrées jusqu’au retour.", 11, UIKit.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint)
	var selected_label := kit.label("0 / %d" % required, 13, Color("ffd266"), HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(selected_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	var selected: Array[String] = []
	var reward_preview := kit.label("Récompense estimée : %s essences" % CardDatabase.format_number(GameState.get_expedition_reward(expedition_id, [])), 11, UIKit.COLOR_CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(reward_preview)
	for card_id in GameState.get_available_creature_ids():
		var card := CardDatabase.get_card(card_id)
		var rarity_data: Dictionary = CardDatabase.RARITIES[card.rarity]
		var row := Button.new()
		row.custom_minimum_size.y = 64
		row.text = "%s  ·  %s  ·  %s" % [card.name, rarity_data.label, GameState.get_mastery_title(card_id)]
		row.add_theme_font_size_override("font_size", 12)
		kit.style_action_button(row, rarity_data.color, false)
		row.pressed.connect(_toggle_team_member.bind(card_id, selected, required, selected_label, reward_preview, expedition_id, row))
		list.add_child(row)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 9)
	content.add_child(actions)
	var back := Button.new()
	back.text = "RETOUR"
	back.custom_minimum_size.y = 54
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kit.style_action_button(back, UIKit.COLOR_MUTED, false)
	back.pressed.connect(func() -> void: close_overlay(overlay); call_deferred("show_expeditions"))
	actions.add_child(back)
	var confirm := Button.new()
	confirm.text = "LANCER"
	confirm.custom_minimum_size.y = 54
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kit.style_action_button(confirm, Color("73d6a4"), true)
	confirm.pressed.connect(_confirm_team.bind(expedition_id, selected, required, overlay))
	actions.add_child(confirm)
	overlay.set_meta("confirm", confirm)
	fade_in(overlay)

func _toggle_team_member(card_id: String, selected: Array, required: int, selected_label: Label, reward_preview: Label, expedition_id: String, row: Button) -> void:
	if selected.has(card_id):
		selected.erase(card_id)
		row.modulate = Color.WHITE
	elif selected.size() < required:
		selected.append(card_id)
		row.modulate = Color(0.75, 1.0, 0.82)
	selected_label.text = "%d / %d" % [selected.size(), required]
	reward_preview.text = "Récompense estimée : %s essences" % CardDatabase.format_number(GameState.get_expedition_reward(expedition_id, selected))
	AudioManager.play("click")

func _confirm_team(expedition_id: String, selected: Array, required: int, overlay: Control) -> void:
	if selected.size() != required:
		show_toast("Sélectionnez exactement %d créature%s." % [required, "s" if required > 1 else ""], Color("ff8b9d"))
		return
	var result := GameState.start_expedition(expedition_id, selected)
	if not result.ok:
		show_toast(result.error, Color("ff8b9d"))
		AudioManager.play("error")
		return
	AudioManager.play("mission")
	close_overlay(overlay)
	show_toast("Expédition lancée. L’équipe est en séquestre.", Color("73d6a4"))

func _claim_expedition(overlay: Control) -> void:
	var result := GameState.claim_expedition()
	if not result.ok:
		show_toast(result.error, Color("ff8b9d"))
		return
	overlay.queue_free()
	AudioManager.play("mission")
	show_toast("Expédition terminée : +%s essences. Maîtrise +1." % CardDatabase.format_number(int(result.reward)), Color("73d6a4"))

func _format_duration(total_seconds: int) -> String:
	var seconds := maxi(0, total_seconds)
	var hours := int(seconds / 3600)
	var minutes := int((seconds % 3600) / 60)
	if hours > 0:
		return "%d H %02d MIN" % [hours, minutes]
	return "%02d:%02d" % [minutes, seconds % 60]

func show_card_details(card: Dictionary) -> void:
	var owned := GameState.get_card_count(card.id)
	var available := GameState.get_available_count(str(card.id))
	var locked := not GameState.is_card_discovered(str(card.id))
	var rarity_data: Dictionary = CardDatabase.RARITIES[card.rarity]
	var overlay := new_overlay()
	var panel := kit.overlay_panel(456, 850)
	overlay.get_node("Center").add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 9)
	panel.add_child(content)
	var card_rate := CardDatabase.get_card_drop_rate(str(card.id))
	var rarity_header := "ULTIME  ·  OBJECTIF PERMANENT  ·  LIÉE AU COMPTE" if str(card.rarity) == "ultimate" else "%s  ·  RANG %s  ·  CARTE %s" % [rarity_data.label, CardDatabase.format_rate(float(rarity_data.drop_rate)), CardDatabase.format_rate(card_rate)]
	content.add_child(kit.label(rarity_header, 10, rarity_data.glow, HORIZONTAL_ALIGNMENT_CENTER))
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(center)
	var card_view := CreatureCardScene.new()
	card_view.custom_minimum_size = Vector2(285, 418)
	center.add_child(card_view)
	card_view.configure(card, owned, locked, false)
	var lore_panel := PanelContainer.new()
	lore_panel.add_theme_stylebox_override("panel", kit.box(Color(0.04, 0.05, 0.115, 0.95), 14, Color(rarity_data.color, 0.25), 1, 10))
	content.add_child(lore_panel)
	var lore := kit.label("“%s”" % card.lore, 12, Color("cbd2e6"), HORIZONTAL_ALIGNMENT_CENTER)
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_panel.add_child(lore)
	var mastery := "Maîtrise %s · %d expédition%s" % [GameState.get_mastery_title(str(card.id)), GameState.get_mastery_xp(str(card.id)), "s" if GameState.get_mastery_xp(str(card.id)) > 1 else ""]
	content.add_child(kit.label(mastery, 11, Color("8cf0b5"), HORIZONTAL_ALIGNMENT_CENTER))
	var reserved := GameState.get_reserved_count(str(card.id))
	var status_text := "NON DÉCOUVERTE" if locked else ("%s possédé%s · %s dispo%s%s" % [CardDatabase.format_number(owned), "s" if owned > 1 else "", CardDatabase.format_number(available), "s" if available > 1 else "", " · %d en expédition" % reserved if reserved > 0 else ""])
	content.add_child(kit.label(status_text, 12, Color("ffb0c0") if locked else rarity_data.glow, HORIZONTAL_ALIGNMENT_CENTER))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 7)
	content.add_child(actions)
	if available > 0 and bool(card.get("tradable", true)) and str(card.rarity) != "ultimate":
		var sell := Button.new()
		sell.text = "VENDRE"
		sell.custom_minimum_size.y = 55
		sell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sell.add_theme_font_size_override("font_size", 10)
		kit.style_action_button(sell, Color("ffd266"), false)
		sell.pressed.connect(func() -> void: close_overlay(overlay); show_sell(card))
		actions.add_child(sell)
	if GameState.get_recyclable_count(str(card.id)) > 0:
		var recycle := Button.new()
		recycle.text = "RECYCLER"
		recycle.custom_minimum_size.y = 55
		recycle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		recycle.add_theme_font_size_override("font_size", 10)
		kit.style_action_button(recycle, Color("73d6a4"), false)
		recycle.pressed.connect(func() -> void: close_overlay(overlay); show_recycle(card))
		actions.add_child(recycle)
	var close := Button.new()
	close.text = "FERMER"
	close.custom_minimum_size.y = 55
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kit.style_action_button(close, rarity_data.color, true)
	close.pressed.connect(close_overlay.bind(overlay))
	actions.add_child(close)
	_animate_card(overlay, card_view)

func show_recycle(card: Dictionary) -> void:
	var recyclable := GameState.get_recyclable_count(str(card.id))
	if recyclable <= 0:
		show_toast("Aucun doublon recyclable.", Color("ff8b9d"))
		return
	var rarity_data: Dictionary = CardDatabase.RARITIES[card.rarity]
	var unit_value := GameState.get_recycle_value(str(card.id))
	var overlay := new_overlay()
	var panel := kit.overlay_panel(430, 620)
	overlay.get_node("Center").add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	content.add_child(kit.label("RECYCLER LES DOUBLONS", 22, Color("73d6a4"), HORIZONTAL_ALIGNMENT_CENTER))
	content.add_child(kit.label(str(card.name), 17, rarity_data.glow, HORIZONTAL_ALIGNMENT_CENTER))
	var preview := CenterContainer.new()
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(preview)
	preview.add_child(kit.mini_art(card.art, rarity_data.color))
	content.add_child(kit.label("%s doublon%s · 1 exemplaire protégé" % [CardDatabase.format_number(recyclable), "s" if recyclable > 1 else ""], 11, UIKit.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var quantity_row := HBoxContainer.new()
	content.add_child(quantity_row)
	var quantity_title := kit.label("QUANTITÉ", 12, UIKit.COLOR_TEXT)
	quantity_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quantity_row.add_child(quantity_title)
	var quantity := SpinBox.new()
	quantity.min_value = 1
	quantity.max_value = recyclable
	quantity.value = 1
	quantity.allow_greater = false
	quantity.custom_minimum_size = Vector2(170, 48)
	kit.style_spin_box(quantity, UIKit.COLOR_GREEN)
	quantity_row.add_child(quantity)
	var reward_label := kit.label("GAIN : %s POUSSIÈRE%s" % [CardDatabase.format_number(unit_value), "S" if unit_value > 1 else ""], 14, Color("73d6a4"), HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(reward_label)
	quantity.value_changed.connect(func(value: float) -> void:
		var total := int(value) * unit_value
		reward_label.text = "GAIN : %s POUSSIÈRE%s" % [CardDatabase.format_number(total), "S" if total > 1 else ""]
	)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 9)
	content.add_child(actions)
	var cancel := Button.new()
	cancel.text = "ANNULER"
	cancel.custom_minimum_size.y = 54
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kit.style_action_button(cancel, UIKit.COLOR_MUTED, false)
	cancel.pressed.connect(close_overlay.bind(overlay))
	actions.add_child(cancel)
	var confirm := Button.new()
	confirm.text = "RECYCLER"
	confirm.custom_minimum_size.y = 54
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kit.style_action_button(confirm, Color("73d6a4"), true)
	confirm.pressed.connect(func() -> void:
		var result := GameState.recycle_duplicates(str(card.id), int(quantity.value))
		if not result.ok:
			show_toast(result.error, Color("ff8b9d"))
			return
		close_overlay(overlay)
		show_toast("%s doublon%s recyclé%s : +%s poussières." % [CardDatabase.format_number(int(result.amount)), "s" if int(result.amount) > 1 else "", "s" if int(result.amount) > 1 else "", CardDatabase.format_number(int(result.reward))], Color("73d6a4"))
	)
	actions.add_child(confirm)
	fade_in(overlay)

func show_sell(card: Dictionary) -> void:
	var owned := GameState.get_available_count(card.id)
	if owned <= 0:
		show_toast("Aucun exemplaire disponible.", Color("ff8b9d"))
		return
	var rarity_data: Dictionary = CardDatabase.RARITIES[card.rarity]
	var overlay := new_overlay()
	var panel := kit.overlay_panel(430, 650)
	overlay.get_node("Center").add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	content.add_child(kit.label("METTRE EN VENTE", 23, Color("ffd266"), HORIZONTAL_ALIGNMENT_CENTER))
	content.add_child(kit.label(card.name, 18, rarity_data.glow, HORIZONTAL_ALIGNMENT_CENTER))
	var preview := CenterContainer.new()
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(preview)
	preview.add_child(kit.mini_art(card.art, rarity_data.color))
	content.add_child(kit.label("Disponibles : %s" % CardDatabase.format_number(owned), 11, UIKit.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var quantity_row := HBoxContainer.new()
	content.add_child(quantity_row)
	var quantity_label := kit.label("QUANTITÉ", 12, UIKit.COLOR_TEXT)
	quantity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quantity_row.add_child(quantity_label)
	var quantity := SpinBox.new()
	quantity.min_value = 1
	quantity.max_value = owned
	quantity.value = 1
	quantity.allow_greater = false
	quantity.custom_minimum_size = Vector2(160, 48)
	kit.style_spin_box(quantity, UIKit.COLOR_GOLD)
	quantity_row.add_child(quantity)
	var price_row := HBoxContainer.new()
	content.add_child(price_row)
	var price_label := kit.label("PRIX PAR CARTE", 12, UIKit.COLOR_TEXT)
	price_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	price_row.add_child(price_label)
	var price := SpinBox.new()
	price.min_value = 1
	price.max_value = 10000000
	var defaults := {"common": 75, "rare": 2500, "epic": 25000, "legendary": 250000, "unique": 1000000}
	price.value = int(defaults.get(card.rarity, 75))
	price.step = 5
	price.suffix = " jetons"
	price.allow_greater = false
	price.custom_minimum_size = Vector2(200, 48)
	kit.style_spin_box(price, UIKit.COLOR_GOLD)
	price_row.add_child(price)
	var warning := kit.label("La carte est retirée de l’inventaire jusqu’à l’achat ou l’annulation de l’offre. Le marché n’utilise que des jetons de jeu.", 10, UIKit.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(warning)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 9)
	content.add_child(actions)
	var cancel := Button.new()
	cancel.text = "ANNULER"
	cancel.custom_minimum_size.y = 54
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kit.style_action_button(cancel, UIKit.COLOR_MUTED, false)
	cancel.pressed.connect(close_overlay.bind(overlay))
	actions.add_child(cancel)
	var confirm := Button.new()
	confirm.text = "PUBLIER L’OFFRE"
	confirm.custom_minimum_size.y = 54
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kit.style_action_button(confirm, Color("ffd266"), true)
	confirm.pressed.connect(func() -> void:
		confirm.disabled = true
		var result: Dictionary = await GameState.create_market_listing(str(card.id), int(quantity.value), int(price.value))
		confirm.disabled = false
		if not result.ok:
			show_toast(str(result.error), Color("ff8b9d"))
			return
		close_overlay(overlay)
		show_toast(Loc.t("market_listed"), Color("ffd266"))
	)
	actions.add_child(confirm)
	fade_in(overlay)

func show_album_detail(album_id: String) -> void:
	var album := CardDatabase.get_album(album_id)
	if album.is_empty():
		show_toast("Album introuvable.", Color("ff8b9d"))
		return
	var progress_data := GameState.get_album_progress(album_id)
	var claimed := GameState.claimed_albums.has(album_id)
	var overlay := new_overlay()
	var panel := kit.overlay_panel(456, 860)
	overlay.get_node("Center").add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	content.add_child(kit.label(str(album.label), 23, Color("ffd88a"), HORIZONTAL_ALIGNMENT_CENTER))
	var description := kit.label(str(album.description), 11, UIKit.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(description)
	content.add_child(kit.label("%d / %d CARTES DÉCOUVERTES" % [int(progress_data.discovered), int(progress_data.total)], 12, Color("ffd266"), HORIZONTAL_ALIGNMENT_CENTER))
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
		view.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		grid.add_child(view)
		view.configure(card, GameState.get_card_count(str(card_id)), not GameState.is_card_discovered(str(card_id)), true)
		view.card_pressed.connect(func(data: Dictionary) -> void: close_overlay(overlay); show_card_details(data))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 9)
	content.add_child(actions)
	var close := Button.new()
	close.text = "FERMER"
	close.custom_minimum_size.y = 54
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kit.style_action_button(close, UIKit.COLOR_ACCENT, false)
	close.pressed.connect(close_overlay.bind(overlay))
	actions.add_child(close)
	var claim := Button.new()
	claim.text = "RÉCOMPENSE RÉCUPÉRÉE" if claimed else "RÉCUPÉRER LA RÉCOMPENSE"
	claim.custom_minimum_size.y = 54
	claim.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	claim.disabled = claimed or not bool(progress_data.complete)
	claim.add_theme_font_size_override("font_size", 10)
	kit.style_action_button(claim, Color("ffd266"), true)
	claim.pressed.connect(func() -> void:
		var result := GameState.claim_album(album_id)
		if not result.ok:
			show_toast(result.error, Color("ff8b9d"))
			return
		close_overlay(overlay)
		show_toast("Album terminé : récompenses ajoutées.", Color("ffd266"))
	)
	actions.add_child(claim)
	fade_in(overlay)

func show_ultimate() -> void:
	var ultimate := CardDatabase.get_card(GameState.ULTIMATE_CARD_ID)
	var progress := GameState.get_ultimate_goal_progress()
	var overlay := new_overlay()
	var panel := kit.overlay_panel(456, 860)
	overlay.get_node("Center").add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	content.add_child(kit.label("OBJECTIF ULTIME", 24, Color("fff0b0"), HORIZONTAL_ALIGNMENT_CENTER))
	var explanation := kit.label("Découvrez les %d cartes Uniques pour forger AETERNUM." % int(progress.total), 11, UIKit.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
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
	content.add_child(kit.label(state_text, 13, Color("ffe08a") if bool(progress.ready) or bool(progress.owned) else UIKit.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var unique_grid := HFlowContainer.new()
	unique_grid.name = "UltimateUniqueGrid"
	unique_grid.alignment = FlowContainer.ALIGNMENT_CENTER
	content.add_child(unique_grid)
	for card in CardDatabase.get_cards_for_rarity("unique"):
		var discovered := GameState.is_card_discovered(str(card.id))
		var icon := kit.mini_art(card.art, CardDatabase.RARITIES.unique.color, Vector2(58, 66))
		icon.modulate = Color.WHITE if discovered else Color(0.24, 0.27, 0.35, 0.55)
		unique_grid.add_child(icon)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 9)
	content.add_child(actions)
	var close := Button.new()
	close.text = "FERMER"
	close.custom_minimum_size.y = 54
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kit.style_action_button(close, UIKit.COLOR_MUTED, false)
	close.pressed.connect(close_overlay.bind(overlay))
	actions.add_child(close)
	var forge := Button.new()
	forge.text = "OBJECTIF ACCOMPLI" if bool(progress.owned) else "FORGER AETERNUM"
	forge.custom_minimum_size.y = 54
	forge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	forge.disabled = bool(progress.owned) or not bool(progress.ready)
	kit.style_action_button(forge, Color("ffe08a"), true)
	forge.pressed.connect(func() -> void:
		var result := GameState.claim_ultimate_goal()
		if not result.ok:
			show_toast(result.error, Color("ff8b9d"))
			return
		close_overlay(overlay)
		show_reward_card(result.card, "CARTE ULTIME OBTENUE", "Objectif permanent accompli · AETERNUM est liée à votre compte")
	)
	actions.add_child(forge)
	fade_in(overlay)

func show_opening_result(result: Dictionary) -> void:
	var overlay := new_overlay()
	var panel := kit.overlay_panel(456, 840)
	overlay.get_node("Center").add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	content.add_child(kit.label("OUVERTURE · CAISSE ORIGINE", 11, UIKit.COLOR_ACCENT_LIGHT, HORIZONTAL_ALIGNMENT_CENTER))
	var title := kit.label("PRÉPAREZ-VOUS", 24, UIKit.COLOR_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(title)
	var progress := kit.label("0 / %d" % int(result.amount), 12, UIKit.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(progress)
	var card_center := CenterContainer.new()
	card_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(card_center)
	var card_view := CreatureCardScene.new()
	card_view.custom_minimum_size = Vector2(270, 397)
	card_view.show_quantity = false
	card_center.add_child(card_view)
	var status := kit.label("Touchez le bouton pour révéler la première carte.", 11, UIKit.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(status)
	var summary := VBoxContainer.new()
	summary.visible = false
	summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary.add_theme_constant_override("separation", 8)
	content.add_child(summary)
	var discovery_count := int(result.newly_discovered.size())
	var discovery_label := kit.label("%d nouvelle%s carte%s" % [discovery_count, "s" if discovery_count > 1 else "", "s" if discovery_count > 1 else ""], 13, UIKit.COLOR_CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	summary.add_child(discovery_label)
	var pity_label := kit.label("Filet anti-malchance déclenché.", 11, Color("ffe08a"), HORIZONTAL_ALIGNMENT_CENTER)
	pity_label.visible = not result.get("pity_hits", []).is_empty()
	summary.add_child(pity_label)
	var flip_hint := kit.label("Touchez une carte pour la retourner.", 11, UIKit.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	summary.add_child(flip_hint)
	var grid := GridContainer.new()
	grid.name = "RevealCardsGrid"
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	summary.add_child(grid)
	var pager := HBoxContainer.new()
	pager.add_theme_constant_override("separation", 8)
	summary.add_child(pager)
	var grid_prev := Button.new()
	grid_prev.text = "‹"
	grid_prev.custom_minimum_size = Vector2(54, 44)
	kit.style_action_button(grid_prev, UIKit.COLOR_ACCENT, false)
	pager.add_child(grid_prev)
	var page_label := kit.label("PAGE 1 / 1", 11, UIKit.COLOR_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pager.add_child(page_label)
	var grid_next := Button.new()
	grid_next.text = "›"
	grid_next.custom_minimum_size = Vector2(54, 44)
	kit.style_action_button(grid_next, UIKit.COLOR_ACCENT, false)
	pager.add_child(grid_next)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 9)
	content.add_child(actions)
	var skip := Button.new()
	skip.text = "TOUT RÉVÉLER"
	skip.custom_minimum_size = Vector2(140, 58)
	skip.add_theme_font_size_override("font_size", 11)
	kit.style_action_button(skip, UIKit.COLOR_MUTED, false)
	actions.add_child(skip)
	var next := Button.new()
	next.text = "RÉVÉLER LA PREMIÈRE"
	next.custom_minimum_size.y = 58
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kit.style_action_button(next, UIKit.COLOR_ACCENT, true)
	actions.add_child(next)
	var state := {
		"result": result, "pulls": result.pulls, "index": -1, "summary_shown": false, "seen_new": {},
		"title": title, "progress": progress, "status": status, "card_center": card_center,
		"card": card_view, "summary": summary, "skip": skip, "next": next,
		"grid": grid, "grid_page": 0, "page_label": page_label, "grid_prev": grid_prev, "grid_next": grid_next,
		"flipped": {}, "flip_hint": flip_hint
	}
	overlay.set_meta("reveal_state", state)
	next.pressed.connect(_on_reveal_next_pressed.bind(overlay))
	card_view.flipped.connect(_on_sequential_card_flipped.bind(overlay))
	skip.pressed.connect(func() -> void: _show_reveal_summary(overlay))
	grid_prev.pressed.connect(func() -> void:
		state.grid_page = maxi(0, int(state.grid_page) - 1)
		_render_reveal_grid(overlay)
	)
	grid_next.pressed.connect(func() -> void:
		state.grid_page = int(state.grid_page) + 1
		_render_reveal_grid(overlay)
	)
	fade_in(overlay)
	_show_sequential_card(overlay, 0)

func _on_reveal_next_pressed(overlay: Control) -> void:
	if not is_instance_valid(overlay) or not overlay.has_meta("reveal_state"):
		return
	var state: Dictionary = overlay.get_meta("reveal_state")
	if bool(state.summary_shown):
		close_overlay(overlay)
		return
	var card_view: CreatureCard = state.card
	if card_view.face_down:
		card_view.flip_to_front()
		return
	var next_index := int(state.index) + 1
	var pulls: Array = state.pulls
	if next_index >= pulls.size():
		_show_reveal_summary(overlay)
		return
	_show_sequential_card(overlay, next_index)

func _show_sequential_card(overlay: Control, index: int) -> void:
	if not is_instance_valid(overlay) or not overlay.has_meta("reveal_state"):
		return
	var state: Dictionary = overlay.get_meta("reveal_state")
	var pulls: Array = state.pulls
	if index < 0 or index >= pulls.size():
		_show_reveal_summary(overlay)
		return
	state.index = index
	var card_id := str(pulls[index])
	var card: Dictionary = CardDatabase.get_card(card_id)
	var card_view: CreatureCard = state.card
	card_view.visible = true
	card_view.rotation = 0.0
	card_view.scale = Vector2.ONE
	card_view.configure(card, 1, false, true)
	card_view.set_face_down(true)
	state.title.text = "CARTE  %d / %d" % [index + 1, pulls.size()]
	state.title.add_theme_color_override("font_color", UIKit.COLOR_TEXT)
	state.progress.text = "%d / %d" % [index + 1, pulls.size()]
	state.status.text = "Touchez la carte pour la retourner."
	state.status.add_theme_color_override("font_color", UIKit.COLOR_MUTED)
	state.next.text = "RETOURNER"

func _on_sequential_card_flipped(data: Dictionary, overlay: Control) -> void:
	if not is_instance_valid(overlay) or not overlay.has_meta("reveal_state"):
		return
	var state: Dictionary = overlay.get_meta("reveal_state")
	if bool(state.summary_shown) or data.is_empty():
		return
	AudioManager.play_rarity(str(data.get("rarity", "common")))
	state.flipped[int(state.index)] = true
	var rarity_data: Dictionary = CardDatabase.RARITIES[str(data.rarity)]
	state.title.text = str(data.name)
	state.title.add_theme_color_override("font_color", rarity_data.glow)
	var card_id := str(data.get("id", ""))
	var is_new: bool = state.result.newly_discovered.has(card_id) and not state.seen_new.has(card_id)
	if is_new:
		state.seen_new[card_id] = true
		state.status.text = "NOUVELLE DÉCOUVERTE  ·  %s" % rarity_data.label
		state.status.add_theme_color_override("font_color", UIKit.COLOR_CYAN)
	else:
		state.status.text = "%s  ·  Exemplaire supplémentaire" % rarity_data.label
		state.status.add_theme_color_override("font_color", rarity_data.glow)
	var pulls: Array = state.pulls
	state.next.text = "VOIR TOUTES LES CARTES" if int(state.index) == pulls.size() - 1 else "RÉVÉLER LA SUIVANTE"
	var card_view: CreatureCard = state.card
	card_view.interactive = false
	card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _reveal_tween(card: Control) -> void:
	if not is_instance_valid(card):
		return
	card.pivot_offset = card.size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "scale", Vector2.ONE, 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "rotation", 0.0, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _show_reveal_summary(overlay: Control) -> void:
	if not is_instance_valid(overlay) or not overlay.has_meta("reveal_state"):
		return
	var state: Dictionary = overlay.get_meta("reveal_state")
	state.summary_shown = true
	state.card_center.visible = false
	state.status.visible = false
	state.summary.visible = true
	state.title.text = "%s CARTES AJOUTÉES" % CardDatabase.format_number(int(state.result.amount))
	state.title.add_theme_color_override("font_color", UIKit.COLOR_TEXT)
	var discovery_count := int(state.result.newly_discovered.size())
	state.progress.text = "OUVERTURE TERMINÉE  ·  %d NOUVELLE%s" % [discovery_count, "S" if discovery_count > 1 else ""]
	state.skip.visible = false
	state.next.text = "CONTINUER"
	state.grid_page = 0
	var pulls: Array = state.pulls
	var flipped: Dictionary = state.flipped
	var has_magic := false
	for index in range(pulls.size()):
		flipped[index] = true
		var rarity := str(CardDatabase.get_card(str(pulls[index])).get("rarity", "common"))
		if rarity in ["rare", "epic", "legendary", "unique", "ultimate"]:
			has_magic = true
	if state.has("flip_hint") and is_instance_valid(state.flip_hint):
		state.flip_hint.text = "Touchez une carte pour voir sa fiche."
	_render_reveal_grid(overlay)
	AudioManager.play("flip")
	if has_magic:
		AudioManager.play("magic", 0.18)

func _render_reveal_grid(overlay: Control) -> void:
	if not is_instance_valid(overlay) or not overlay.has_meta("reveal_state"):
		return
	var state: Dictionary = overlay.get_meta("reveal_state")
	var pulls: Array = state.pulls
	var grid: GridContainer = state.grid
	var flipped: Dictionary = state.flipped
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	var total_pages := maxi(1, ceili(float(pulls.size()) / float(REVEAL_PAGE_SIZE)))
	state.grid_page = clampi(int(state.grid_page), 0, total_pages - 1)
	var start_index := int(state.grid_page) * REVEAL_PAGE_SIZE
	var end_index := mini(start_index + REVEAL_PAGE_SIZE, pulls.size())
	var newly: Array = state.result.newly_discovered
	for index in range(start_index, end_index):
		var pull_index := index
		var card_id := str(pulls[pull_index])
		var card := CardDatabase.get_card(card_id)
		var already_flipped := bool(state.summary_shown) or flipped.has(pull_index) or (pull_index in flipped)
		var view := CreatureCardScene.new()
		view.custom_minimum_size = Vector2(188, 248)
		view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		view.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		grid.add_child(view)
		view.show_quantity = false
		view.configure(card, 1, false, true)
		view.set_face_down(not already_flipped)
		if already_flipped and newly.has(card_id):
			view.modulate = Color(1.08, 1.08, 1.02)
		view.flipped.connect(_on_reveal_card_flipped.bind(overlay, pull_index, card_id, view))
		view.card_pressed.connect(func(data: Dictionary) -> void: show_card_details(data))
	state.page_label.text = "GRILLE  ·  PAGE %d / %d  ·  %d CARTES" % [int(state.grid_page) + 1, total_pages, pulls.size()]
	state.grid_prev.disabled = int(state.grid_page) <= 0
	state.grid_next.disabled = int(state.grid_page) >= total_pages - 1
	state.grid_prev.visible = total_pages > 1
	state.grid_next.visible = total_pages > 1


func _on_reveal_card_flipped(data: Dictionary, overlay: Control, pull_index: int, card_id: String, view: CreatureCard) -> void:
	if not is_instance_valid(overlay) or not overlay.has_meta("reveal_state"):
		return
	var state: Dictionary = overlay.get_meta("reveal_state")
	state.flipped[pull_index] = true
	AudioManager.play_rarity(str(data.get("rarity", "common")))
	var newly: Array = state.result.newly_discovered
	if newly.has(card_id) and is_instance_valid(view):
		view.modulate = Color(1.08, 1.08, 1.02)

func show_settings() -> void:
	var overlay := new_overlay()
	var panel := kit.overlay_panel(456, 820)
	overlay.get_node("Center").add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)
	content.add_child(kit.label(Loc.t("settings"), 24, UIKit.COLOR_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	content.add_child(kit.label(Loc.t("sound"), 14, UIKit.COLOR_CYAN))
	var hint := kit.label(Loc.t("sound_hint"), 11, UIKit.COLOR_MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint)
	var volume_label := kit.label(Loc.t("volume") % int(round(AudioManager.volume * 100.0)), 12, UIKit.COLOR_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(volume_label)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = AudioManager.volume * 100.0
	slider.custom_minimum_size.y = 28
	content.add_child(slider)
	var mute := CheckButton.new()
	mute.text = Loc.t("mute")
	mute.button_pressed = AudioManager.is_muted()
	mute.add_theme_font_size_override("font_size", 13)
	content.add_child(mute)
	slider.value_changed.connect(func(value: float) -> void:
		AudioManager.set_volume(value / 100.0)
		volume_label.text = Loc.t("volume") % int(round(value))
		if value > 0.0:
			mute.set_pressed_no_signal(false)
	)
	mute.toggled.connect(func(pressed: bool) -> void:
		AudioManager.set_muted(pressed)
		if not pressed:
			AudioManager.play("click")
	)
	content.add_child(kit.label(Loc.t("language"), 14, UIKit.COLOR_CYAN))
	var langs := HBoxContainer.new()
	langs.add_theme_constant_override("separation", 10)
	content.add_child(langs)
	langs.add_child(_language_button("fr", Loc.t("lang_fr"), "res://assets/ui/flag_fr.svg", overlay))
	langs.add_child(_language_button("en", Loc.t("lang_en"), "res://assets/ui/flag_us.svg", overlay))
	content.add_child(kit.label(Loc.t("market_online_title"), 14, Color("ffd266")))
	var market_hint := kit.label(Loc.t("market_online_hint"), 11, UIKit.COLOR_MUTED)
	market_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(market_hint)
	content.add_child(kit.label(Loc.t("market_server_url"), 12, UIKit.COLOR_TEXT))
	var url_edit := LineEdit.new()
	url_edit.text = GameState.server_url
	url_edit.placeholder_text = "http://127.0.0.1:8787"
	url_edit.custom_minimum_size.y = 44
	url_edit.add_theme_font_size_override("font_size", 13)
	url_edit.text_changed.connect(func(value: String) -> void:
		GameState.server_url = value.strip_edges()
	)
	content.add_child(url_edit)
	var market_row := HBoxContainer.new()
	market_row.add_theme_constant_override("separation", 8)
	content.add_child(market_row)
	var market_status := kit.label(Loc.t("market_connected") % GameState.public_name if GameState.is_market_online() else Loc.t("market_offline"), 11, Color("78e6a0") if GameState.is_market_online() else UIKit.COLOR_MUTED)
	market_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	market_row.add_child(market_status)
	var market_btn := Button.new()
	market_btn.text = Loc.t("market_disconnect") if GameState.is_market_online() else Loc.t("market_connect")
	market_btn.custom_minimum_size = Vector2(130, 48)
	market_btn.add_theme_font_size_override("font_size", 10)
	kit.style_action_button(market_btn, Color("ff8b9d") if GameState.is_market_online() else Color("ffd266"), not GameState.is_market_online())
	market_btn.pressed.connect(_toggle_market.bind(url_edit, overlay))
	market_row.add_child(market_btn)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)
	var close := Button.new()
	close.text = Loc.t("close")
	close.custom_minimum_size.y = 56
	kit.style_action_button(close, UIKit.COLOR_ACCENT, true)
	close.pressed.connect(close_overlay.bind(overlay))
	content.add_child(close)
	fade_in(overlay)

func _toggle_market(url_edit: LineEdit, overlay: Control) -> void:
	GameState.server_url = url_edit.text.strip_edges()
	if GameState.server_url.is_empty():
		GameState.server_url = "http://127.0.0.1:8787"
	if GameState.is_market_online():
		GameState.disconnect_market()
		show_toast(Loc.t("market_offline"), UIKit.COLOR_CYAN)
		close_overlay(overlay)
		call_deferred("show_settings")
		return
	var result: Dictionary = await GameState.connect_market()
	if bool(result.get("ok", false)):
		show_toast(Loc.t("market_connected") % str(result.get("public_name", GameState.public_name)), Color("78e6a0"))
	else:
		show_toast(str(result.get("error", Loc.t("market_no_network"))), Color("ff8b9d"))
	close_overlay(overlay)
	call_deferred("show_settings")

func _language_button(code: String, caption: String, flag_path: String, overlay: Control) -> Button:
	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 70)
	button.text = "  " + caption
	button.icon = load(flag_path)
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 36)
	button.add_theme_font_size_override("font_size", 13)
	var active: bool = Loc.code == code
	kit.style_action_button(button, UIKit.COLOR_CYAN if active else UIKit.COLOR_MUTED, active)
	button.pressed.connect(func() -> void:
		AudioManager.play("click")
		Loc.set_code(code)
		close_overlay(overlay)
		call_deferred("show_settings")
	)
	return button

func show_craft_batch(result: Dictionary) -> void:
	if int(result.get("amount", 1)) <= 1:
		show_reward_card(result.card, Loc.t("craft_ok"), Loc.t("craft_spent") % CardDatabase.format_number(int(result.get("spent", GameState.CRAFT_MISSING_COMMON_COST))))
		return
	var overlay := new_overlay()
	var panel := kit.overlay_panel(440, 560)
	overlay.get_node("Center").add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	content.add_child(kit.label(Loc.t("craft_batch") % CardDatabase.format_number(int(result.amount)), 24, Color("73d6a4"), HORIZONTAL_ALIGNMENT_CENTER))
	content.add_child(kit.label(Loc.t("craft_spent") % CardDatabase.format_number(int(result.spent)), 12, UIKit.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var new_count := int(result.newly_discovered.size())
	var dupes := int(result.amount) - new_count
	var summary := kit.label(Loc.t("craft_new") % [new_count, dupes], 14, UIKit.COLOR_CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(summary)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)
	var close := Button.new()
	close.text = Loc.t("continue")
	close.custom_minimum_size.y = 56
	kit.style_action_button(close, Color("73d6a4"), true)
	close.pressed.connect(close_overlay.bind(overlay))
	content.add_child(close)
	fade_in(overlay)
	AudioManager.play("fusion")

func show_tutorial() -> void:
	var tracked := GameState.get_tracked_quest()
	if tracked.is_empty():
		return
	show_toast(str(tracked.get("hint", tracked.get("description", ""))), UIKit.COLOR_CYAN)

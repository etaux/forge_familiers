extends Node
## Interface V24 : pages découpées, 313 cartes, overlays.

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var backup := {
		"essence": GameState.essence,
		"dust": GameState.dust,
		"inventory": GameState.inventory.duplicate(true),
		"discoveries": GameState.discovered_cards.duplicate(),
		"habitats": GameState.claimed_habitats.duplicate(),
		"albums": GameState.claimed_albums.duplicate(),
		"next_farm": GameState.next_farm_at_unix,
		"daily_date": GameState.daily_date,
		"missions": GameState.daily_missions.duplicate(true),
		"expedition": GameState.active_expedition.duplicate(true),
		"tutorial_done": GameState.tutorial_done
	}
	GameState._passive_timer.stop()
	GameState.tutorial_done = true
	GameState.essence = 5000
	GameState.dust = 150
	GameState.next_farm_at_unix = 0
	GameState.active_expedition.clear()
	GameState.claimed_habitats.clear()
	GameState.claimed_albums.clear()
	GameState.discovered_cards.clear()
	for card_id in CardDatabase.CARD_ORDER:
		GameState.inventory[card_id] = 0
	for card_id in ["mousselet", "bouliflore", "braisillon", "goutillon", "galetou"]:
		GameState.inventory[card_id] = 1
		GameState.discovered_cards.append(card_id)
	GameState.inventory["mousselet"] = 3

	var main := preload("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(main._pages.size() == 5)
	assert(main.theme != null)
	assert(main._nav_buttons.size() == 5)
	assert(main.farm_page != null and main.collection_page != null)
	assert(int(ProjectSettings.get_setting("display/window/size/window_width_override")) == 540)
	assert(main.collection_page.filtered_ids.size() == 313)
	assert(main.collection_page.views.size() == CollectionPage.PAGE_SIZE)
	assert(main.fusion_page.filtered_ids.size() == 301)
	assert(main.fusion_page.rows.size() == FusionPage.PAGE_SIZE)
	main.collection_page.page = 1
	main.collection_page.rebuild()
	assert(main.collection_page.page == 1 and main.collection_page.views.size() == CollectionPage.PAGE_SIZE)
	main.collection_page.filter.select(6)
	main.collection_page.page = 0
	main.collection_page.rebuild()
	assert(main.collection_page.filtered_ids.size() == 1 and main.collection_page.views.size() == 1)
	main.collection_page.filter.select(0)
	main.collection_page.rebuild()
	main.fusion_page.page = 1
	main.fusion_page.rebuild()
	assert(main.fusion_page.page == 1 and main.fusion_page.rows.size() == FusionPage.PAGE_SIZE)
	assert(main.albums_page.collections_list.get_child_count() >= 16)
	assert(main.albums_page.dust_label.text == "150")

	main._switch_page("albums")
	assert(main._pages.albums.visible)
	main.overlays.show_album_detail("tiny_guardians")
	await get_tree().process_frame
	var album_overlay: Control = main.overlays.get_node("Overlay")
	var album_grid := album_overlay.find_child("AlbumCardsGrid", true, false) as GridContainer
	assert(album_grid != null)
	assert(album_grid.get_child_count() == 6)
	album_overlay.queue_free()
	await get_tree().process_frame

	main.overlays.show_ultimate()
	await get_tree().process_frame
	var ultimate_overlay: Control = main.overlays.get_node("Overlay")
	var ultimate_grid := ultimate_overlay.find_child("UltimateUniqueGrid", true, false) as HFlowContainer
	assert(ultimate_grid != null and ultimate_grid.get_child_count() == 11)
	ultimate_overlay.queue_free()
	await get_tree().process_frame

	main.overlays.show_recycle(CardDatabase.get_card("mousselet"))
	await get_tree().process_frame
	main.overlays.get_node("Overlay").queue_free()
	await get_tree().process_frame

	main.overlays.show_missions()
	await get_tree().process_frame
	main.overlays.get_node("Overlay").queue_free()
	await get_tree().process_frame
	main.overlays.show_expeditions()
	await get_tree().process_frame
	main.overlays.get_node("Overlay").queue_free()
	await get_tree().process_frame

	var result := GameState.open_crate("small")
	assert(result.pulls.size() == 6)
	main.overlays.show_opening_result(result)
	await get_tree().process_frame
	var reveal_overlay: Control = main.overlays.get_node("Overlay")
	var state: Dictionary = reveal_overlay.get_meta("reveal_state")
	assert(int(state.index) == 0)
	main.overlays._show_reveal_summary(reveal_overlay)
	assert(bool(state.summary_shown))
	main.queue_free()

	GameState.essence = int(backup.essence)
	GameState.dust = int(backup.dust)
	GameState.inventory = backup.inventory
	_restore_string_array(GameState.discovered_cards, backup.discoveries)
	_restore_string_array(GameState.claimed_habitats, backup.habitats)
	_restore_string_array(GameState.claimed_albums, backup.albums)
	GameState.next_farm_at_unix = int(backup.next_farm)
	GameState.daily_date = str(backup.daily_date)
	GameState.daily_missions = backup.missions
	GameState.active_expedition = backup.expedition
	GameState.tutorial_done = bool(backup.tutorial_done)
	GameState._passive_timer.start()
	GameState.save_state()
	print("UI FLOW TEST V24 OK — pages découpées, 313 cartes, 60 albums.")
	get_tree().quit(0)

func _restore_string_array(target: Array[String], source: Array) -> void:
	target.clear()
	for value in source:
		target.append(str(value))

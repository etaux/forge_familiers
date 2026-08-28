extends Node
## Vérifie l’interface V4 : recyclage, habitats, albums, missions et révélations.

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
		"expedition": GameState.active_expedition.duplicate(true)
	}
	GameState._passive_timer.stop()
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
	assert(main.theme != null and main.theme.default_font != null)
	assert(main._nav_buttons.size() == 5)
	assert(int(ProjectSettings.get_setting("display/window/size/window_width_override")) == 540)
	assert(int(ProjectSettings.get_setting("display/window/size/window_height_override")) == 960)
	# Les catalogues sont chargés par pages, jamais en totalité dans l’interface.
	assert(main._filtered_collection_ids.size() == 214)
	assert(main._collection_views.size() == main.COLLECTION_PAGE_SIZE)
	assert(main._filtered_fusion_ids.size() == 202)
	assert(main._fusion_rows.size() == main.FUSION_PAGE_SIZE)
	main._on_collection_next_page()
	assert(main._collection_page == 1 and main._collection_views.size() == main.COLLECTION_PAGE_SIZE)
	main._collection_filter.select(6) # Rang Ultime.
	main._on_collection_filter_changed(6)
	assert(main._filtered_collection_ids.size() == 1 and main._collection_views.size() == 1)
	main._collection_filter.select(0)
	main._on_collection_filter_changed(0)
	main._on_fusion_next_page()
	assert(main._fusion_page == 1 and main._fusion_rows.size() == main.FUSION_PAGE_SIZE)
	assert(main._collections_list != null)
	assert(main._collections_list.get_child_count() >= 16)
	assert(main._dust_label.text == "150")

	# Page Habitats & Albums.
	main._switch_page("albums")
	assert(main._pages.albums.visible)
	assert(main._craft_common_button != null)
	main._show_album_detail("tiny_guardians")
	await get_tree().process_frame
	var album_overlay: Control = main.get_node("Overlay")
	var album_grid := album_overlay.find_child("AlbumCardsGrid", true, false) as GridContainer
	assert(album_grid != null)
	assert(album_grid.get_child_count() == 6, "L’album doit afficher ses six cartes consultables.")
	album_overlay.queue_free()
	await get_tree().process_frame

	# Objectif permanent et aperçu des onze cartes Uniques requises.
	assert(main._ultimate_goal_button != null)
	main._show_ultimate_goal_overlay()
	await get_tree().process_frame
	var ultimate_overlay: Control = main.get_node("Overlay")
	var ultimate_grid := ultimate_overlay.find_child("UltimateUniqueGrid", true, false) as HFlowContainer
	assert(ultimate_grid != null and ultimate_grid.get_child_count() == 11)
	ultimate_overlay.queue_free()
	await get_tree().process_frame

	# Fenêtre de recyclage d’un doublon.
	main._show_recycle_overlay(CardDatabase.get_card("mousselet"))
	await get_tree().process_frame
	var recycle_overlay: Control = main.get_node("Overlay")
	assert(recycle_overlay != null)
	recycle_overlay.queue_free()
	await get_tree().process_frame

	# Interfaces missions et expéditions.
	main._show_missions_overlay()
	await get_tree().process_frame
	var mission_overlay: Control = main.get_node("Overlay")
	mission_overlay.queue_free()
	await get_tree().process_frame
	main._show_expeditions_overlay()
	await get_tree().process_frame
	var expedition_overlay: Control = main.get_node("Overlay")
	expedition_overlay.queue_free()
	await get_tree().process_frame

	# Ouverture séquentielle et récapitulatif.
	var result := GameState.open_crate("small")
	assert(result.pulls.size() == 6)
	main._show_opening_result(result)
	await get_tree().process_frame
	var reveal_overlay: Control = main.get_node("Overlay")
	var state: Dictionary = reveal_overlay.get_meta("reveal_state")
	assert(int(state.index) == 0)
	for _step in range(result.pulls.size()):
		main._advance_reveal(reveal_overlay)
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
	GameState._passive_timer.start()
	GameState.save_state()
	print("UI FLOW TEST V23 OK — 100 rares, pagination mobile et 214 cartes actuelles.")
	get_tree().quit(0)

func _restore_string_array(target: Array[String], source: Array) -> void:
	target.clear()
	for value in source:
		target.append(str(value))

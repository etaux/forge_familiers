extends Node
## Test V24 : 313 cartes, pity, fusion rééquilibrée, expédition avec équipe.

func _ready() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var backup := {
		"essence": GameState.essence,
		"market_coins": GameState.market_coins,
		"dust": GameState.dust,
		"inventory": GameState.inventory.duplicate(true),
		"reserved": GameState.reserved.duplicate(true),
		"discovered_cards": GameState.discovered_cards.duplicate(),
		"claimed_habitats": GameState.claimed_habitats.duplicate(),
		"claimed_albums": GameState.claimed_albums.duplicate(),
		"card_mastery": GameState.card_mastery.duplicate(true),
		"pity_counts": GameState.pity_counts.duplicate(true),
		"lifetime_cards": GameState.lifetime_cards,
		"lifetime_crates": GameState.lifetime_crates,
		"lifetime_fusions": GameState.lifetime_fusions,
		"farm_actions": GameState.farm_actions,
		"market_purchases": GameState.market_purchases,
		"selected_crate": GameState.selected_crate,
		"market_listings": GameState.market_listings.duplicate(true),
		"market_initialized": GameState.market_initialized,
		"tutorial_done": GameState.tutorial_done,
		"next_farm_at_unix": GameState.next_farm_at_unix,
		"last_seen_unix": GameState.last_seen_unix,
		"pending_offline_essence": GameState.pending_offline_essence,
		"daily_date": GameState.daily_date,
		"daily_missions": GameState.daily_missions.duplicate(true),
		"active_expedition": GameState.active_expedition.duplicate(true),
		"farm_yield_level": GameState.farm_yield_level,
		"farm_speed_level": GameState.farm_speed_level,
		"farm_passive_level": GameState.farm_passive_level,
		"luck_level": GameState.luck_level,
		"quest_progress": GameState.quest_progress.duplicate(true),
		"claimed_quests": GameState.claimed_quests.duplicate()
	}
	GameState._passive_timer.stop()

	assert(CardDatabase.get_cards_for_rarity("common").size() == 100)
	assert(CardDatabase.get_cards_for_rarity("rare").size() == 100)
	assert(CardDatabase.get_cards_for_rarity("epic").size() == 100)
	assert(CardDatabase.get_cards_for_rarity("legendary").size() == 1)
	assert(CardDatabase.get_cards_for_rarity("unique").size() == 11)
	assert(CardDatabase.get_cards_for_rarity("ultimate").size() == 1)
	assert(CardDatabase.CARD_ORDER.size() == 313)
	assert(CardDatabase.HABITAT_ORDER.size() == 7)
	assert(CardDatabase.ALBUM_ORDER.size() == 60)
	assert(CardDatabase.get_fusion_cost("common") == 10)
	assert(CardDatabase.get_fusion_cost("rare") == 10)
	assert(CardDatabase.get_fusion_cost("epic") == 8)
	assert(CardDatabase.get_fusion_cost("legendary") == 5)
	assert(is_equal_approx(CardDatabase.get_card_drop_rate("chroma_zero"), 0.01 / 11.0))
	var habitat_cards: Array[String] = []
	for habitat_id in CardDatabase.HABITAT_ORDER:
		for card_id in CardDatabase.get_habitat(habitat_id).card_ids:
			assert(CardDatabase.CARDS.has(str(card_id)))
			assert(not habitat_cards.has(str(card_id)), "Une carte ne doit appartenir qu’à un habitat.")
			habitat_cards.append(str(card_id))
	assert(habitat_cards.size() == 313, "Les habitats doivent couvrir les 313 cartes.")
	assert(int(CardDatabase.get_habitat("waters").expedition_bonus_percent) == 9)
	assert(int(CardDatabase.get_habitat("embers").expedition_bonus_percent) == 3)
	assert(int(CardDatabase.get_habitat("chrome_archive").expedition_bonus_percent) == 10)

	assert(GameState.STARTING_ESSENCE == 200)
	assert(GameState.FARM_REWARD == 2)
	GameState.essence = 200
	GameState.farm_yield_level = 0
	GameState.farm_speed_level = 0
	GameState.farm_passive_level = 0
	GameState.luck_level = 0
	GameState.next_farm_at_unix = 0
	assert(GameState.farm().ok)
	assert(GameState.essence == 202)
	assert(not GameState.farm().ok)

	GameState.daily_date = Time.get_date_string_from_system()
	GameState.daily_missions = [{"id":"test_harvest","type":"harvest","label":"Test","description":"Test","target":2,"reward_type":"essence","reward":75,"progress":0,"claimed":false}]
	GameState._add_mission_progress("harvest", 2)
	assert(GameState.claim_mission("test_harvest").ok)

	GameState.essence = 20_000
	_clear_inventory()
	_clear_discoveries()
	var expected_total := 0
	for crate_id in CardDatabase.CRATE_ORDER:
		var result := GameState.open_crate(crate_id)
		assert(result.ok)
		assert(result.pulls.size() == int(CardDatabase.CRATES[crate_id].cards))
		expected_total += int(CardDatabase.CRATES[crate_id].cards)
	assert(GameState.get_total_cards() == expected_total)

	# Pity dur : Unique garantie.
	_clear_inventory()
	GameState.pity_counts = {"rare": 0, "epic": 0, "legendary": 0, "unique": 8000}
	var pity_roll := GameState.roll_rarity_with_pity()
	assert(str(pity_roll.rarity) == "unique" and bool(pity_roll.pity))
	assert(int(GameState.pity_counts.unique) == 0)

	# Fusion rééquilibrée : 10 rares identiques → 1 épique.
	_clear_inventory()
	GameState.inventory["mousselet"] = 10
	assert(GameState.fuse("mousselet").ok)
	_clear_inventory()
	GameState.inventory["cristaloup"] = 10
	assert(GameState.fuse_all().ok)
	assert(GameState.get_rarity_count("epic") == 1)
	_clear_inventory()
	GameState.inventory["noctilux"] = 8
	assert(GameState.fuse("noctilux").ok)
	assert(GameState.get_rarity_count("legendary") == 1)
	_clear_inventory()
	GameState.inventory["solgriffon"] = 5
	assert(GameState.fuse("solgriffon").ok)
	assert(GameState.get_rarity_count("unique") == 1)

	# Expédition avec équipe choisie, séquestre et maîtrise.
	_clear_inventory()
	_clear_discoveries()
	GameState.reserved.clear()
	GameState.card_mastery.clear()
	GameState.claimed_habitats.clear()
	GameState.active_expedition.clear()
	for card_id in ["mousselet", "bouliflore", "braisillon", "goutillon", "galetou"]:
		GameState.inventory[card_id] = 1
		GameState.discovered_cards.append(card_id)
	assert(not GameState.start_expedition("long").ok)
	var team: Array[String] = ["mousselet", "bouliflore", "braisillon", "goutillon", "galetou"]
	assert(GameState.start_expedition("long", team).ok)
	assert(GameState.get_reserved_count("mousselet") == 1)
	assert(GameState.get_available_count("mousselet") == 0)
	assert(not GameState.fuse("mousselet").ok)
	GameState.active_expedition.ends_at = int(Time.get_unix_time_from_system()) - 1
	assert(GameState.claim_expedition().ok)
	assert(GameState.get_reserved_count("mousselet") == 0)
	assert(GameState.get_mastery_xp("mousselet") == 1)
	assert(GameState.get_mastery_level("mousselet") == 1)

	# Recyclage.
	_clear_inventory()
	_clear_discoveries()
	GameState.inventory["mousselet"] = 3
	GameState.discovered_cards.append("mousselet")
	GameState.dust = 0
	var recycle := GameState.recycle_duplicates("mousselet", 2)
	assert(recycle.ok and int(recycle.reward) == 2)
	assert(GameState.get_card_count("mousselet") == 1)

	GameState.dust = 100
	var craft := GameState.craft_missing_common()
	assert(craft.ok and bool(craft.new))

	GameState.claimed_habitats.clear()
	GameState.dust = 0
	var forest := CardDatabase.get_habitat("forest")
	_set_discoveries(forest.card_ids)
	var habitat_reward := GameState.claim_habitat("forest")
	assert(habitat_reward.ok)
	assert(GameState.get_expedition_bonus_percent() == 6)

	GameState.claimed_albums.clear()
	var album := CardDatabase.get_album("tiny_guardians")
	_set_discoveries(album.card_ids)
	GameState.essence = 0
	GameState.market_coins = 0
	GameState.dust = 0
	assert(GameState.claim_album("tiny_guardians").ok)

	_clear_inventory()
	_clear_discoveries()
	for card in CardDatabase.get_cards_for_rarity("unique"):
		GameState.inventory[card.id] = 1
		GameState.discovered_cards.append(str(card.id))
	var ultimate_reward := GameState.claim_ultimate_goal()
	assert(ultimate_reward.ok)
	assert(str(ultimate_reward.card.id) == "aeternum")
	assert(not GameState.create_market_listing("aeternum", 1, 999999).ok)

	_clear_inventory()
	GameState.inventory["mousselet"] = 3
	var sale := GameState.create_market_listing("mousselet", 2, 75)
	assert(sale.ok and GameState.get_card_count("mousselet") == 1)
	assert(GameState.cancel_market_listing(str(sale.listing.id)).ok)

	var rng := RandomNumberGenerator.new()
	rng.seed = 4_704_026
	var counts := {"common": 0, "rare": 0, "epic": 0, "legendary": 0, "unique": 0}
	var sample_size := 500_000
	for _index in range(sample_size):
		var rarity := CardDatabase.roll_rarity(rng)
		counts[rarity] = int(counts[rarity]) + 1
	assert(abs(int(counts.common) - 446_950) < 2_000)
	assert(abs(int(counts.rare) - 50_000) < 1_400)
	assert(abs(int(counts.epic) - 2_500) < 260)
	assert(abs(int(counts.legendary) - 500) < 100)
	assert(abs(int(counts.unique) - 50) < 35)

	_restore_backup(backup)
	print("SMOKE TEST V24 OK — 313 cartes, 100 épiques, pity, fusion ×10/10/8/5.")
	get_tree().quit(0)

func _clear_inventory() -> void:
	GameState.inventory.clear()
	GameState.reserved.clear()
	for card_id in CardDatabase.CARD_ORDER:
		GameState.inventory[card_id] = 0

func _clear_discoveries() -> void:
	GameState.discovered_cards.clear()

func _set_discoveries(card_ids: Array) -> void:
	GameState.discovered_cards.clear()
	for card_id in card_ids:
		GameState.discovered_cards.append(str(card_id))

func _restore_string_array(target: Array[String], source: Array) -> void:
	target.clear()
	for value in source:
		target.append(str(value))

func _restore_backup(backup: Dictionary) -> void:
	GameState.essence = int(backup.essence)
	GameState.market_coins = int(backup.market_coins)
	GameState.dust = int(backup.dust)
	GameState.inventory = backup.inventory
	GameState.reserved = backup.reserved
	_restore_string_array(GameState.discovered_cards, backup.discovered_cards)
	_restore_string_array(GameState.claimed_habitats, backup.claimed_habitats)
	_restore_string_array(GameState.claimed_albums, backup.claimed_albums)
	GameState.card_mastery = backup.card_mastery
	GameState.pity_counts = backup.pity_counts
	GameState.lifetime_cards = int(backup.lifetime_cards)
	GameState.lifetime_crates = int(backup.lifetime_crates)
	GameState.lifetime_fusions = int(backup.lifetime_fusions)
	GameState.farm_actions = int(backup.farm_actions)
	GameState.market_purchases = int(backup.market_purchases)
	GameState.selected_crate = str(backup.selected_crate)
	GameState.market_listings = backup.market_listings
	GameState.market_initialized = bool(backup.market_initialized)
	GameState.tutorial_done = bool(backup.tutorial_done)
	GameState.next_farm_at_unix = int(backup.next_farm_at_unix)
	GameState.last_seen_unix = int(backup.last_seen_unix)
	GameState.pending_offline_essence = int(backup.pending_offline_essence)
	GameState.daily_date = str(backup.daily_date)
	GameState.daily_missions = backup.daily_missions
	GameState.active_expedition = backup.active_expedition
	GameState.farm_yield_level = int(backup.farm_yield_level)
	GameState.farm_speed_level = int(backup.farm_speed_level)
	GameState.farm_passive_level = int(backup.farm_passive_level)
	GameState.luck_level = int(backup.luck_level)
	GameState.quest_progress = backup.quest_progress
	GameState.claimed_quests.clear()
	for quest_id in backup.claimed_quests:
		GameState.claimed_quests.append(str(quest_id))
	GameState._passive_timer.start()
	GameState.save_state()

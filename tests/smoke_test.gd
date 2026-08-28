extends Node
## Test V4 : économie, recyclage, habitats, albums, missions, expéditions et marché.

func _ready() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var backup := {
		"essence": GameState.essence,
		"market_coins": GameState.market_coins,
		"dust": GameState.dust,
		"inventory": GameState.inventory.duplicate(true),
		"discovered_cards": GameState.discovered_cards.duplicate(),
		"claimed_habitats": GameState.claimed_habitats.duplicate(),
		"claimed_albums": GameState.claimed_albums.duplicate(),
		"lifetime_cards": GameState.lifetime_cards,
		"lifetime_crates": GameState.lifetime_crates,
		"lifetime_fusions": GameState.lifetime_fusions,
		"farm_actions": GameState.farm_actions,
		"market_purchases": GameState.market_purchases,
		"selected_crate": GameState.selected_crate,
		"market_listings": GameState.market_listings.duplicate(true),
		"market_initialized": GameState.market_initialized,
		"next_farm_at_unix": GameState.next_farm_at_unix,
		"last_seen_unix": GameState.last_seen_unix,
		"pending_offline_essence": GameState.pending_offline_essence,
		"daily_date": GameState.daily_date,
		"daily_missions": GameState.daily_missions.duplicate(true),
		"active_expedition": GameState.active_expedition.duplicate(true)
	}
	GameState._passive_timer.stop()

	# Catalogue et définitions de collections.
	assert(CardDatabase.get_cards_for_rarity("common").size() == 100)
	assert(CardDatabase.get_cards_for_rarity("rare").size() == 100)
	assert(CardDatabase.get_cards_for_rarity("unique").size() == 11)
	assert(CardDatabase.get_cards_for_rarity("ultimate").size() == 1)
	assert(CardDatabase.CARD_ORDER.size() == 214)
	assert(CardDatabase.HABITAT_ORDER.size() == 7)
	assert(CardDatabase.ALBUM_ORDER.size() == 40)
	assert(is_equal_approx(CardDatabase.get_card_drop_rate("chroma_zero"), 0.01 / 11.0))
	var habitat_cards: Array[String] = []
	for habitat_id in CardDatabase.HABITAT_ORDER:
		for card_id in CardDatabase.get_habitat(habitat_id).card_ids:
			assert(CardDatabase.CARDS.has(str(card_id)))
			assert(not habitat_cards.has(str(card_id)), "Une carte ne doit appartenir qu’à un habitat.")
			habitat_cards.append(str(card_id))
	assert(habitat_cards.size() == 214, "Les habitats doivent couvrir les 214 cartes.")

	# Économie V3 conservée.
	assert(GameState.STARTING_ESSENCE == 200)
	assert(GameState.FARM_REWARD == 2)
	assert(GameState.FARM_COOLDOWN_SECONDS == 10)
	assert(int(CardDatabase.CRATES.small.cost) == 150)
	assert(int(CardDatabase.CRATES.titan.cost) == 850)
	GameState.essence = 200
	GameState.next_farm_at_unix = 0
	assert(GameState.farm().ok)
	assert(GameState.essence == 202)
	assert(not GameState.farm().ok)
	GameState.next_farm_at_unix = 0
	GameState.essence = 0
	GameState._apply_offline_income(int(Time.get_unix_time_from_system()) - 100)
	assert(GameState.pending_offline_essence == 10 and GameState.essence == 10)
	GameState.consume_offline_reward()

	# Mission contrôlée.
	GameState.daily_date = Time.get_date_string_from_system()
	GameState.daily_missions = [{"id":"test_harvest","type":"harvest","label":"Test","description":"Test","target":2,"reward_type":"essence","reward":75,"progress":0,"claimed":false}]
	GameState._add_mission_progress("harvest", 2)
	assert(GameState.claim_mission("test_harvest").ok)

	# Caisses 6 / 15 / 25 / 50.
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
	assert(GameState.get_discovered_count() > 0)

	# Fusion simple et cascade.
	_clear_inventory()
	GameState.inventory["mousselet"] = 10
	GameState.inventory["bouliflore"] = 9
	assert(GameState.fuse("mousselet").ok)
	assert(not GameState.fuse("bouliflore").ok)
	# Chaque seuil supérieur est vérifié séparément car le résultat aléatoire
	# d’une fusion ne complète plus forcément une carte précise du rang suivant.
	_clear_inventory()
	GameState.inventory["cristaloup"] = 500
	assert(GameState.fuse_all().ok)
	assert(GameState.get_rarity_count("epic") == 1)
	_clear_inventory()
	GameState.inventory["noctilux"] = 1000
	assert(GameState.fuse("noctilux").ok)
	assert(GameState.get_rarity_count("legendary") == 1)
	_clear_inventory()
	GameState.inventory["solgriffon"] = 10000
	assert(GameState.fuse("solgriffon").ok)
	assert(GameState.get_rarity_count("unique") == 1)

	# Expédition sans bonus d’habitat.
	_clear_inventory()
	_clear_discoveries()
	GameState.claimed_habitats.clear()
	for card_id in ["mousselet", "bouliflore", "braisillon", "goutillon", "galetou"]:
		GameState.inventory[card_id] = 1
		GameState.discovered_cards.append(card_id)
	GameState.active_expedition.clear()
	assert(GameState.start_expedition("long").ok)
	assert(int(GameState.active_expedition.reward) == 500)
	GameState.active_expedition.ends_at = int(Time.get_unix_time_from_system()) - 1
	assert(GameState.claim_expedition().ok)

	# Recyclage : deux doublons communs donnent deux poussières et gardent une copie.
	_clear_inventory()
	_clear_discoveries()
	GameState.inventory["mousselet"] = 3
	GameState.discovered_cards.append("mousselet")
	GameState.dust = 0
	var recycle := GameState.recycle_duplicates("mousselet", 2)
	assert(recycle.ok and int(recycle.reward) == 2)
	assert(GameState.get_card_count("mousselet") == 1)
	assert(GameState.dust == 2)
	assert(GameState.is_card_discovered("mousselet"))

	# Invocation d’une commune manquante avec cent poussières.
	GameState.dust = 100
	var discovered_before := GameState.get_discovered_count()
	var craft := GameState.craft_missing_common()
	assert(craft.ok and bool(craft.new))
	assert(GameState.dust == 0)
	assert(GameState.get_discovered_count() == discovered_before + 1)

	# Habitat complet : récompense et bonus permanent de 5 %.
	GameState.claimed_habitats.clear()
	GameState.dust = 0
	var forest := CardDatabase.get_habitat("forest")
	_set_discoveries(forest.card_ids)
	var habitat_reward := GameState.claim_habitat("forest")
	assert(habitat_reward.ok)
	assert(GameState.dust == int(forest.reward_dust))
	assert(GameState.get_expedition_bonus_percent() == 5)
	assert(GameState.get_expedition_reward("long") == 525)

	# Album complet : récompenses uniques dans les trois monnaies.
	GameState.claimed_albums.clear()
	var album := CardDatabase.get_album("tiny_guardians")
	_set_discoveries(album.card_ids)
	GameState.essence = 0
	GameState.market_coins = 0
	GameState.dust = 0
	var album_reward := GameState.claim_album("tiny_guardians")
	assert(album_reward.ok)
	assert(GameState.essence == int(album.reward_essence))
	assert(GameState.market_coins == int(album.reward_coins))
	assert(GameState.dust == int(album.reward_dust))
	assert(not GameState.claim_album("tiny_guardians").ok)

	# Objectif permanent : les 11 Uniques permettent de forger AETERNUM une seule fois.
	_clear_inventory()
	_clear_discoveries()
	for card in CardDatabase.get_cards_for_rarity("unique"):
		GameState.inventory[card.id] = 1
		GameState.discovered_cards.append(str(card.id))
	var ultimate_progress := GameState.get_ultimate_goal_progress()
	assert(bool(ultimate_progress.ready) and int(ultimate_progress.discovered) == 11)
	var ultimate_reward := GameState.claim_ultimate_goal()
	assert(ultimate_reward.ok)
	assert(str(ultimate_reward.card.id) == "aeternum")
	assert(GameState.get_card_count("aeternum") == 1)
	assert(GameState.is_card_discovered("aeternum"))
	assert(not GameState.claim_ultimate_goal().ok)
	assert(not GameState.create_market_listing("aeternum", 1, 999999).ok)
	assert(GameState.get_recyclable_count("aeternum") == 0)

	# Marché local et séquestre.
	_clear_inventory()
	GameState.inventory["mousselet"] = 3
	var sale := GameState.create_market_listing("mousselet", 2, 75)
	assert(sale.ok and GameState.get_card_count("mousselet") == 1)
	assert(GameState.cancel_market_listing(str(sale.listing.id)).ok)
	assert(GameState.get_card_count("mousselet") == 3)

	# Contrôle statistique des taux.
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
	print("SMOKE TEST V23 OK — 100 rares, 214 cartes et %d tirages validés." % sample_size)
	get_tree().quit(0)

func _clear_inventory() -> void:
	GameState.inventory.clear()
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
	_restore_string_array(GameState.discovered_cards, backup.discovered_cards)
	_restore_string_array(GameState.claimed_habitats, backup.claimed_habitats)
	_restore_string_array(GameState.claimed_albums, backup.claimed_albums)
	GameState.lifetime_cards = int(backup.lifetime_cards)
	GameState.lifetime_crates = int(backup.lifetime_crates)
	GameState.lifetime_fusions = int(backup.lifetime_fusions)
	GameState.farm_actions = int(backup.farm_actions)
	GameState.market_purchases = int(backup.market_purchases)
	GameState.selected_crate = str(backup.selected_crate)
	GameState.market_listings = backup.market_listings
	GameState.market_initialized = bool(backup.market_initialized)
	GameState.next_farm_at_unix = int(backup.next_farm_at_unix)
	GameState.last_seen_unix = int(backup.last_seen_unix)
	GameState.pending_offline_essence = int(backup.pending_offline_essence)
	GameState.daily_date = str(backup.daily_date)
	GameState.daily_missions = backup.daily_missions
	GameState.active_expedition = backup.active_expedition
	GameState._passive_timer.start()
	GameState.save_state()

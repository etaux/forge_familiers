extends Node
## Économie V3, inventaire, tirages, missions, expéditions, fusion et marché local.

signal essence_changed(value: int)
signal coins_changed(value: int)
signal inventory_changed
signal market_changed
signal farm_state_changed
signal missions_changed
signal expedition_changed
signal dust_changed(value: int)
signal collections_changed

const SAVE_PATH := "user://forge_familiers_save.json"
const SAVE_VERSION := 4
const STARTING_ESSENCE := 200
const STARTING_MARKET_COINS := 2500
const FARM_REWARD := 2
const FARM_COOLDOWN_SECONDS := 10
const PASSIVE_REWARD := 1
const PASSIVE_INTERVAL_SECONDS := 10
const OFFLINE_CAP_SECONDS := 8 * 60 * 60
const REAL_MONEY_ENABLED := false
const ULTIMATE_CARD_ID := "aeternum"
const CRAFT_MISSING_COMMON_COST := 100
const RECYCLE_VALUES := {
	"common": 1,
	"rare": 25,
	"epic": 250,
	"legendary": 2500,
	"unique": 10000
}

const MISSION_POOL := [
	{"id": "harvest", "type": "harvest", "label": "Récolteur patient", "description": "Effectuer 3 récoltes manuelles", "target": 3, "reward_type": "essence", "reward": 75},
	{"id": "crates", "type": "crates", "label": "Ouvreur de caisses", "description": "Ouvrir 2 caisses Origine", "target": 2, "reward_type": "essence", "reward": 120},
	{"id": "cards", "type": "cards", "label": "Grande découverte", "description": "Révéler 30 cartes", "target": 30, "reward_type": "essence", "reward": 150},
	{"id": "fusion", "type": "fusion", "label": "Alchimiste", "description": "Réaliser 1 fusion", "target": 1, "reward_type": "essence", "reward": 200},
	{"id": "listing", "type": "listing", "label": "Petit marchand", "description": "Publier 1 offre sur le marché", "target": 1, "reward_type": "coins", "reward": 100},
	{"id": "expedition", "type": "expedition", "label": "Explorateur", "description": "Terminer 1 expédition", "target": 1, "reward_type": "essence", "reward": 180}
]

const EXPEDITIONS := {
	"short": {"label": "BALADE", "duration_seconds": 30 * 60, "duration_label": "30 MIN", "reward": 50, "cards_required": 1},
	"medium": {"label": "EXPLORATION", "duration_seconds": 2 * 60 * 60, "duration_label": "2 HEURES", "reward": 180, "cards_required": 3},
	"long": {"label": "GRANDE QUÊTE", "duration_seconds": 8 * 60 * 60, "duration_label": "8 HEURES", "reward": 500, "cards_required": 5}
}

var essence: int = STARTING_ESSENCE
var market_coins: int = STARTING_MARKET_COINS
var dust: int = 0
var inventory: Dictionary = {}
var discovered_cards: Array[String] = []
var claimed_habitats: Array[String] = []
var claimed_albums: Array[String] = []
var lifetime_cards: int = 0
var lifetime_crates: int = 0
var lifetime_fusions: int = 0
var farm_actions: int = 0
var market_purchases: int = 0
var selected_crate: String = "small"
var market_listings: Array[Dictionary] = []
var market_initialized: bool = false

var next_farm_at_unix: int = 0
var last_seen_unix: int = 0
var pending_offline_essence: int = 0
var daily_date: String = ""
var daily_missions: Array[Dictionary] = []
var active_expedition: Dictionary = {}

var _rng := RandomNumberGenerator.new()
var _save_timer: Timer
var _passive_timer: Timer

func _ready() -> void:
	_rng.randomize()
	_initialize_inventory()
	load_state()
	_migrate_discoveries_from_inventory()
	_ensure_daily_missions()
	_initialize_market_if_needed()

	_save_timer = Timer.new()
	_save_timer.wait_time = 4.0
	_save_timer.autostart = true
	_save_timer.timeout.connect(save_state)
	add_child(_save_timer)

	_passive_timer = Timer.new()
	_passive_timer.wait_time = PASSIVE_INTERVAL_SECONDS
	_passive_timer.autostart = true
	_passive_timer.timeout.connect(_on_passive_tick)
	add_child(_passive_timer)

func _initialize_inventory() -> void:
	for card_id in CardDatabase.CARD_ORDER:
		if not inventory.has(card_id):
			inventory[card_id] = 0

func _migrate_discoveries_from_inventory() -> void:
	for card_id in CardDatabase.CARD_ORDER:
		if get_card_count(card_id) > 0 and not discovered_cards.has(card_id):
			discovered_cards.append(card_id)

func _mark_discovered(card_id: String, notify: bool = true) -> bool:
	if discovered_cards.has(card_id):
		return false
	discovered_cards.append(card_id)
	if notify:
		collections_changed.emit()
	return true

func is_card_discovered(card_id: String) -> bool:
	return discovered_cards.has(card_id)

# -----------------------------------------------------------------------------
# Économie et récolte
# -----------------------------------------------------------------------------

func can_farm() -> bool:
	return int(Time.get_unix_time_from_system()) >= next_farm_at_unix

func get_farm_cooldown() -> int:
	return maxi(0, next_farm_at_unix - int(Time.get_unix_time_from_system()))

func farm() -> Dictionary:
	if not can_farm():
		return {"ok": false, "remaining": get_farm_cooldown(), "error": "La récolte se recharge."}
	essence += FARM_REWARD
	farm_actions += 1
	next_farm_at_unix = int(Time.get_unix_time_from_system()) + FARM_COOLDOWN_SECONDS
	_add_mission_progress("harvest", 1)
	essence_changed.emit(essence)
	farm_state_changed.emit()
	return {"ok": true, "amount": FARM_REWARD}

func consume_offline_reward() -> int:
	var amount := pending_offline_essence
	pending_offline_essence = 0
	return amount

func can_afford(crate_id: String) -> bool:
	if not CardDatabase.CRATES.has(crate_id):
		return false
	return essence >= int(CardDatabase.CRATES[crate_id].cost)

func open_crate(crate_id: String) -> Dictionary:
	if not CardDatabase.CRATES.has(crate_id):
		return {"ok": false, "error": "Caisse inconnue."}
	var crate: Dictionary = CardDatabase.CRATES[crate_id]
	var cost := int(crate.cost)
	if essence < cost:
		return {"ok": false, "error": "Il manque %s essences." % CardDatabase.format_number(cost - essence)}

	essence -= cost
	var rarity_counts := {"common": 0, "rare": 0, "epic": 0, "legendary": 0, "unique": 0, "ultimate": 0}
	var newly_discovered: Array[String] = []
	var pulls: Array[String] = []
	var amount := int(crate.cards)
	for _index in range(amount):
		var rarity := CardDatabase.roll_rarity(_rng)
		var card := CardDatabase.get_random_card_for_rarity(rarity, _rng)
		if card.is_empty():
			continue
		var card_id: String = card.id
		var old_count := int(inventory.get(card_id, 0))
		inventory[card_id] = old_count + 1
		pulls.append(card_id)
		if _mark_discovered(card_id, false) and not newly_discovered.has(card_id):
			newly_discovered.append(card_id)
		rarity_counts[rarity] = int(rarity_counts[rarity]) + 1

	if not newly_discovered.is_empty():
		collections_changed.emit()
	lifetime_cards += pulls.size()
	lifetime_crates += 1
	selected_crate = crate_id
	_add_mission_progress("crates", 1)
	_add_mission_progress("cards", pulls.size())
	save_state()
	essence_changed.emit(essence)
	inventory_changed.emit()

	var best_rarity := "common"
	for rarity in CardDatabase.RARITY_ORDER:
		if int(rarity_counts[rarity]) > 0:
			best_rarity = rarity
	return {"ok": true, "crate_id": crate_id, "amount": pulls.size(), "pulls": pulls, "rarity_counts": rarity_counts, "newly_discovered": newly_discovered, "best_rarity": best_rarity}

# -----------------------------------------------------------------------------
# Missions quotidiennes
# -----------------------------------------------------------------------------

func _ensure_daily_missions() -> void:
	var today := Time.get_date_string_from_system()
	if daily_date == today and not daily_missions.is_empty():
		return
	daily_date = today
	daily_missions.clear()
	var start := absi(today.hash()) % MISSION_POOL.size()
	for offset in [0, 2, 4]:
		var template: Dictionary = MISSION_POOL[(start + offset) % MISSION_POOL.size()]
		var mission := template.duplicate(true)
		mission["progress"] = 0
		mission["claimed"] = false
		daily_missions.append(mission)
	missions_changed.emit()

func _add_mission_progress(mission_type: String, amount: int) -> void:
	_ensure_daily_missions()
	var changed := false
	for mission in daily_missions:
		if str(mission.type) != mission_type or bool(mission.claimed):
			continue
		var before := int(mission.progress)
		mission.progress = mini(int(mission.target), before + amount)
		changed = changed or int(mission.progress) != before
	if changed:
		missions_changed.emit()

func claim_mission(mission_id: String) -> Dictionary:
	_ensure_daily_missions()
	for mission in daily_missions:
		if str(mission.id) != mission_id:
			continue
		if bool(mission.claimed):
			return {"ok": false, "error": "Récompense déjà récupérée."}
		if int(mission.progress) < int(mission.target):
			return {"ok": false, "error": "Mission encore incomplète."}
		mission.claimed = true
		var reward := int(mission.reward)
		if str(mission.reward_type) == "coins":
			market_coins += reward
			coins_changed.emit(market_coins)
		else:
			essence += reward
			essence_changed.emit(essence)
		save_state()
		missions_changed.emit()
		return {"ok": true, "reward": reward, "reward_type": mission.reward_type}
	return {"ok": false, "error": "Mission inconnue."}

func get_completed_mission_count() -> int:
	_ensure_daily_missions()
	var total := 0
	for mission in daily_missions:
		if int(mission.progress) >= int(mission.target):
			total += 1
	return total

func get_claimed_mission_count() -> int:
	_ensure_daily_missions()
	var total := 0
	for mission in daily_missions:
		if bool(mission.claimed):
			total += 1
	return total

# -----------------------------------------------------------------------------
# Expéditions persistantes
# -----------------------------------------------------------------------------

func start_expedition(expedition_id: String) -> Dictionary:
	if not active_expedition.is_empty():
		return {"ok": false, "error": "Une expédition est déjà en cours."}
	if not EXPEDITIONS.has(expedition_id):
		return {"ok": false, "error": "Expédition inconnue."}
	var definition: Dictionary = EXPEDITIONS[expedition_id]
	var team := _get_best_owned_card_ids(int(definition.cards_required))
	if team.size() < int(definition.cards_required):
		return {"ok": false, "error": "Il faut posséder %d créature%s différente%s." % [int(definition.cards_required), "s" if int(definition.cards_required) > 1 else "", "s" if int(definition.cards_required) > 1 else ""]}
	var now := int(Time.get_unix_time_from_system())
	var bonus_percent := get_expedition_bonus_percent()
	active_expedition = {
		"id": expedition_id,
		"started_at": now,
		"ends_at": now + int(definition.duration_seconds),
		"base_reward": int(definition.reward),
		"bonus_percent": bonus_percent,
		"reward": get_expedition_reward(expedition_id),
		"team": team
	}
	save_state()
	expedition_changed.emit()
	return {"ok": true, "expedition": active_expedition}

func _get_best_owned_card_ids(amount: int) -> Array[String]:
	var result: Array[String] = []
	for rarity_index in range(CardDatabase.RARITY_ORDER.size() - 1, -1, -1):
		var rarity: String = CardDatabase.RARITY_ORDER[rarity_index]
		for card in CardDatabase.get_cards_for_rarity(rarity):
			if get_card_count(card.id) > 0:
				result.append(str(card.id))
				if result.size() >= amount:
					return result
	return result

func get_expedition_remaining() -> int:
	if active_expedition.is_empty():
		return 0
	return maxi(0, int(active_expedition.ends_at) - int(Time.get_unix_time_from_system()))

func is_expedition_complete() -> bool:
	return not active_expedition.is_empty() and get_expedition_remaining() <= 0

func claim_expedition() -> Dictionary:
	if active_expedition.is_empty():
		return {"ok": false, "error": "Aucune expédition en cours."}
	if not is_expedition_complete():
		return {"ok": false, "error": "L’expédition n’est pas encore terminée."}
	var reward := int(active_expedition.reward)
	var completed := active_expedition.duplicate(true)
	active_expedition.clear()
	essence += reward
	_add_mission_progress("expedition", 1)
	save_state()
	essence_changed.emit(essence)
	expedition_changed.emit()
	return {"ok": true, "reward": reward, "expedition": completed}

# -----------------------------------------------------------------------------
# Fusion d’exemplaires identiques
# -----------------------------------------------------------------------------

func fuse(card_id: String) -> Dictionary:
	var source := CardDatabase.get_card(card_id)
	if source.is_empty():
		return {"ok": false, "error": "Carte inconnue."}
	var rarity: String = source.rarity
	var next_rarity := CardDatabase.get_next_rarity(rarity)
	var cost := CardDatabase.get_fusion_cost(rarity)
	if next_rarity.is_empty() or cost <= 0:
		return {"ok": false, "error": "Une carte unique ne peut pas être fusionnée."}
	var source_count := get_card_count(card_id)
	if source_count < cost:
		return {"ok": false, "error": "Il faut %s exemplaires identiques de %s." % [CardDatabase.format_number(cost), source.name]}
	inventory[card_id] = source_count - cost
	var target := CardDatabase.get_random_card_for_rarity(next_rarity, _rng)
	inventory[target.id] = int(inventory.get(target.id, 0)) + 1
	_mark_discovered(str(target.id))
	lifetime_fusions += 1
	_add_mission_progress("fusion", 1)
	save_state()
	inventory_changed.emit()
	return {"ok": true, "spent": cost, "source": source, "card": target, "amount": 1}

func fuse_all() -> Dictionary:
	var produced := {"rare": 0, "epic": 0, "legendary": 0, "unique": 0}
	var total_fusions := 0
	var last_card: Dictionary = {}
	for index in range(CardDatabase.RARITY_ORDER.size() - 1):
		var rarity: String = CardDatabase.RARITY_ORDER[index]
		var next_rarity: String = CardDatabase.RARITY_ORDER[index + 1]
		var cost := CardDatabase.get_fusion_cost(rarity)
		if cost <= 0:
			continue
		for source in CardDatabase.get_cards_for_rarity(rarity):
			var batches := int(get_card_count(source.id) / cost)
			if batches <= 0:
				continue
			inventory[source.id] = get_card_count(source.id) - batches * cost
			for _batch in range(batches):
				var target := CardDatabase.get_random_card_for_rarity(next_rarity, _rng)
				inventory[target.id] = int(inventory.get(target.id, 0)) + 1
				_mark_discovered(str(target.id))
				last_card = target
			produced[next_rarity] = int(produced[next_rarity]) + batches
			total_fusions += batches
	if total_fusions <= 0:
		return {"ok": false, "error": "Aucune carte ne possède assez d’exemplaires identiques."}
	lifetime_fusions += total_fusions
	_add_mission_progress("fusion", total_fusions)
	save_state()
	inventory_changed.emit()
	return {"ok": true, "produced": produced, "total_fusions": total_fusions, "last_card": last_card}

func get_card_count(card_id: String) -> int:
	return int(inventory.get(card_id, 0))

func get_rarity_count(rarity: String) -> int:
	var total := 0
	for card in CardDatabase.get_cards_for_rarity(rarity):
		total += get_card_count(card.id)
	return total

func get_total_cards() -> int:
	var total := 0
	for card_id in CardDatabase.CARD_ORDER:
		total += get_card_count(card_id)
	return total

func get_discovered_count() -> int:
	return discovered_cards.size()

# -----------------------------------------------------------------------------
# Recyclage, habitats et albums
# -----------------------------------------------------------------------------

func get_recycle_value(card_id: String) -> int:
	var card := CardDatabase.get_card(card_id)
	if card.is_empty():
		return 0
	return int(RECYCLE_VALUES.get(str(card.rarity), 0))

func get_recyclable_count(card_id: String) -> int:
	# Un exemplaire est toujours protégé et certaines cartes sont non recyclables.
	if get_recycle_value(card_id) <= 0:
		return 0
	return maxi(0, get_card_count(card_id) - 1)

func recycle_duplicates(card_id: String, amount: int) -> Dictionary:
	var card := CardDatabase.get_card(card_id)
	if card.is_empty():
		return {"ok": false, "error": "Carte inconnue."}
	if amount <= 0 or amount > get_recyclable_count(card_id):
		return {"ok": false, "error": "Quantité de doublons invalide."}
	var unit_value := get_recycle_value(card_id)
	var reward := amount * unit_value
	inventory[card_id] = get_card_count(card_id) - amount
	dust += reward
	save_state()
	inventory_changed.emit()
	dust_changed.emit(dust)
	return {"ok": true, "card": card, "amount": amount, "reward": reward}

func craft_missing_common() -> Dictionary:
	if dust < CRAFT_MISSING_COMMON_COST:
		return {"ok": false, "error": "Il manque %s poussières." % CardDatabase.format_number(CRAFT_MISSING_COMMON_COST - dust)}
	var missing: Array[Dictionary] = []
	for card in CardDatabase.get_cards_for_rarity("common"):
		if not is_card_discovered(str(card.id)):
			missing.append(card)
	var pool := missing if not missing.is_empty() else CardDatabase.get_cards_for_rarity("common")
	if pool.is_empty():
		return {"ok": false, "error": "Aucune commune disponible."}
	var card: Dictionary = pool[_rng.randi_range(0, pool.size() - 1)]
	dust -= CRAFT_MISSING_COMMON_COST
	inventory[card.id] = get_card_count(str(card.id)) + 1
	var was_new := _mark_discovered(str(card.id))
	save_state()
	inventory_changed.emit()
	dust_changed.emit(dust)
	return {"ok": true, "card": card, "new": was_new}

func get_habitat_progress(habitat_id: String) -> Dictionary:
	var habitat := CardDatabase.get_habitat(habitat_id)
	if habitat.is_empty():
		return {"discovered": 0, "total": 0, "complete": false}
	var found := 0
	for card_id in habitat.card_ids:
		if is_card_discovered(str(card_id)):
			found += 1
	var total: int = habitat.card_ids.size()
	return {"discovered": found, "total": total, "complete": found >= total}

func claim_habitat(habitat_id: String) -> Dictionary:
	var habitat := CardDatabase.get_habitat(habitat_id)
	if habitat.is_empty():
		return {"ok": false, "error": "Habitat inconnu."}
	if claimed_habitats.has(habitat_id):
		return {"ok": false, "error": "Habitat déjà restauré."}
	if not bool(get_habitat_progress(habitat_id).complete):
		return {"ok": false, "error": "Toutes les créatures de cet habitat ne sont pas encore découvertes."}
	claimed_habitats.append(habitat_id)
	var reward := int(habitat.reward_dust)
	dust += reward
	save_state()
	dust_changed.emit(dust)
	collections_changed.emit()
	return {"ok": true, "reward": reward, "bonus": int(habitat.expedition_bonus_percent)}

func get_expedition_bonus_percent() -> int:
	var total := 0
	for habitat_id in claimed_habitats:
		var habitat := CardDatabase.get_habitat(habitat_id)
		if not habitat.is_empty():
			total += int(habitat.expedition_bonus_percent)
	return total

func get_expedition_reward(expedition_id: String) -> int:
	if not EXPEDITIONS.has(expedition_id):
		return 0
	var base_reward := int(EXPEDITIONS[expedition_id].reward)
	return int(round(base_reward * (1.0 + float(get_expedition_bonus_percent()) / 100.0)))

func get_album_progress(album_id: String) -> Dictionary:
	var album := CardDatabase.get_album(album_id)
	if album.is_empty():
		return {"discovered": 0, "total": 0, "complete": false}
	var found := 0
	for card_id in album.card_ids:
		if is_card_discovered(str(card_id)):
			found += 1
	var total: int = album.card_ids.size()
	return {"discovered": found, "total": total, "complete": found >= total}

func claim_album(album_id: String) -> Dictionary:
	var album := CardDatabase.get_album(album_id)
	if album.is_empty():
		return {"ok": false, "error": "Album inconnu."}
	if claimed_albums.has(album_id):
		return {"ok": false, "error": "Album déjà récompensé."}
	if not bool(get_album_progress(album_id).complete):
		return {"ok": false, "error": "Cette page d’album est encore incomplète."}
	claimed_albums.append(album_id)
	var essence_reward := int(album.reward_essence)
	var coins_reward := int(album.reward_coins)
	var dust_reward := int(album.reward_dust)
	essence += essence_reward
	market_coins += coins_reward
	dust += dust_reward
	save_state()
	essence_changed.emit(essence)
	coins_changed.emit(market_coins)
	dust_changed.emit(dust)
	collections_changed.emit()
	return {"ok": true, "essence": essence_reward, "coins": coins_reward, "dust": dust_reward}

# -----------------------------------------------------------------------------
# Objectif permanent : posséder la carte Ultime
# -----------------------------------------------------------------------------

func get_ultimate_goal_progress() -> Dictionary:
	var unique_cards := CardDatabase.get_cards_for_rarity("unique")
	var found := 0
	for card in unique_cards:
		if is_card_discovered(str(card.id)):
			found += 1
	return {
		"discovered": found,
		"total": unique_cards.size(),
		"ready": found >= unique_cards.size(),
		"owned": get_card_count(ULTIMATE_CARD_ID) > 0
	}

func claim_ultimate_goal() -> Dictionary:
	var ultimate := CardDatabase.get_card(ULTIMATE_CARD_ID)
	if ultimate.is_empty():
		return {"ok": false, "error": "La carte Ultime est introuvable."}
	if get_card_count(ULTIMATE_CARD_ID) > 0 or is_card_discovered(ULTIMATE_CARD_ID):
		return {"ok": false, "error": "AETERNUM est déjà en votre possession."}
	var progress := get_ultimate_goal_progress()
	if not bool(progress.ready):
		return {"ok": false, "error": "Il faut découvrir toutes les cartes Uniques : %d / %d." % [int(progress.discovered), int(progress.total)]}
	inventory[ULTIMATE_CARD_ID] = 1
	_mark_discovered(ULTIMATE_CARD_ID)
	save_state()
	inventory_changed.emit()
	return {"ok": true, "card": ultimate}

# -----------------------------------------------------------------------------
# Marché local de démonstration. Le serveur sera autoritaire en production.
# -----------------------------------------------------------------------------

func _initialize_market_if_needed() -> void:
	if market_initialized:
		return
	market_initialized = true
	var samples := [
		["pollenko", "Luna#042", 2, 85], ["goutillon", "Aster#118", 1, 120],
		["bouliflore", "Milo#771", 3, 55], ["roselune", "Nox#313", 1, 140],
		["cristaloup", "Sora#205", 1, 2400], ["floconin", "Alba#009", 2, 95],
		["chataignouf", "Kiro#552", 4, 48], ["luminargot", "Eden#480", 1, 165]
	]
	for sample in samples:
		if CardDatabase.CARDS.has(sample[0]):
			market_listings.append(_make_listing(str(sample[1]), str(sample[0]), int(sample[2]), int(sample[3]), false))
	save_state()

func _make_listing(seller: String, card_id: String, quantity: int, unit_price: int, is_player: bool) -> Dictionary:
	return {"id": "%s-%d-%d" % [card_id, Time.get_unix_time_from_system(), _rng.randi()], "seller": seller, "card_id": card_id, "quantity": quantity, "unit_price": unit_price, "currency": "coins", "is_player": is_player, "created_at": int(Time.get_unix_time_from_system())}

func create_market_listing(card_id: String, quantity: int, unit_price: int) -> Dictionary:
	var card := CardDatabase.get_card(card_id)
	if card.is_empty():
		return {"ok": false, "error": "Carte inconnue."}
	if not bool(card.get("tradable", true)) or str(card.rarity) == "ultimate":
		return {"ok": false, "error": "La carte Ultime est liée au compte et ne peut pas être vendue."}
	if quantity <= 0 or unit_price <= 0:
		return {"ok": false, "error": "La quantité et le prix doivent être positifs."}
	if get_card_count(card_id) < quantity:
		return {"ok": false, "error": "Vous ne possédez pas assez d’exemplaires."}
	inventory[card_id] = get_card_count(card_id) - quantity
	var listing := _make_listing("Vous", card_id, quantity, unit_price, true)
	market_listings.push_front(listing)
	_add_mission_progress("listing", 1)
	save_state()
	inventory_changed.emit()
	market_changed.emit()
	return {"ok": true, "listing": listing}

func buy_market_listing(listing_id: String) -> Dictionary:
	var index := _find_listing_index(listing_id)
	if index < 0:
		return {"ok": false, "error": "Cette offre n’est plus disponible."}
	var listing: Dictionary = market_listings[index]
	if bool(listing.get("is_player", false)):
		return {"ok": false, "error": "Vous ne pouvez pas acheter votre propre offre."}
	var total := int(listing.quantity) * int(listing.unit_price)
	if market_coins < total:
		return {"ok": false, "error": "Il manque %s jetons." % CardDatabase.format_number(total - market_coins)}
	market_coins -= total
	inventory[listing.card_id] = get_card_count(listing.card_id) + int(listing.quantity)
	_mark_discovered(str(listing.card_id))
	market_listings.remove_at(index)
	market_purchases += 1
	save_state()
	coins_changed.emit(market_coins)
	inventory_changed.emit()
	market_changed.emit()
	return {"ok": true, "listing": listing, "total": total}

func cancel_market_listing(listing_id: String) -> Dictionary:
	var index := _find_listing_index(listing_id)
	if index < 0:
		return {"ok": false, "error": "Offre introuvable."}
	var listing: Dictionary = market_listings[index]
	if not bool(listing.get("is_player", false)):
		return {"ok": false, "error": "Cette offre ne vous appartient pas."}
	inventory[listing.card_id] = get_card_count(listing.card_id) + int(listing.quantity)
	market_listings.remove_at(index)
	save_state()
	inventory_changed.emit()
	market_changed.emit()
	return {"ok": true}

func _find_listing_index(listing_id: String) -> int:
	for index in range(market_listings.size()):
		if str(market_listings[index].get("id", "")) == listing_id:
			return index
	return -1

# -----------------------------------------------------------------------------
# Sauvegarde et migration
# -----------------------------------------------------------------------------

func reset_progress() -> void:
	essence = STARTING_ESSENCE
	market_coins = STARTING_MARKET_COINS
	dust = 0
	inventory.clear()
	discovered_cards.clear()
	claimed_habitats.clear()
	claimed_albums.clear()
	_initialize_inventory()
	lifetime_cards = 0
	lifetime_crates = 0
	lifetime_fusions = 0
	farm_actions = 0
	market_purchases = 0
	selected_crate = "small"
	market_listings.clear()
	market_initialized = false
	next_farm_at_unix = 0
	last_seen_unix = int(Time.get_unix_time_from_system())
	pending_offline_essence = 0
	daily_date = ""
	daily_missions.clear()
	active_expedition.clear()
	_ensure_daily_missions()
	_initialize_market_if_needed()
	save_state()
	essence_changed.emit(essence)
	coins_changed.emit(market_coins)
	inventory_changed.emit()
	market_changed.emit()
	farm_state_changed.emit()
	expedition_changed.emit()
	dust_changed.emit(dust)
	collections_changed.emit()

func save_state() -> void:
	last_seen_unix = int(Time.get_unix_time_from_system())
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	var data := {
		"version": SAVE_VERSION,
		"essence": essence,
		"market_coins": market_coins,
		"dust": dust,
		"inventory": inventory,
		"discovered_cards": discovered_cards,
		"claimed_habitats": claimed_habitats,
		"claimed_albums": claimed_albums,
		"lifetime_cards": lifetime_cards,
		"lifetime_crates": lifetime_crates,
		"lifetime_fusions": lifetime_fusions,
		"farm_actions": farm_actions,
		"market_purchases": market_purchases,
		"selected_crate": selected_crate,
		"market_listings": market_listings,
		"market_initialized": market_initialized,
		"next_farm_at_unix": next_farm_at_unix,
		"last_seen_unix": last_seen_unix,
		"daily_date": daily_date,
		"daily_missions": daily_missions,
		"active_expedition": active_expedition
	}
	file.store_string(JSON.stringify(data))

func load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		last_seen_unix = int(Time.get_unix_time_from_system())
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var loaded_version := int(parsed.get("version", 1))
	essence = maxi(0, int(parsed.get("essence", STARTING_ESSENCE)))
	# Migration prototype V2 -> V3 : l’inventaire est conservé mais la nouvelle
	# économie repart avec le capital de départ prévu pour être testée correctement.
	if loaded_version < 3:
		essence = STARTING_ESSENCE
	market_coins = maxi(0, int(parsed.get("market_coins", STARTING_MARKET_COINS)))
	dust = maxi(0, int(parsed.get("dust", 0)))
	var loaded_inventory = parsed.get("inventory", {})
	if typeof(loaded_inventory) == TYPE_DICTIONARY:
		inventory = loaded_inventory
	_initialize_inventory()
	discovered_cards.clear()
	var loaded_discoveries = parsed.get("discovered_cards", [])
	if typeof(loaded_discoveries) == TYPE_ARRAY:
		for card_id in loaded_discoveries:
			if CardDatabase.CARDS.has(str(card_id)):
				discovered_cards.append(str(card_id))
	claimed_habitats.clear()
	for habitat_id in parsed.get("claimed_habitats", []):
		if CardDatabase.HABITATS.has(str(habitat_id)):
			claimed_habitats.append(str(habitat_id))
	claimed_albums.clear()
	for album_id in parsed.get("claimed_albums", []):
		if CardDatabase.ALBUMS.has(str(album_id)):
			claimed_albums.append(str(album_id))
	lifetime_cards = maxi(0, int(parsed.get("lifetime_cards", 0)))
	lifetime_crates = maxi(0, int(parsed.get("lifetime_crates", 0)))
	lifetime_fusions = maxi(0, int(parsed.get("lifetime_fusions", 0)))
	farm_actions = maxi(0, int(parsed.get("farm_actions", 0)))
	market_purchases = maxi(0, int(parsed.get("market_purchases", 0)))
	selected_crate = str(parsed.get("selected_crate", "small"))
	if not CardDatabase.CRATES.has(selected_crate):
		selected_crate = "small"
	market_initialized = bool(parsed.get("market_initialized", false))
	market_listings.clear()
	var loaded_listings = parsed.get("market_listings", [])
	if typeof(loaded_listings) == TYPE_ARRAY:
		for listing in loaded_listings:
			if typeof(listing) == TYPE_DICTIONARY and CardDatabase.CARDS.has(str(listing.get("card_id", ""))):
				market_listings.append(listing)
	next_farm_at_unix = int(parsed.get("next_farm_at_unix", 0))
	daily_date = str(parsed.get("daily_date", ""))
	daily_missions.clear()
	var loaded_missions = parsed.get("daily_missions", [])
	if typeof(loaded_missions) == TYPE_ARRAY:
		for mission in loaded_missions:
			if typeof(mission) == TYPE_DICTIONARY:
				daily_missions.append(mission)
	var loaded_expedition = parsed.get("active_expedition", {})
	if typeof(loaded_expedition) == TYPE_DICTIONARY:
		active_expedition = loaded_expedition
	var saved_last_seen := int(parsed.get("last_seen_unix", int(Time.get_unix_time_from_system())))
	_apply_offline_income(saved_last_seen)

func _apply_offline_income(saved_last_seen: int) -> void:
	var now := int(Time.get_unix_time_from_system())
	var elapsed := clampi(now - saved_last_seen, 0, OFFLINE_CAP_SECONDS)
	var ticks := int(elapsed / PASSIVE_INTERVAL_SECONDS)
	pending_offline_essence = ticks * PASSIVE_REWARD
	if pending_offline_essence > 0:
		essence += pending_offline_essence
	last_seen_unix = now

func _on_passive_tick() -> void:
	_ensure_daily_missions()
	essence += PASSIVE_REWARD
	essence_changed.emit(essence)
	farm_state_changed.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_state()

extends Node
## Économie V5 : pity, séquestre d’expédition, maîtrise, fusion rééquilibrée.

signal essence_changed(value: int)
signal coins_changed(value: int)
signal inventory_changed
signal market_changed
signal farm_state_changed
signal missions_changed
signal expedition_changed
signal dust_changed(value: int)
signal collections_changed
signal mastery_changed

const SAVE_PATH := "user://forge_familiers_save.json"
const EXPORT_SAVE_PATH := "user://forge_familiers_release.json"
const SAVE_VERSION := 8
const STARTING_ESSENCE := 200
const STARTING_MARKET_COINS := 2500
const FARM_REWARD := 2
const FARM_COOLDOWN_SECONDS := 10
const PASSIVE_REWARD := 1
const PASSIVE_INTERVAL_SECONDS := 10
const FARM_YIELD_VALUES := [2, 3, 4, 5, 6, 8, 10]
const FARM_SPEED_VALUES := [10, 8, 7, 6, 5, 4]
const UPGRADE_MAX := {"yield": 6, "speed": 5, "passive": 5, "luck": 8}
const UPGRADE_COSTS := {
	"yield": [80, 160, 320, 640, 1200, 2200],
	"speed": [100, 200, 400, 800, 1500],
	"passive": [120, 250, 500, 1000, 1800],
	"luck": [180, 360, 650, 1100, 1700, 2500, 3500, 5000]
}
const OFFLINE_CAP_SECONDS := 8 * 60 * 60
const ULTIMATE_CARD_ID := "aeternum"
const CRAFT_MISSING_COMMON_COST := 100
const RECYCLE_VALUES := {
	"common": 1,
	"rare": 25,
	"epic": 250,
	"legendary": 2500,
	"unique": 10000
}

const PITY_CAPS := {
	"rare": 20,
	"epic": 300,
	"legendary": 1000,
	"unique": 8000
}
const PITY_ORDER: Array[String] = ["unique", "legendary", "epic", "rare"]

const MASTERY_THRESHOLDS := [1, 3, 10, 25]
const MASTERY_TITLES := ["Nouveau-né", "Compagnon", "Éclaireur", "Gardien", "Légende"]
const MASTERY_BONUS_PER_LEVEL := 2

const MISSION_POOL := [
	{"id": "harvest", "type": "harvest", "label": "Récolteur patient", "description": "Effectuer 3 récoltes manuelles", "target": 3, "reward_type": "essence", "reward": 75},
	{"id": "crates", "type": "crates", "label": "Ouvreur de caisses", "description": "Ouvrir 2 caisses Origine", "target": 2, "reward_type": "essence", "reward": 120},
	{"id": "cards", "type": "cards", "label": "Grande découverte", "description": "Révéler 30 cartes", "target": 30, "reward_type": "essence", "reward": 150},
	{"id": "fusion", "type": "fusion", "label": "Alchimiste", "description": "Réaliser 1 fusion", "target": 1, "reward_type": "essence", "reward": 200},
	{"id": "listing", "type": "listing", "label": "Petit marchand", "description": "Publier 1 offre sur le marché", "target": 1, "reward_type": "coins", "reward": 100},
	{"id": "expedition", "type": "expedition", "label": "Explorateur", "description": "Terminer 1 expédition", "target": 1, "reward_type": "essence", "reward": 180}
]

const QUEST_DEFS := [
	{"id": "guide_harvest", "chapter": "guide", "order": 0, "type": "harvest", "target": 1, "reward_type": "essence", "reward": 40, "label_fr": "Première récolte", "label_en": "First harvest", "description_fr": "Récolte de l’essence sur l’herbe.", "description_en": "Harvest essence from the grass.", "hint_fr": "Touche l’herbe ou le bouton Récolter.", "hint_en": "Tap the grass or Harvest."},
	{"id": "guide_crate", "chapter": "guide", "order": 1, "type": "crates", "target": 1, "reward_type": "essence", "reward": 80, "label_fr": "Première caisse", "label_en": "First crate", "description_fr": "Ouvre une caisse Origine.", "description_en": "Open an Origin crate.", "hint_fr": "Choisis une taille puis appuie sur Ouvrir.", "hint_en": "Pick a size, then tap Open."},
	{"id": "guide_collection", "chapter": "guide", "order": 2, "type": "visit_collection", "target": 1, "reward_type": "essence", "reward": 50, "label_fr": "Regarder la collection", "label_en": "Visit the collection", "description_fr": "Ouvre l’onglet Cartes.", "description_en": "Open the Cards tab.", "hint_fr": "En bas, touche Cartes.", "hint_en": "At the bottom, tap Cards."},
	{"id": "guide_upgrade", "chapter": "guide", "order": 3, "type": "upgrade", "target": 1, "reward_type": "essence", "reward": 80, "label_fr": "Améliorer la ferme", "label_en": "Upgrade the farm", "description_fr": "Achète une amélioration de ferme.", "description_en": "Buy a farm upgrade.", "hint_fr": "Touche Améliorer, puis achète un bonus.", "hint_en": "Tap Upgrade, then buy a bonus."},
	{"id": "guide_albums", "chapter": "guide", "order": 4, "type": "visit_albums", "target": 1, "reward_type": "essence", "reward": 50, "label_fr": "Habitats et albums", "label_en": "Habitats and albums", "description_fr": "Consulte l’onglet Albums.", "description_en": "Open the Albums tab.", "hint_fr": "En bas, touche Albums.", "hint_en": "At the bottom, tap Albums."},
	{"id": "story_harvest10", "chapter": "story", "order": 0, "type": "harvest", "target": 10, "reward_type": "essence", "reward": 90, "label_fr": "Récolteur assidu", "label_en": "Steady harvester", "description_fr": "Effectue 10 récoltes manuelles.", "description_en": "Perform 10 manual harvests.", "hint_fr": "Continue de toucher l’herbe.", "hint_en": "Keep tapping the grass."},
	{"id": "story_crates3", "chapter": "story", "order": 1, "type": "crates", "target": 3, "reward_type": "essence", "reward": 140, "label_fr": "Ouvreur confirmé", "label_en": "Crate opener", "description_fr": "Ouvre 3 caisses Origine.", "description_en": "Open 3 Origin crates.", "hint_fr": "L’essence achète les caisses.", "hint_en": "Essence buys crates."},
	{"id": "story_discover12", "chapter": "story", "order": 2, "type": "discover", "target": 12, "reward_type": "essence", "reward": 120, "label_fr": "Naturaliste", "label_en": "Naturalist", "description_fr": "Découvre 12 familiers différents.", "description_en": "Discover 12 different familiars.", "hint_fr": "Les nouvelles cartes comptent.", "hint_en": "New cards count."},
	{"id": "story_fusion_visit", "chapter": "story", "order": 3, "type": "visit_fusion", "target": 1, "reward_type": "essence", "reward": 50, "label_fr": "L’atelier", "label_en": "The workshop", "description_fr": "Rends-toi à l’atelier de fusion.", "description_en": "Visit the fusion workshop.", "hint_fr": "En bas, touche Fusion.", "hint_en": "At the bottom, tap Fusion."},
	{"id": "story_fusion", "chapter": "story", "order": 4, "type": "fusion", "target": 1, "reward_type": "essence", "reward": 200, "label_fr": "Premier amalgam", "label_en": "First fusion", "description_fr": "Réalise 1 fusion.", "description_en": "Complete 1 fusion.", "hint_fr": "Dix communes identiques deviennent une rare.", "hint_en": "Ten identical commons become a rare."},
	{"id": "story_expedition", "chapter": "story", "order": 5, "type": "expedition_start", "target": 1, "reward_type": "essence", "reward": 100, "label_fr": "Première équipe", "label_en": "First team", "description_fr": "Lance une expédition.", "description_en": "Start an expedition.", "hint_fr": "Compose une équipe depuis Expéditions.", "hint_en": "Build a team from Expeditions."},
	{"id": "story_luck", "chapter": "story", "order": 6, "type": "luck_upgrade", "target": 1, "reward_type": "essence", "reward": 160, "label_fr": "Porte-bonheur", "label_en": "Lucky charm", "description_fr": "Achète 1 niveau de fortune.", "description_en": "Buy 1 luck upgrade.", "hint_fr": "Améliorer → Fortune des caisses.", "hint_en": "Upgrade → Crate fortune."},
	{"id": "story_yield3", "chapter": "story", "order": 7, "type": "yield_level", "target": 3, "reward_type": "essence", "reward": 220, "label_fr": "Ferme prospère", "label_en": "Thriving farm", "description_fr": "Atteins le niveau 3 de récolte.", "description_en": "Reach harvest upgrade level 3.", "hint_fr": "Améliore le rendement de la ferme.", "hint_en": "Upgrade farm yield."},
	{"id": "story_rare", "chapter": "story", "order": 8, "type": "discover_rare", "target": 1, "reward_type": "essence", "reward": 180, "label_fr": "Première rare", "label_en": "First rare", "description_fr": "Découvre une carte rare.", "description_en": "Discover a rare card.", "hint_fr": "Ouvre des caisses ou fusionne.", "hint_en": "Open crates or fuse."},
	{"id": "story_crates10", "chapter": "story", "order": 9, "type": "crates", "target": 10, "reward_type": "essence", "reward": 280, "label_fr": "Collectionneur de caisses", "label_en": "Crate collector", "description_fr": "Ouvre 10 caisses.", "description_en": "Open 10 crates.", "hint_fr": "La fortune aide un peu les taux.", "hint_en": "Luck slightly helps the rates."}
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
var reserved: Dictionary = {}
var discovered_cards: Array[String] = []
var claimed_habitats: Array[String] = []
var claimed_albums: Array[String] = []
var card_mastery: Dictionary = {}
var pity_counts: Dictionary = {"rare": 0, "epic": 0, "legendary": 0, "unique": 0}
var lifetime_cards: int = 0
var lifetime_crates: int = 0
var lifetime_fusions: int = 0
var farm_actions: int = 0
var market_purchases: int = 0
var selected_crate: String = "small"
var market_listings: Array[Dictionary] = []
var market_initialized: bool = false
var tutorial_done: bool = false
var language: String = "fr"
var sound_volume: float = 1.0
var sound_muted: bool = false
var farm_yield_level: int = 0
var farm_speed_level: int = 0
var farm_passive_level: int = 0
var luck_level: int = 0
var quest_progress: Dictionary = {}
var claimed_quests: Array[String] = []
var market_online: bool = false
var server_url: String = "http://127.0.0.1:8787"
var device_id: String = ""
var server_token: String = ""
var server_user_id: String = ""
var public_name: String = ""
var market_connected: bool = false
var online_listings: Array = []
var last_server_coins: int = -1

var next_farm_at_unix: int = 0
var last_seen_unix: int = 0
var pending_offline_essence: int = 0
var daily_date: String = ""
var daily_missions: Array[Dictionary] = []
var active_expedition: Dictionary = {}

var _rng := RandomNumberGenerator.new()
var _save_timer: Timer
var _passive_timer: Timer
var _http: HTTPRequest
var _http_busy: bool = false

func get_save_path() -> String:
	if OS.has_feature("editor"):
		return SAVE_PATH
	return EXPORT_SAVE_PATH

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

	_http = HTTPRequest.new()
	_http.timeout = 8.0
	_http.use_threads = true
	add_child(_http)
	if device_id.is_empty():
		device_id = "%x-%d" % [_rng.randi(), Time.get_unix_time_from_system()]
		save_state()
	if market_online:
		call_deferred("_boot_market")

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
	var quest_changed := _add_quest_progress("discover", 1)
	var card := CardDatabase.get_card(card_id)
	if str(card.get("rarity", "")) == "rare":
		quest_changed = _add_quest_progress("discover_rare", 1) or quest_changed
	if quest_changed:
		missions_changed.emit()
	if notify:
		collections_changed.emit()
	return true

func is_card_discovered(card_id: String) -> bool:
	return discovered_cards.has(card_id)

func get_wanderers(limit: int = 8) -> Array[String]:
	var result: Array[String] = []
	for rarity_index in range(CardDatabase.RARITY_ORDER.size() - 1, -1, -1):
		var rarity: String = CardDatabase.RARITY_ORDER[rarity_index]
		for card in CardDatabase.get_cards_for_rarity(rarity):
			if get_card_count(str(card.id)) > 0:
				result.append(str(card.id))
				if result.size() >= limit:
					return result
	return result

# -----------------------------------------------------------------------------
# Économie et récolte
# -----------------------------------------------------------------------------

func can_farm() -> bool:
	return int(Time.get_unix_time_from_system()) >= next_farm_at_unix

func get_farm_cooldown() -> int:
	return maxi(0, next_farm_at_unix - int(Time.get_unix_time_from_system()))

func get_farm_reward() -> int:
	return int(FARM_YIELD_VALUES[clampi(farm_yield_level, 0, FARM_YIELD_VALUES.size() - 1)])

func get_harvest_cooldown_seconds() -> int:
	return int(FARM_SPEED_VALUES[clampi(farm_speed_level, 0, FARM_SPEED_VALUES.size() - 1)])

func get_passive_reward() -> int:
	return PASSIVE_REWARD + farm_passive_level

func farm() -> Dictionary:
	if not can_farm():
		return {"ok": false, "remaining": get_farm_cooldown(), "error": "La récolte se recharge."}
	var amount := get_farm_reward()
	essence += amount
	farm_actions += 1
	next_farm_at_unix = int(Time.get_unix_time_from_system()) + get_harvest_cooldown_seconds()
	_add_mission_progress("harvest", 1)
	essence_changed.emit(essence)
	farm_state_changed.emit()
	return {"ok": true, "amount": amount}

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
	var pity_hits: Array[String] = []
	var amount := int(crate.cards)
	for _index in range(amount):
		var roll := roll_rarity_with_pity()
		var rarity: String = roll.rarity
		if bool(roll.pity):
			pity_hits.append(rarity)
		var card := CardDatabase.get_random_card_for_rarity(rarity, _rng)
		if card.is_empty():
			continue
		var card_id: String = card.id
		inventory[card_id] = int(inventory.get(card_id, 0)) + 1
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
	return {
		"ok": true,
		"crate_id": crate_id,
		"amount": pulls.size(),
		"pulls": pulls,
		"rarity_counts": rarity_counts,
		"newly_discovered": newly_discovered,
		"best_rarity": best_rarity,
		"pity_hits": pity_hits
	}

func roll_rarity_with_pity() -> Dictionary:
	for rarity in PITY_ORDER:
		if int(pity_counts.get(rarity, 0)) >= int(PITY_CAPS[rarity]):
			_register_pity_result(rarity)
			return {"rarity": rarity, "pity": true}
	var rarity := CardDatabase.roll_rarity(_rng)
	_register_pity_result(rarity)
	return {"rarity": rarity, "pity": false}

func _register_pity_result(rarity: String) -> void:
	for key in PITY_CAPS:
		if str(key) == rarity:
			pity_counts[key] = 0
		else:
			pity_counts[key] = int(pity_counts.get(key, 0)) + 1

func get_pity_remaining(rarity: String) -> int:
	if not PITY_CAPS.has(rarity):
		return 0
	return maxi(0, int(PITY_CAPS[rarity]) - int(pity_counts.get(rarity, 0)))

func get_pity_status() -> Dictionary:
	var status := {}
	for rarity in PITY_CAPS:
		status[rarity] = {
			"count": int(pity_counts.get(rarity, 0)),
			"cap": int(PITY_CAPS[rarity]),
			"remaining": get_pity_remaining(rarity)
		}
	return status

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
	var quest_changed := _add_quest_progress(mission_type, amount)
	if changed or quest_changed:
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
# Quêtes (guide + histoire) et améliorations
# -----------------------------------------------------------------------------

func quest_text(quest: Dictionary, field: String) -> String:
	var suffix := "_en" if str(language) == "en" else "_fr"
	return str(quest.get(field + suffix, quest.get(field, "")))

func is_guide_complete() -> bool:
	for quest in QUEST_DEFS:
		if str(quest.chapter) == "guide" and not claimed_quests.has(str(quest.id)):
			return false
	return true

func _mark_guide_claimed() -> void:
	for quest in QUEST_DEFS:
		var quest_id := str(quest.id)
		if str(quest.chapter) == "guide" and not claimed_quests.has(quest_id):
			claimed_quests.append(quest_id)

func _is_quest_unlocked(quest: Dictionary) -> bool:
	var chapter := str(quest.chapter)
	if chapter == "guide":
		var order := int(quest.order)
		if order <= 0:
			return true
		for other in QUEST_DEFS:
			if str(other.chapter) == "guide" and int(other.order) == order - 1:
				return claimed_quests.has(str(other.id))
		return false
	return is_guide_complete()

func get_quest_progress_value(quest: Dictionary) -> int:
	var qtype := str(quest.type)
	if qtype == "yield_level":
		return farm_yield_level
	if qtype == "luck_level":
		return luck_level
	if qtype == "speed_level":
		return farm_speed_level
	if qtype == "passive_level":
		return farm_passive_level
	return int(quest_progress.get(str(quest.id), 0))

func _add_quest_progress(progress_type: String, amount: int) -> bool:
	if amount <= 0:
		return false
	var changed := false
	for quest in QUEST_DEFS:
		var quest_id := str(quest.id)
		if claimed_quests.has(quest_id) or not _is_quest_unlocked(quest):
			continue
		if str(quest.type) != progress_type:
			continue
		if str(quest.type) in ["yield_level", "luck_level", "speed_level", "passive_level"]:
			continue
		var before := int(quest_progress.get(quest_id, 0))
		var next_value := mini(int(quest.target), before + amount)
		if next_value != before:
			quest_progress[quest_id] = next_value
			changed = true
	return changed

func claim_quest(quest_id: String) -> Dictionary:
	for quest in QUEST_DEFS:
		if str(quest.id) != quest_id:
			continue
		if claimed_quests.has(quest_id):
			return {"ok": false, "error": "Récompense déjà récupérée."}
		if not _is_quest_unlocked(quest):
			return {"ok": false, "error": "Quête encore verrouillée."}
		if get_quest_progress_value(quest) < int(quest.target):
			return {"ok": false, "error": "Quête encore incomplète."}
		claimed_quests.append(quest_id)
		var reward := int(quest.reward)
		if str(quest.reward_type) == "coins":
			market_coins += reward
			coins_changed.emit(market_coins)
		else:
			essence += reward
			essence_changed.emit(essence)
		if str(quest.chapter) == "guide" and is_guide_complete():
			tutorial_done = true
		save_state()
		missions_changed.emit()
		return {"ok": true, "reward": reward, "reward_type": quest.reward_type, "quest": quest}
	return {"ok": false, "error": "Quête inconnue."}

func note_visit(page_id: String) -> void:
	var mapping := {
		"collection": "visit_collection",
		"albums": "visit_albums",
		"fusion": "visit_fusion",
		"market": "visit_market"
	}
	if not mapping.has(page_id):
		return
	if _add_quest_progress(str(mapping[page_id]), 1):
		missions_changed.emit()

func get_quest_board_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for quest in QUEST_DEFS:
		var chapter := str(quest.chapter)
		var unlocked := _is_quest_unlocked(quest)
		if chapter == "story" and not is_guide_complete() and not unlocked:
			continue
		var progress := get_quest_progress_value(quest)
		var target := int(quest.target)
		var claimed: bool = claimed_quests.has(str(quest.id))
		rows.append({
			"id": str(quest.id),
			"kind": "quest",
			"chapter": chapter,
			"label": quest_text(quest, "label"),
			"description": quest_text(quest, "description"),
			"hint": quest_text(quest, "hint"),
			"progress": progress,
			"target": target,
			"claimed": claimed,
			"complete": claimed or progress >= target,
			"locked": not unlocked and not claimed,
			"reward": int(quest.reward),
			"reward_type": str(quest.reward_type)
		})
	_ensure_daily_missions()
	for mission in daily_missions:
		var progress := int(mission.progress)
		var target := int(mission.target)
		var claimed := bool(mission.claimed)
		rows.append({
			"id": str(mission.id),
			"kind": "daily",
			"chapter": "daily",
			"label": str(mission.label),
			"description": str(mission.description),
			"hint": "",
			"progress": progress,
			"target": target,
			"claimed": claimed,
			"complete": claimed or progress >= target,
			"locked": false,
			"reward": int(mission.reward),
			"reward_type": str(mission.reward_type)
		})
	return rows

func get_tracked_quest() -> Dictionary:
	for row in get_quest_board_rows():
		if str(row.chapter) == "daily":
			continue
		if bool(row.claimed) or bool(row.locked):
			continue
		return row
	for row in get_quest_board_rows():
		if str(row.chapter) != "daily":
			continue
		if bool(row.claimed):
			continue
		return row
	return {}

func get_ready_quest_count() -> int:
	var total := 0
	for row in get_quest_board_rows():
		if bool(row.complete) and not bool(row.claimed) and not bool(row.locked):
			total += 1
	return total

func get_upgrade_level(upgrade_id: String) -> int:
	match upgrade_id:
		"yield":
			return farm_yield_level
		"speed":
			return farm_speed_level
		"passive":
			return farm_passive_level
		"luck":
			return luck_level
		_:
			return 0

func get_upgrade_max(upgrade_id: String) -> int:
	return int(UPGRADE_MAX.get(upgrade_id, 0))

func get_upgrade_cost(upgrade_id: String) -> int:
	if not UPGRADE_COSTS.has(upgrade_id):
		return 0
	var level := get_upgrade_level(upgrade_id)
	var costs: Array = UPGRADE_COSTS[upgrade_id]
	if level < 0 or level >= costs.size():
		return 0
	return int(costs[level])

func is_upgrade_maxed(upgrade_id: String) -> bool:
	return get_upgrade_level(upgrade_id) >= get_upgrade_max(upgrade_id)

func get_upgrade_preview(upgrade_id: String) -> Dictionary:
	var level := get_upgrade_level(upgrade_id)
	match upgrade_id:
		"yield":
			var current := get_farm_reward()
			var nxt := int(FARM_YIELD_VALUES[mini(level + 1, FARM_YIELD_VALUES.size() - 1)])
			return {"current": "+%d" % current, "next": "+%d" % nxt}
		"speed":
			var current_cd := get_harvest_cooldown_seconds()
			var next_cd := int(FARM_SPEED_VALUES[mini(level + 1, FARM_SPEED_VALUES.size() - 1)])
			return {"current": "%d s" % current_cd, "next": "%d s" % next_cd}
		"passive":
			var current_p := get_passive_reward()
			var next_p := PASSIVE_REWARD + mini(level + 1, get_upgrade_max("passive"))
			return {"current": "+%d / 10s" % current_p, "next": "+%d / 10s" % next_p}
		"luck":
			var now_chances := CardDatabase.get_rarity_chances(luck_level)
			var next_chances := CardDatabase.get_rarity_chances(mini(luck_level + 1, get_upgrade_max("luck")))
			return {
				"current": CardDatabase.format_rate(float(now_chances.rare) * 100.0),
				"next": CardDatabase.format_rate(float(next_chances.rare) * 100.0)
			}
		_:
			return {"current": "-", "next": "-"}

func buy_upgrade(upgrade_id: String) -> Dictionary:
	if not UPGRADE_MAX.has(upgrade_id):
		return {"ok": false, "error": "Amélioration inconnue."}
	if is_upgrade_maxed(upgrade_id):
		return {"ok": false, "error": "Niveau maximum atteint."}
	var cost := get_upgrade_cost(upgrade_id)
	if essence < cost:
		return {"ok": false, "error": "Il manque %s essences." % CardDatabase.format_number(cost - essence)}
	essence -= cost
	match upgrade_id:
		"yield":
			farm_yield_level += 1
		"speed":
			farm_speed_level += 1
		"passive":
			farm_passive_level += 1
		"luck":
			luck_level += 1
	_add_quest_progress("upgrade", 1)
	if upgrade_id == "luck":
		_add_quest_progress("luck_upgrade", 1)
	else:
		_add_quest_progress("farm_upgrade", 1)
	save_state()
	essence_changed.emit(essence)
	farm_state_changed.emit()
	missions_changed.emit()
	return {"ok": true, "id": upgrade_id, "level": get_upgrade_level(upgrade_id), "cost": cost}

# -----------------------------------------------------------------------------
# Expéditions : équipe choisie, séquestre, maîtrise
# -----------------------------------------------------------------------------

func get_card_count(card_id: String) -> int:
	return int(inventory.get(card_id, 0))

func get_reserved_count(card_id: String) -> int:
	return int(reserved.get(card_id, 0))

func get_available_count(card_id: String) -> int:
	return maxi(0, get_card_count(card_id) - get_reserved_count(card_id))

func get_available_creature_ids() -> Array[String]:
	var result: Array[String] = []
	for rarity_index in range(CardDatabase.RARITY_ORDER.size() - 1, -1, -1):
		var rarity: String = CardDatabase.RARITY_ORDER[rarity_index]
		for card in CardDatabase.get_cards_for_rarity(rarity):
			if get_available_count(str(card.id)) > 0:
				result.append(str(card.id))
	return result

func _reserve(card_id: String, amount: int = 1) -> void:
	reserved[card_id] = get_reserved_count(card_id) + amount

func _release(card_id: String, amount: int = 1) -> void:
	reserved[card_id] = maxi(0, get_reserved_count(card_id) - amount)
	if int(reserved[card_id]) <= 0:
		reserved.erase(card_id)

func start_expedition(expedition_id: String, team: Array = []) -> Dictionary:
	if not active_expedition.is_empty():
		return {"ok": false, "error": "Une expédition est déjà en cours."}
	if not EXPEDITIONS.has(expedition_id):
		return {"ok": false, "error": "Expédition inconnue."}
	var definition: Dictionary = EXPEDITIONS[expedition_id]
	var required := int(definition.cards_required)
	var cleaned: Array[String] = []
	for value in team:
		var card_id := str(value)
		if cleaned.has(card_id):
			return {"ok": false, "error": "Chaque créature ne peut partir qu’une fois."}
		if not CardDatabase.CARDS.has(card_id):
			return {"ok": false, "error": "Carte inconnue dans l’équipe."}
		if get_available_count(card_id) <= 0:
			return {"ok": false, "error": "« %s » n’est pas disponible." % CardDatabase.get_card(card_id).name}
		cleaned.append(card_id)
	if cleaned.size() != required:
		return {"ok": false, "error": "Il faut %d créature%s différente%s." % [required, "s" if required > 1 else "", "s" if required > 1 else ""]}
	var now := int(Time.get_unix_time_from_system())
	var habitat_bonus := get_expedition_bonus_percent()
	var mastery_bonus := get_team_mastery_bonus_percent(cleaned)
	for card_id in cleaned:
		_reserve(card_id, 1)
	active_expedition = {
		"id": expedition_id,
		"started_at": now,
		"ends_at": now + int(definition.duration_seconds),
		"base_reward": int(definition.reward),
		"habitat_bonus": habitat_bonus,
		"mastery_bonus": mastery_bonus,
		"bonus_percent": habitat_bonus + mastery_bonus,
		"reward": get_expedition_reward(expedition_id, cleaned),
		"team": cleaned
	}
	_add_quest_progress("expedition_start", 1)
	save_state()
	inventory_changed.emit()
	expedition_changed.emit()
	missions_changed.emit()
	return {"ok": true, "expedition": active_expedition}

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
	for card_id in completed.get("team", []):
		_release(str(card_id), 1)
		add_mastery(str(card_id), 1)
	active_expedition.clear()
	essence += reward
	_add_mission_progress("expedition", 1)
	save_state()
	essence_changed.emit(essence)
	inventory_changed.emit()
	expedition_changed.emit()
	mastery_changed.emit()
	return {"ok": true, "reward": reward, "expedition": completed}

func get_mastery_xp(card_id: String) -> int:
	return int(card_mastery.get(card_id, 0))

func get_mastery_level(card_id: String) -> int:
	var xp := get_mastery_xp(card_id)
	var level := 0
	for threshold in MASTERY_THRESHOLDS:
		if xp >= int(threshold):
			level += 1
	return level

func get_mastery_title(card_id: String) -> String:
	return str(MASTERY_TITLES[get_mastery_level(card_id)])

func add_mastery(card_id: String, amount: int = 1) -> void:
	card_mastery[card_id] = get_mastery_xp(card_id) + amount

func get_team_mastery_bonus_percent(team: Array) -> int:
	var total := 0
	for card_id in team:
		total += get_mastery_level(str(card_id)) * MASTERY_BONUS_PER_LEVEL
	return total

func get_expedition_bonus_percent() -> int:
	var total := 0
	for habitat_id in claimed_habitats:
		var habitat := CardDatabase.get_habitat(habitat_id)
		if not habitat.is_empty():
			total += int(habitat.expedition_bonus_percent)
	return total

func get_expedition_reward(expedition_id: String, team: Array = []) -> int:
	if not EXPEDITIONS.has(expedition_id):
		return 0
	var base_reward := int(EXPEDITIONS[expedition_id].reward)
	var members: Array = team
	if members.is_empty() and not active_expedition.is_empty():
		members = active_expedition.get("team", [])
	var bonus := get_expedition_bonus_percent() + get_team_mastery_bonus_percent(members)
	return int(round(base_reward * (1.0 + float(bonus) / 100.0)))

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
	if get_available_count(card_id) < cost:
		return {"ok": false, "error": "Il faut %s exemplaires disponibles de %s." % [CardDatabase.format_number(cost), source.name]}
	inventory[card_id] = get_card_count(card_id) - cost
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
			var batches := int(get_available_count(source.id) / cost)
			if batches <= 0:
				continue
			inventory[source.id] = get_card_count(source.id) - batches * cost
			for _batch in range(batches):
				var target := CardDatabase.get_random_card_for_rarity(next_rarity, _rng)
				inventory[target.id] = int(inventory.get(target.id, 0)) + 1
				_mark_discovered(str(target.id))
				last_card = target
			produced[next_rarity] = int(produced.get(next_rarity, 0)) + batches
			total_fusions += batches
	if total_fusions <= 0:
		return {"ok": false, "error": "Aucune carte ne possède assez d’exemplaires disponibles."}
	lifetime_fusions += total_fusions
	_add_mission_progress("fusion", total_fusions)
	save_state()
	inventory_changed.emit()
	return {"ok": true, "produced": produced, "total_fusions": total_fusions, "last_card": last_card}

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
	if get_recycle_value(card_id) <= 0:
		return 0
	return mini(get_available_count(card_id), maxi(0, get_card_count(card_id) - 1))

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

func get_max_craft_count() -> int:
	return int(dust / CRAFT_MISSING_COMMON_COST)

func craft_missing_common() -> Dictionary:
	return craft_commons(1)

func craft_commons(amount: int) -> Dictionary:
	var max_count := get_max_craft_count()
	var wanted := max_count if amount < 0 else clampi(amount, 1, maxi(1, max_count))
	if max_count <= 0:
		return {"ok": false, "error": Loc.t("dust_missing") % CardDatabase.format_number(CRAFT_MISSING_COMMON_COST - dust)}
	var commons: Array = CardDatabase.get_cards_for_rarity("common")
	if commons.is_empty():
		return {"ok": false, "error": Loc.t("no_commons")}
	var crafted: Array = []
	var newly: Array = []
	while crafted.size() < wanted and dust >= CRAFT_MISSING_COMMON_COST:
		var missing: Array = []
		for card in commons:
			if not is_card_discovered(str(card.id)):
				missing.append(card)
		var pool: Array = missing if not missing.is_empty() else commons
		var card: Dictionary = pool[_rng.randi_range(0, pool.size() - 1)]
		dust -= CRAFT_MISSING_COMMON_COST
		inventory[str(card.id)] = get_card_count(str(card.id)) + 1
		if _mark_discovered(str(card.id)):
			newly.append(str(card.id))
		crafted.append(str(card.id))
	if crafted.is_empty():
		return {"ok": false, "error": Loc.t("no_commons")}
	save_state()
	inventory_changed.emit()
	dust_changed.emit(dust)
	var last_card: Dictionary = CardDatabase.get_card(str(crafted.back()))
	return {
		"ok": true,
		"card": last_card,
		"new": newly.has(str(last_card.id)),
		"amount": crafted.size(),
		"spent": crafted.size() * CRAFT_MISSING_COMMON_COST,
		"pulls": crafted,
		"newly_discovered": newly
	}

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

func complete_tutorial() -> void:
	tutorial_done = true
	_mark_guide_claimed()
	save_state()
	missions_changed.emit()

# -----------------------------------------------------------------------------
# Marché : hors-ligne (démo) ou multijoueur via backend/server.py
# -----------------------------------------------------------------------------

func _boot_market() -> void:
	await connect_market()

func is_market_online() -> bool:
	return market_online and market_connected

func get_market_listings() -> Array:
	return online_listings if is_market_online() else market_listings

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

func _tradable_snapshot() -> Dictionary:
	var cards := {}
	for card_id in CardDatabase.CARD_ORDER:
		var card := CardDatabase.get_card(card_id)
		if card.is_empty() or not bool(card.get("tradable", true)) or str(card.rarity) == "ultimate":
			continue
		var amount := get_available_count(card_id)
		if amount > 0:
			cards[card_id] = amount
	return cards

func _http_json(method: String, path: String, payload: Dictionary = {}) -> Dictionary:
	if _http == null:
		return {"ok": false, "error": Loc.t("market_no_network")}
	while _http_busy:
		await get_tree().process_frame
	_http_busy = true
	var url := server_url.rstrip("/") + path
	var headers := PackedStringArray(["Content-Type: application/json"])
	if not server_token.is_empty():
		headers.append("Authorization: Bearer %s" % server_token)
	headers.append("Idempotency-Key: %s-%s" % [Time.get_unix_time_from_system(), _rng.randi()])
	var verb := HTTPClient.METHOD_GET
	if method == "POST":
		verb = HTTPClient.METHOD_POST
	elif method == "DELETE":
		verb = HTTPClient.METHOD_DELETE
	var body := "" if method == "GET" or method == "DELETE" else JSON.stringify(payload)
	var err := _http.request(url, headers, verb, body)
	if err != OK:
		_http_busy = false
		return {"ok": false, "error": Loc.t("market_no_network")}
	var completed: Array = await _http.request_completed
	_http_busy = false
	var code := int(completed[1])
	var raw := (completed[3] as PackedByteArray).get_string_from_utf8()
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "error": Loc.t("market_bad_response")}
	var data: Dictionary = parsed
	if code >= 400 and not data.has("error"):
		data["error"] = Loc.t("market_no_network")
	if not data.has("ok"):
		data["ok"] = code >= 200 and code < 300
	return data

func connect_market() -> Dictionary:
	if server_url.strip_edges().is_empty():
		server_url = "http://127.0.0.1:8787"
	if device_id.is_empty():
		device_id = "%x-%d" % [_rng.randi(), Time.get_unix_time_from_system()]
	var session: Dictionary = await _http_json("POST", "/v1/auth/session", {"device_id": device_id})
	if not bool(session.get("ok", false)):
		market_connected = false
		market_changed.emit()
		return {"ok": false, "error": str(session.get("error", Loc.t("market_no_network")))}
	server_token = str(session.get("token", ""))
	server_user_id = str(session.get("user_id", ""))
	public_name = str(session.get("public_name", ""))
	var synced: Dictionary = await _http_json("POST", "/v1/market/sync", {"coins": market_coins, "cards": _tradable_snapshot()})
	if not bool(synced.get("ok", false)):
		market_connected = false
		market_changed.emit()
		return {"ok": false, "error": str(synced.get("error", Loc.t("market_no_network")))}
	var server_coins := int(synced.get("coins", market_coins))
	if server_coins != market_coins:
		market_coins = server_coins
		coins_changed.emit(market_coins)
	last_server_coins = server_coins
	market_online = true
	market_connected = true
	await refresh_market_listings()
	save_state()
	market_changed.emit()
	return {"ok": true, "public_name": public_name}

func disconnect_market() -> void:
	market_online = false
	market_connected = false
	online_listings.clear()
	save_state()
	market_changed.emit()

func refresh_market_listings() -> Dictionary:
	if not market_online:
		return {"ok": true}
	var result: Dictionary = await _http_json("GET", "/v1/market/listings")
	if not bool(result.get("ok", false)):
		market_connected = false
		market_changed.emit()
		return result
	market_connected = true
	online_listings.clear()
	var rows = result.get("listings", [])
	if typeof(rows) == TYPE_ARRAY:
		for row in rows:
			if typeof(row) != TYPE_DICTIONARY:
				continue
			var card_id := str(row.get("card_id", ""))
			if not CardDatabase.CARDS.has(card_id):
				continue
			var mine := bool(row.get("is_mine", false)) or str(row.get("seller_id", "")) == server_user_id
			online_listings.append({
				"id": str(row.get("id", "")),
				"seller": str(row.get("seller", public_name)),
				"card_id": card_id,
				"quantity": int(row.get("quantity", 1)),
				"unit_price": int(row.get("unit_price", 1)),
				"currency": "coins",
				"is_player": mine,
				"created_at": int(row.get("created_at", 0))
			})
	var wallet: Dictionary = await _http_json("GET", "/v1/wallet")
	if bool(wallet.get("ok", false)):
		_apply_server_coins(int(wallet.get("coins", market_coins)))
	market_changed.emit()
	return {"ok": true}

func _apply_server_coins(server_coins: int) -> void:
	if last_server_coins < 0:
		last_server_coins = market_coins
	var delta := server_coins - last_server_coins
	last_server_coins = server_coins
	if delta == 0:
		return
	market_coins = maxi(0, market_coins + delta)
	coins_changed.emit(market_coins)
	save_state()

func _note_server_coins(server_coins: int) -> void:
	last_server_coins = server_coins

func create_market_listing(card_id: String, quantity: int, unit_price: int) -> Dictionary:
	var card := CardDatabase.get_card(card_id)
	if card.is_empty():
		return {"ok": false, "error": "Carte inconnue."}
	if not bool(card.get("tradable", true)) or str(card.rarity) == "ultimate":
		return {"ok": false, "error": "La carte Ultime est liée au compte et ne peut pas être vendue."}
	if quantity <= 0 or unit_price <= 0:
		return {"ok": false, "error": "La quantité et le prix doivent être positifs."}
	if get_available_count(card_id) < quantity:
		return {"ok": false, "error": "Vous ne possédez pas assez d’exemplaires disponibles."}
	if market_online:
		if not market_connected:
			var linked: Dictionary = await connect_market()
			if not bool(linked.ok):
				return linked
		var posted: Dictionary = await _http_json("POST", "/v1/market/listings", {"card_id": card_id, "quantity": quantity, "unit_price": unit_price})
		if not bool(posted.get("ok", false)):
			return {"ok": false, "error": str(posted.get("error", Loc.t("market_no_network")))}
		inventory[card_id] = get_card_count(card_id) - quantity
		_add_mission_progress("listing", 1)
		save_state()
		inventory_changed.emit()
		await refresh_market_listings()
		return {"ok": true, "listing": posted.get("listing", {})}
	inventory[card_id] = get_card_count(card_id) - quantity
	var listing := _make_listing("Vous", card_id, quantity, unit_price, true)
	market_listings.push_front(listing)
	_add_mission_progress("listing", 1)
	save_state()
	inventory_changed.emit()
	market_changed.emit()
	return {"ok": true, "listing": listing}

func buy_market_listing(listing_id: String) -> Dictionary:
	if market_online:
		if not market_connected:
			var linked: Dictionary = await connect_market()
			if not bool(linked.ok):
				return linked
		var bought: Dictionary = await _http_json("POST", "/v1/market/orders", {"listing_id": listing_id})
		if not bool(bought.get("ok", false)):
			await refresh_market_listings()
			return {"ok": false, "error": str(bought.get("error", Loc.t("market_no_network")))}
		var card_id := str(bought.get("card_id", ""))
		var quantity := int(bought.get("quantity", 1))
		var total := int(bought.get("total", 0))
		if market_coins < total:
			market_coins = total
		market_coins -= total
		if CardDatabase.CARDS.has(card_id):
			inventory[card_id] = get_card_count(card_id) + quantity
			_mark_discovered(card_id)
		if bought.has("coins"):
			_note_server_coins(int(bought.coins))
		market_purchases += 1
		save_state()
		coins_changed.emit(market_coins)
		inventory_changed.emit()
		await refresh_market_listings()
		return {"ok": true, "total": total, "listing": {"card_id": card_id, "quantity": quantity}}
	var index := _find_listing_index(listing_id)
	if index < 0:
		return {"ok": false, "error": "Cette offre n’est plus disponible."}
	var listing: Dictionary = market_listings[index]
	if bool(listing.get("is_player", false)):
		return {"ok": false, "error": "Vous ne pouvez pas acheter votre propre offre."}
	var local_total := int(listing.quantity) * int(listing.unit_price)
	if market_coins < local_total:
		return {"ok": false, "error": "Il manque %s jetons." % CardDatabase.format_number(local_total - market_coins)}
	market_coins -= local_total
	inventory[listing.card_id] = get_card_count(listing.card_id) + int(listing.quantity)
	_mark_discovered(str(listing.card_id))
	market_listings.remove_at(index)
	market_purchases += 1
	save_state()
	coins_changed.emit(market_coins)
	inventory_changed.emit()
	market_changed.emit()
	return {"ok": true, "listing": listing, "total": local_total}

func cancel_market_listing(listing_id: String) -> Dictionary:
	if market_online:
		if not market_connected:
			var linked: Dictionary = await connect_market()
			if not bool(linked.ok):
				return linked
		var listing := _find_online_listing(listing_id)
		var cancelled: Dictionary = await _http_json("DELETE", "/v1/market/listings/%s" % listing_id)
		if not bool(cancelled.get("ok", false)):
			await refresh_market_listings()
			return {"ok": false, "error": str(cancelled.get("error", Loc.t("market_no_network")))}
		if not listing.is_empty():
			inventory[str(listing.card_id)] = get_card_count(str(listing.card_id)) + int(listing.quantity)
		save_state()
		inventory_changed.emit()
		await refresh_market_listings()
		return {"ok": true}
	var index := _find_listing_index(listing_id)
	if index < 0:
		return {"ok": false, "error": "Offre introuvable."}
	var local_listing: Dictionary = market_listings[index]
	if not bool(local_listing.get("is_player", false)):
		return {"ok": false, "error": "Cette offre ne vous appartient pas."}
	inventory[local_listing.card_id] = get_card_count(local_listing.card_id) + int(local_listing.quantity)
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

func _find_online_listing(listing_id: String) -> Dictionary:
	for listing in online_listings:
		if str(listing.get("id", "")) == listing_id:
			return listing
	return {}

# -----------------------------------------------------------------------------
# Sauvegarde et migration
# -----------------------------------------------------------------------------

func reset_progress() -> void:
	essence = STARTING_ESSENCE
	market_coins = STARTING_MARKET_COINS
	dust = 0
	inventory.clear()
	reserved.clear()
	discovered_cards.clear()
	claimed_habitats.clear()
	claimed_albums.clear()
	card_mastery.clear()
	pity_counts = {"rare": 0, "epic": 0, "legendary": 0, "unique": 0}
	_initialize_inventory()
	lifetime_cards = 0
	lifetime_crates = 0
	lifetime_fusions = 0
	farm_actions = 0
	market_purchases = 0
	selected_crate = "small"
	market_listings.clear()
	market_initialized = false
	tutorial_done = false
	farm_yield_level = 0
	farm_speed_level = 0
	farm_passive_level = 0
	luck_level = 0
	quest_progress.clear()
	claimed_quests.clear()
	market_online = false
	market_connected = false
	online_listings.clear()
	server_token = ""
	server_user_id = ""
	public_name = ""
	last_server_coins = -1
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
	mastery_changed.emit()

func save_state() -> void:
	last_seen_unix = int(Time.get_unix_time_from_system())
	var file := FileAccess.open(get_save_path(), FileAccess.WRITE)
	if file == null:
		return
	var data := {
		"version": SAVE_VERSION,
		"essence": essence,
		"market_coins": market_coins,
		"dust": dust,
		"inventory": inventory,
		"reserved": reserved,
		"discovered_cards": discovered_cards,
		"claimed_habitats": claimed_habitats,
		"claimed_albums": claimed_albums,
		"card_mastery": card_mastery,
		"pity_counts": pity_counts,
		"lifetime_cards": lifetime_cards,
		"lifetime_crates": lifetime_crates,
		"lifetime_fusions": lifetime_fusions,
		"farm_actions": farm_actions,
		"market_purchases": market_purchases,
		"selected_crate": selected_crate,
		"market_listings": market_listings,
		"market_initialized": market_initialized,
		"tutorial_done": tutorial_done,
		"farm_yield_level": farm_yield_level,
		"farm_speed_level": farm_speed_level,
		"farm_passive_level": farm_passive_level,
		"luck_level": luck_level,
		"quest_progress": quest_progress,
		"claimed_quests": claimed_quests,
		"market_online": market_online,
		"server_url": server_url,
		"device_id": device_id,
		"server_token": server_token,
		"server_user_id": server_user_id,
		"public_name": public_name,
		"last_server_coins": last_server_coins,
		"language": language,
		"sound_volume": sound_volume,
		"sound_muted": sound_muted,
		"next_farm_at_unix": next_farm_at_unix,
		"last_seen_unix": last_seen_unix,
		"daily_date": daily_date,
		"daily_missions": daily_missions,
		"active_expedition": active_expedition
	}
	file.store_string(JSON.stringify(data))

func load_state() -> void:
	if not FileAccess.file_exists(get_save_path()):
		last_seen_unix = int(Time.get_unix_time_from_system())
		return
	var file := FileAccess.open(get_save_path(), FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var loaded_version := int(parsed.get("version", 1))
	essence = maxi(0, int(parsed.get("essence", STARTING_ESSENCE)))
	if loaded_version < 3:
		essence = STARTING_ESSENCE
	market_coins = maxi(0, int(parsed.get("market_coins", STARTING_MARKET_COINS)))
	dust = maxi(0, int(parsed.get("dust", 0)))
	var loaded_inventory = parsed.get("inventory", {})
	if typeof(loaded_inventory) == TYPE_DICTIONARY:
		inventory = loaded_inventory
	_initialize_inventory()
	reserved.clear()
	var loaded_reserved = parsed.get("reserved", {})
	if typeof(loaded_reserved) == TYPE_DICTIONARY:
		for card_id in loaded_reserved:
			if CardDatabase.CARDS.has(str(card_id)):
				reserved[str(card_id)] = maxi(0, int(loaded_reserved[card_id]))
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
	card_mastery.clear()
	var loaded_mastery = parsed.get("card_mastery", {})
	if typeof(loaded_mastery) == TYPE_DICTIONARY:
		for card_id in loaded_mastery:
			if CardDatabase.CARDS.has(str(card_id)):
				card_mastery[str(card_id)] = maxi(0, int(loaded_mastery[card_id]))
	pity_counts = {"rare": 0, "epic": 0, "legendary": 0, "unique": 0}
	var loaded_pity = parsed.get("pity_counts", {})
	if typeof(loaded_pity) == TYPE_DICTIONARY:
		for rarity in PITY_CAPS:
			pity_counts[rarity] = maxi(0, int(loaded_pity.get(rarity, 0)))
	lifetime_cards = maxi(0, int(parsed.get("lifetime_cards", 0)))
	lifetime_crates = maxi(0, int(parsed.get("lifetime_crates", 0)))
	lifetime_fusions = maxi(0, int(parsed.get("lifetime_fusions", 0)))
	farm_actions = maxi(0, int(parsed.get("farm_actions", 0)))
	market_purchases = maxi(0, int(parsed.get("market_purchases", 0)))
	selected_crate = str(parsed.get("selected_crate", "small"))
	if not CardDatabase.CRATES.has(selected_crate):
		selected_crate = "small"
	market_initialized = bool(parsed.get("market_initialized", false))
	tutorial_done = bool(parsed.get("tutorial_done", false))
	farm_yield_level = clampi(int(parsed.get("farm_yield_level", 0)), 0, get_upgrade_max("yield"))
	farm_speed_level = clampi(int(parsed.get("farm_speed_level", 0)), 0, get_upgrade_max("speed"))
	farm_passive_level = clampi(int(parsed.get("farm_passive_level", 0)), 0, get_upgrade_max("passive"))
	luck_level = clampi(int(parsed.get("luck_level", 0)), 0, get_upgrade_max("luck"))
	quest_progress.clear()
	var loaded_quest_progress = parsed.get("quest_progress", {})
	if typeof(loaded_quest_progress) == TYPE_DICTIONARY:
		for quest_id in loaded_quest_progress:
			quest_progress[str(quest_id)] = maxi(0, int(loaded_quest_progress[quest_id]))
	claimed_quests.clear()
	var loaded_claimed = parsed.get("claimed_quests", [])
	if typeof(loaded_claimed) == TYPE_ARRAY:
		for quest_id in loaded_claimed:
			claimed_quests.append(str(quest_id))
	if tutorial_done:
		_mark_guide_claimed()
	language = "en" if str(parsed.get("language", "fr")) == "en" else "fr"
	sound_volume = clampf(float(parsed.get("sound_volume", 1.0)), 0.0, 1.0)
	sound_muted = bool(parsed.get("sound_muted", false))
	market_online = bool(parsed.get("market_online", false))
	server_url = str(parsed.get("server_url", server_url)).strip_edges()
	if server_url.is_empty():
		server_url = "http://127.0.0.1:8787"
	device_id = str(parsed.get("device_id", device_id))
	server_token = str(parsed.get("server_token", ""))
	server_user_id = str(parsed.get("server_user_id", ""))
	public_name = str(parsed.get("public_name", ""))
	last_server_coins = int(parsed.get("last_server_coins", -1))
	market_connected = false
	online_listings.clear()
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
		# Recalage du séquestre si une vieille save n’avait pas reserved.
		if reserved.is_empty():
			for card_id in active_expedition.get("team", []):
				if CardDatabase.CARDS.has(str(card_id)) and get_available_count(str(card_id)) > 0:
					_reserve(str(card_id), 1)
	var saved_last_seen := int(parsed.get("last_seen_unix", int(Time.get_unix_time_from_system())))
	_apply_offline_income(saved_last_seen)

func _apply_offline_income(saved_last_seen: int) -> void:
	var now := int(Time.get_unix_time_from_system())
	var elapsed := clampi(now - saved_last_seen, 0, OFFLINE_CAP_SECONDS)
	var ticks := int(elapsed / PASSIVE_INTERVAL_SECONDS)
	pending_offline_essence = ticks * get_passive_reward()
	if pending_offline_essence > 0:
		essence += pending_offline_essence
	last_seen_unix = now

func _on_passive_tick() -> void:
	_ensure_daily_missions()
	essence += get_passive_reward()
	essence_changed.emit(essence)
	farm_state_changed.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_state()

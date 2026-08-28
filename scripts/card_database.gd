extends Node
## Base de données centrale des cartes, raretés, fusions et caisses.

const CATALOG_PATH := "res://data/card_catalog.json"
const COLLECTIONS_PATH := "res://data/collections.json"

const RARITY_ORDER: Array[String] = [
	"common", "rare", "epic", "legendary", "unique", "ultimate"
]

# Coût en exemplaires IDENTIQUES pour produire une carte aléatoire du rang suivant.
const FUSION_COSTS := {
	"common": 10,
	"rare": 500,
	"epic": 1000,
	"legendary": 10000
}

const RARITIES := {
	"common": {
		"label": "COMMUNE",
		"short_label": "Commune",
		"color": Color("55d982"),
		"dark": Color("123b2a"),
		"glow": Color("72f0a0"),
		"drop_rate": 89.39,
		"stars": 1
	},
	"rare": {
		"label": "RARE",
		"short_label": "Bleue",
		"color": Color("3b8cff"),
		"dark": Color("102d63"),
		"glow": Color("54c7ff"),
		"drop_rate": 10.0,
		"stars": 2
	},
	"epic": {
		"label": "ÉPIQUE",
		"short_label": "Violette",
		"color": Color("ac55ff"),
		"dark": Color("3d155f"),
		"glow": Color("e278ff"),
		"drop_rate": 0.5,
		"stars": 3
	},
	"legendary": {
		"label": "LÉGENDAIRE",
		"short_label": "Orange",
		"color": Color("ff941f"),
		"dark": Color("60260c"),
		"glow": Color("ffd05a"),
		"drop_rate": 0.1,
		"stars": 4
	},
	"unique": {
		"label": "UNIQUE",
		"short_label": "Chrome",
		"color": Color("d8e1ea"),
		"dark": Color("323b49"),
		"glow": Color("ffffff"),
		"drop_rate": 0.01,
		"stars": 5
	},
	"ultimate": {
		"label": "ULTIME",
		"short_label": "Or-Obsidienne",
		"color": Color("ffe08a"),
		"dark": Color("29180a"),
		"glow": Color("fff4c7"),
		"drop_rate": 0.0,
		"stars": 6
	}
}

const CRATE_ORDER: Array[String] = ["small", "medium", "large", "titan"]

# Les prix conservent une réduction progressive par carte.
const CRATES := {
	"small": {
		"label": "PETITE",
		"cards": 6,
		"cost": 150,
		"subtitle": "25 essences / carte"
	},
	"medium": {
		"label": "MOYENNE",
		"cards": 15,
		"cost": 330,
		"subtitle": "22 essences / carte"
	},
	"large": {
		"label": "GRANDE",
		"cards": 25,
		"cost": 500,
		"subtitle": "20 essences / carte"
	},
	"titan": {
		"label": "TRÈS GRANDE",
		"cards": 50,
		"cost": 850,
		"subtitle": "17 essences / carte"
	}
}

var CARD_ORDER: Array[String] = []
var CARDS: Dictionary = {}
var CARD_IDS_BY_RARITY: Dictionary = {}
var HABITAT_ORDER: Array[String] = []
var HABITATS: Dictionary = {}
var ALBUM_ORDER: Array[String] = []
var ALBUMS: Dictionary = {}

func _init() -> void:
	_load_catalog()
	_load_collections()

func _load_catalog() -> void:
	CARD_ORDER.clear()
	CARDS.clear()
	CARD_IDS_BY_RARITY.clear()
	for rarity in RARITY_ORDER:
		CARD_IDS_BY_RARITY[rarity] = PackedStringArray()
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_error("Catalogue de cartes introuvable : %s" % CATALOG_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Le catalogue de cartes doit être un tableau JSON.")
		return
	for value in parsed:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = value
		var card_id := str(card.get("id", ""))
		if card_id.is_empty():
			continue
		CARDS[card_id] = card
		CARD_ORDER.append(card_id)
		var rarity := str(card.get("rarity", ""))
		if CARD_IDS_BY_RARITY.has(rarity):
			var rarity_ids: PackedStringArray = CARD_IDS_BY_RARITY[rarity]
			rarity_ids.append(card_id)
			CARD_IDS_BY_RARITY[rarity] = rarity_ids

func _load_collections() -> void:
	HABITAT_ORDER.clear()
	HABITATS.clear()
	ALBUM_ORDER.clear()
	ALBUMS.clear()
	var file := FileAccess.open(COLLECTIONS_PATH, FileAccess.READ)
	if file == null:
		push_error("Collections introuvables : %s" % COLLECTIONS_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Le fichier des collections doit être un objet JSON.")
		return
	for value in parsed.get("habitats", []):
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var habitat: Dictionary = value
		var habitat_id := str(habitat.get("id", ""))
		if habitat_id.is_empty():
			continue
		HABITATS[habitat_id] = habitat
		HABITAT_ORDER.append(habitat_id)
	for value in parsed.get("albums", []):
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var album: Dictionary = value
		var album_id := str(album.get("id", ""))
		if album_id.is_empty():
			continue
		ALBUMS[album_id] = album
		ALBUM_ORDER.append(album_id)

func get_habitat(habitat_id: String) -> Dictionary:
	return HABITATS.get(habitat_id, {})

func get_album(album_id: String) -> Dictionary:
	return ALBUMS.get(album_id, {})

func get_card(card_id: String) -> Dictionary:
	return CARDS.get(card_id, {})

func get_card_ids_for_rarity(rarity: String) -> PackedStringArray:
	return CARD_IDS_BY_RARITY.get(rarity, PackedStringArray())

func get_cards_for_rarity(rarity: String) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	for card_id in get_card_ids_for_rarity(rarity):
		matches.append(CARDS[card_id])
	return matches

func get_card_for_rarity(rarity: String) -> Dictionary:
	var ids := get_card_ids_for_rarity(rarity)
	return CARDS[ids[0]] if not ids.is_empty() else {}

func get_random_card_for_rarity(rarity: String, rng: RandomNumberGenerator) -> Dictionary:
	var ids := get_card_ids_for_rarity(rarity)
	if ids.is_empty():
		return {}
	return CARDS[ids[rng.randi_range(0, ids.size() - 1)]]

func get_card_drop_rate(card_id: String) -> float:
	var card := get_card(card_id)
	if card.is_empty():
		return 0.0
	var rarity: String = card.rarity
	var cards_in_rarity := get_card_ids_for_rarity(rarity).size()
	if cards_in_rarity <= 0:
		return 0.0
	return float(RARITIES[rarity].drop_rate) / float(cards_in_rarity)

func get_next_rarity(rarity: String) -> String:
	var index := RARITY_ORDER.find(rarity)
	if index < 0 or index >= RARITY_ORDER.size() - 1:
		return ""
	return RARITY_ORDER[index + 1]

func get_fusion_cost(rarity: String) -> int:
	return int(FUSION_COSTS.get(rarity, 0))

func roll_rarity(rng: RandomNumberGenerator) -> String:
	# Tirage exclusif : 0,01 % + 0,1 % + 0,5 % + 10 % ;
	# la commune reçoit le reste, soit exactement 89,39 %.
	var roll := rng.randf()
	if roll < 0.0001:
		return "unique"
	if roll < 0.0011:
		return "legendary"
	if roll < 0.0061:
		return "epic"
	if roll < 0.1061:
		return "rare"
	return "common"

func format_rate(value: float) -> String:
	var formatted := ""
	if value >= 0.01:
		formatted = "%.2f" % value
	elif value >= 0.001:
		formatted = "%.4f" % value
	else:
		formatted = "%.5f" % value
	while formatted.ends_with("0"):
		formatted = formatted.trim_suffix("0")
	if formatted.ends_with("."):
		formatted = formatted.trim_suffix(".")
	return formatted.replace(".", ",") + " %"

func format_number(value: int) -> String:
	var source := str(maxi(value, 0))
	var output := ""
	while source.length() > 3:
		output = " " + source.right(3) + output
		source = source.left(source.length() - 3)
	return source + output

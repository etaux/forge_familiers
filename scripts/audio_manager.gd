extends Node
## SFX courts. Volume et sourdine viennent des réglages.

const SFX := {
	"click": "res://assets/audio/click.wav",
	"harvest": "res://assets/audio/harvest.wav",
	"crate_open": "res://assets/audio/crate_open.wav",
	"reveal": "res://assets/audio/reveal.wav",
	"rare": "res://assets/audio/rare.wav",
	"fusion": "res://assets/audio/fusion.wav",
	"mission": "res://assets/audio/mission.wav",
	"error": "res://assets/audio/error.wav",
	"unique": "res://assets/audio/unique.wav",
	"flip": "res://assets/audio/flip.mp3",
	"magic": "res://assets/audio/magic.wav"
}

const HIGH_RARITIES := ["rare", "epic", "legendary", "unique", "ultimate"]

var volume := 1.0
var _muted := false

func _ready() -> void:
	volume = clampf(float(GameState.sound_volume), 0.0, 1.0)
	_muted = bool(GameState.sound_muted)

func is_muted() -> bool:
	return _muted

func set_muted(value: bool) -> void:
	_muted = value
	GameState.sound_muted = value
	GameState.save_state()

func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	GameState.sound_volume = volume
	if volume > 0.001:
		_muted = false
		GameState.sound_muted = false
	GameState.save_state()

func play(kind: String, delay: float = 0.0) -> void:
	if _muted or volume <= 0.001 or not SFX.has(kind):
		return
	if delay > 0.0:
		var wait := get_tree().create_timer(delay)
		wait.timeout.connect(func() -> void: play(kind, 0.0))
		return
	var stream: AudioStream = load(SFX[kind])
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	var base := -2.5 if kind == "flip" else -4.0
	player.volume_db = base + linear_to_db(maxf(volume, 0.001))
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func play_rarity(rarity: String) -> void:
	play_card_reveal(rarity)

func play_card_reveal(rarity: String) -> void:
	play("flip")
	if rarity in HIGH_RARITIES:
		play("magic", 0.16)

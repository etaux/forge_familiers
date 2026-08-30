class_name FarmWorld
extends Control
## Ferme dessinée : ciel, collines, grange, familiers qui se promènent.

signal harvest_tapped

const CrateViewScene := preload("res://scripts/crate_view.gd")

var crate_id: String = "small"
var _time := 0.0
var _wanderers: Array[Dictionary] = []
var _crate_view: OriginCrateView
var _flash := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(0, 210)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_crate_view = CrateViewScene.new()
	_crate_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_crate_view)
	set_process(true)
	refresh_wanderers()

func set_crate(value: String) -> void:
	crate_id = value
	if _crate_view:
		_crate_view.set_crate(value)
	queue_redraw()

func punch() -> void:
	_flash = 1.0
	if _crate_view:
		_crate_view.punch()

func refresh_wanderers() -> void:
	_wanderers.clear()
	var ids := GameState.get_wanderers(8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for index in range(ids.size()):
		var card := CardDatabase.get_card(ids[index])
		if card.is_empty():
			continue
		_wanderers.append({
			"id": ids[index],
			"texture": load(str(card.art)),
			"x": rng.randf_range(0.08, 0.78),
			"y": rng.randf_range(0.52, 0.78),
			"speed": rng.randf_range(0.015, 0.04) * (1.0 if index % 2 == 0 else -1.0),
			"phase": rng.randf() * TAU,
			"size": rng.randf_range(34.0, 52.0)
		})
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	_flash = move_toward(_flash, 0.0, delta * 2.4)
	for wanderer in _wanderers:
		wanderer.x = float(wanderer.x) + float(wanderer.speed) * delta
		if float(wanderer.x) > 0.84 or float(wanderer.x) < 0.06:
			wanderer.speed = -float(wanderer.speed)
			wanderer.x = clampf(float(wanderer.x), 0.06, 0.84)
	if _crate_view:
		var barn := Rect2(size.x * 0.58, size.y * 0.18, size.x * 0.38, size.y * 0.62)
		_crate_view.position = barn.position + Vector2(8, 18)
		_crate_view.size = Vector2(maxi(120, int(barn.size.x - 16)), maxi(90, int(barn.size.y - 28)))
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	var tap := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tap = true
	elif event is InputEventScreenTouch and event.pressed:
		tap = true
	if not tap:
		return
	var local := Vector2.ZERO
	if event is InputEventMouseButton:
		local = event.position
	elif event is InputEventScreenTouch:
		local = event.position
	# Orbes de récolte à gauche, ou n’importe où sur l’herbe.
	if local.y > size.y * 0.42:
		harvest_tapped.emit()
		accept_event()

func _draw() -> void:
	if size.x < 4.0 or size.y < 4.0:
		return
	var sky := Rect2(Vector2.ZERO, size)
	draw_rect(sky, Color("1a2758"))
	draw_rect(Rect2(0, 0, size.x, size.y * 0.45), Color("24356e"))
	var sun_pos := Vector2(size.x * 0.16, size.y * 0.18)
	draw_circle(sun_pos, 22.0 + sin(_time * 1.4) * 1.5, Color(1.0, 0.86, 0.55, 0.95))
	draw_circle(sun_pos, 36.0, Color(1.0, 0.78, 0.42, 0.12 + _flash * 0.08))

	var hill := PackedVector2Array([
		Vector2(0, size.y * 0.58), Vector2(size.x * 0.22, size.y * 0.46),
		Vector2(size.x * 0.48, size.y * 0.56), Vector2(size.x * 0.78, size.y * 0.42),
		Vector2(size.x, size.y * 0.52), Vector2(size.x, size.y), Vector2(0, size.y)
	])
	draw_colored_polygon(hill, Color("1d4a38"))
	var grass := Rect2(0, size.y * 0.62, size.x, size.y * 0.38)
	draw_rect(grass, Color("246044"))
	draw_rect(Rect2(0, size.y * 0.62, size.x, 6), Color("2f7a56"))

	# Étang
	var pond := Rect2(size.x * 0.08, size.y * 0.72, size.x * 0.28, size.y * 0.16)
	draw_style_box(_round(Color("1a5d7a"), 18), pond)
	draw_style_box(_round(Color(0.45, 0.85, 1.0, 0.18 + sin(_time) * 0.04), 14), pond.grow(-4.0))

	# Arbres
	for tree_x in [0.40, 0.48, 0.90]:
		var base := Vector2(size.x * tree_x, size.y * 0.70)
		draw_rect(Rect2(base.x - 3, base.y - 18, 6, 22), Color("4a2d18"))
		draw_circle(base + Vector2(0, -28), 16, Color("1f6b3a"))
		draw_circle(base + Vector2(-10, -22), 11, Color("25824a"))

	# Grange
	var barn := Rect2(size.x * 0.58, size.y * 0.22, size.x * 0.38, size.y * 0.58)
	draw_style_box(_round(Color("6b2e28"), 10, Color("e8c07a"), 2), barn)
	var roof := PackedVector2Array([
		Vector2(barn.position.x - 8, barn.position.y + 18),
		Vector2(barn.position.x + barn.size.x * 0.5, barn.position.y - 16),
		Vector2(barn.end.x + 8, barn.position.y + 18)
	])
	draw_colored_polygon(roof, Color("8a3a32"))

	# Orbes de récolte
	var ready := GameState.can_farm()
	for index in range(3):
		var orb := Vector2(size.x * (0.18 + index * 0.12), size.y * 0.58 + sin(_time * 2.0 + index) * 4.0)
		var alpha := 0.55 + sin(_time * 3.0 + index) * 0.2 if ready else 0.18
		draw_circle(orb, 7.0 + _flash * 4.0, Color(0.55, 0.92, 1.0, alpha))
		draw_circle(orb, 3.0, Color(1, 1, 1, alpha + 0.2))

	for wanderer in _wanderers:
		var tex: Texture2D = wanderer.texture
		if tex == null:
			continue
		var bob := sin(_time * 2.4 + float(wanderer.phase)) * 3.0
		var dim := float(wanderer.size)
		var dest := Rect2(size.x * float(wanderer.x), size.y * float(wanderer.y) + bob, dim, dim)
		draw_texture_rect(tex, dest, false)
		draw_arc(dest.get_center() + Vector2(0, dim * 0.42), dim * 0.28, 0, TAU, 12, Color(0, 0, 0, 0.18), 2.0)

func _round(background: Color, radius: int, border: Color = Color.TRANSPARENT, width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	if width > 0:
		style.border_color = border
		style.border_width_left = width
		style.border_width_top = width
		style.border_width_right = width
		style.border_width_bottom = width
	return style

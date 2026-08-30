class_name CreatureCard
extends Control
## Carte visuelle réutilisable dans la collection, les ouvertures et les détails.

signal card_pressed(card: Dictionary)
signal flipped(card: Dictionary)

const CardFX := preload("res://scripts/card_fx.gd")
const FontKit := preload("res://scripts/ui_fonts.gd")

var _font_regular: Font
var _font_semibold: Font
var _font_bold: Font
var _font_extrabold: Font
var card_data: Dictionary = {}
var quantity: int = 0
var is_locked: bool = false
var interactive: bool = false
var show_quantity: bool = true
var face_down: bool = false
var _flipping: bool = false
var _flip_tween: Tween

var _art: TextureRect
var _dim: ColorRect
var _fx: Control
var _rarity_label: Label
var _quantity_label: Label
var _name_label: Label
var _title_label: Label
var _odds_label: Label
var _number_label: Label
var _lock_label: Label

func _ready() -> void:
	_font_regular = FontKit.make(500.0)
	_font_semibold = FontKit.make(650.0)
	_font_bold = FontKit.make(760.0)
	_font_extrabold = FontKit.make(900.0)
	custom_minimum_size = Vector2(210, 310)
	clip_contents = true
	_build_children()
	_apply_data()
	_layout_children()
	queue_redraw()

func configure(data: Dictionary, owned_quantity: int = 0, locked: bool = false, can_press: bool = false) -> void:
	card_data = data
	quantity = owned_quantity
	is_locked = locked
	interactive = can_press
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if interactive else Control.CURSOR_ARROW
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	if is_node_ready():
		_apply_data()
		queue_redraw()

func set_face_down(value: bool) -> void:
	face_down = value
	_flipping = false
	scale = Vector2.ONE
	if is_node_ready():
		_apply_face_visibility()
		queue_redraw()

func flip_to_front() -> void:
	if not face_down or _flipping or card_data.is_empty():
		return
	_flipping = true
	if size.x < 2.0:
		await get_tree().process_frame
		if not is_instance_valid(self) or not face_down:
			_flipping = false
			return
	pivot_offset = size * 0.5
	if _flip_tween and _flip_tween.is_running():
		_flip_tween.kill()
	_flip_tween = create_tween()
	_flip_tween.tween_property(self, "scale", Vector2(0.02, 1.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_flip_tween.tween_callback(_reveal_front)
	_flip_tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_flip_tween.tween_callback(func() -> void: _flipping = false)

func _reveal_front() -> void:
	if not is_instance_valid(self):
		return
	face_down = false
	_apply_face_visibility()
	queue_redraw()
	flipped.emit(card_data)

func set_quantity(value: int, discovered: bool = false) -> void:
	quantity = value
	is_locked = not discovered
	if is_node_ready():
		_apply_data()
		queue_redraw()

func _build_children() -> void:
	_art = TextureRect.new()
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)

	_dim = ColorRect.new()
	_dim.color = Color(0.015, 0.02, 0.055, 0.58)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)

	_fx = CardFX.new()
	add_child(_fx)

	_rarity_label = _new_label(12, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_rarity_label.add_theme_constant_override("outline_size", 3)
	_rarity_label.add_theme_color_override("font_outline_color", Color(0.01, 0.015, 0.04, 0.9))
	add_child(_rarity_label)

	_quantity_label = _new_label(14, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_quantity_label.add_theme_constant_override("outline_size", 3)
	_quantity_label.add_theme_color_override("font_outline_color", Color(0.01, 0.015, 0.04, 0.95))
	add_child(_quantity_label)

	_name_label = _new_label(21, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_name_label.add_theme_constant_override("outline_size", 3)
	_name_label.add_theme_color_override("font_outline_color", Color(0.01, 0.015, 0.04, 0.95))
	add_child(_name_label)

	_title_label = _new_label(11, Color("b9c2d8"), HORIZONTAL_ALIGNMENT_CENTER)
	_title_label.add_theme_constant_override("outline_size", 2)
	_title_label.add_theme_color_override("font_outline_color", Color(0.01, 0.015, 0.04, 0.9))
	add_child(_title_label)

	_odds_label = _new_label(11, Color("dbe4f5"), HORIZONTAL_ALIGNMENT_LEFT)
	add_child(_odds_label)

	_number_label = _new_label(11, Color("8f9bb6"), HORIZONTAL_ALIGNMENT_RIGHT)
	add_child(_number_label)

	_lock_label = _new_label(13, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_lock_label.add_theme_constant_override("outline_size", 3)
	_lock_label.add_theme_color_override("font_outline_color", Color(0.01, 0.015, 0.04, 0.96))
	add_child(_lock_label)

func _new_label(font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var final_size := maxi(12, font_size + 1)
	label.add_theme_font_size_override("font_size", final_size)
	if font_size >= 20:
		label.add_theme_font_override("font", _font_extrabold)
	elif font_size >= 13:
		label.add_theme_font_override("font", _font_bold)
	else:
		label.add_theme_font_override("font", _font_semibold)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return label

func _apply_data() -> void:
	if card_data.is_empty() or _art == null:
		return
	var rarity: String = card_data.rarity
	var rarity_data: Dictionary = CardDatabase.RARITIES[rarity]
	_art.texture = load(card_data.art)
	_art.modulate = Color(0.62, 0.66, 0.72, 0.72) if is_locked else Color.WHITE
	_dim.visible = is_locked
	_fx.configure(rarity)
	_fx.visible = not is_locked or rarity in ["unique", "ultimate"]
	_rarity_label.text = "%s  %s" % [_star_string(int(rarity_data.stars)), rarity_data.label]
	_rarity_label.add_theme_color_override("font_color", rarity_data.glow)
	_quantity_label.text = "×%s" % CardDatabase.format_number(quantity)
	_quantity_label.visible = show_quantity and quantity > 0
	_name_label.text = card_data.name
	_title_label.text = card_data.title
	_odds_label.text = "OBJECTIF ULTIME" if rarity == "ultimate" else "CHANCE  %s" % CardDatabase.format_rate(CardDatabase.get_card_drop_rate(str(card_data.id)))
	_number_label.text = "OR-%s" % card_data.number
	_lock_label.text = "À DÉCOUVRIR" if is_locked else ""
	_lock_label.visible = is_locked
	_apply_face_visibility()

func _apply_face_visibility() -> void:
	if _art == null:
		return
	var show_front := not face_down
	_art.visible = show_front
	_dim.visible = show_front and is_locked
	var rarity := str(card_data.get("rarity", "common"))
	_fx.visible = show_front and (not is_locked or rarity in ["unique", "ultimate"])
	_rarity_label.visible = show_front
	_quantity_label.visible = show_front and show_quantity and quantity > 0
	_name_label.visible = show_front
	_title_label.visible = show_front
	_odds_label.visible = show_front
	_number_label.visible = show_front
	_lock_label.visible = show_front and is_locked

func _star_string(count: int) -> String:
	var output := ""
	for _index in range(count):
		output += "◆"
	return output

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_layout_children()
		queue_redraw()

func _layout_children() -> void:
	if _art == null:
		return
	pivot_offset = size * 0.5
	var width := size.x
	var height := size.y
	var name_size := 22 if width >= 225.0 else 19
	if not card_data.is_empty() and str(card_data.name).length() > 12:
		name_size -= 2
	_name_label.add_theme_font_size_override("font_size", name_size)
	var padding := maxf(8.0, width * 0.052)
	var art_top := height * 0.122
	var art_height := height * 0.575

	_art.position = Vector2(padding, art_top)
	_art.size = Vector2(width - padding * 2.0, art_height)
	_dim.position = _art.position
	_dim.size = _art.size
	_fx.position = Vector2.ZERO
	_fx.size = size

	_rarity_label.position = Vector2(padding, height * 0.025)
	_rarity_label.size = Vector2(width - padding * 2.0, height * 0.082)
	_quantity_label.position = Vector2(width - padding - width * 0.28, art_top + 5.0)
	_quantity_label.size = Vector2(width * 0.27, height * 0.075)

	_name_label.position = Vector2(padding, height * 0.715)
	_name_label.size = Vector2(width - padding * 2.0, height * 0.09)
	_title_label.position = Vector2(padding, height * 0.794)
	_title_label.size = Vector2(width - padding * 2.0, height * 0.064)
	_odds_label.position = Vector2(padding, height * 0.885)
	_odds_label.size = Vector2(width * 0.61, height * 0.06)
	_number_label.position = Vector2(width * 0.62, height * 0.885)
	_number_label.size = Vector2(width - width * 0.62 - padding, height * 0.06)
	_lock_label.position = Vector2(padding, art_top + art_height * 0.37)
	_lock_label.size = Vector2(width - padding * 2.0, height * 0.09)

func _draw() -> void:
	if face_down:
		_draw_back()
		return
	if card_data.is_empty():
		return
	var rarity: String = card_data.rarity
	var rarity_data: Dictionary = CardDatabase.RARITIES[rarity]
	var frame_color: Color = rarity_data.color
	var dark_color: Color = rarity_data.dark
	var padding := maxf(8.0, size.x * 0.052)

	# Ombre, cadre, intérieur et panneau d’informations.
	draw_style_box(_box(Color(0.0, 0.0, 0.0, 0.48), 22), Rect2(3, 5, size.x - 6, size.y - 6))
	draw_style_box(_box(dark_color, 21, frame_color, 3), Rect2(1, 1, size.x - 2, size.y - 2))
	draw_style_box(_box(Color("0b1028"), 17, Color(frame_color, 0.42), 1), Rect2(7, 7, size.x - 14, size.y - 14))

	var art_rect := Rect2(padding, size.y * 0.122, size.x - padding * 2.0, size.y * 0.575)
	draw_style_box(_box(Color("080b18"), 12, Color(frame_color, 0.8), 2), art_rect.grow(2.0))
	var info_rect := Rect2(padding, size.y * 0.704, size.x - padding * 2.0, size.y * 0.255)
	draw_style_box(_box(Color(0.035, 0.045, 0.105, 0.96), 11, Color(frame_color, 0.24), 1), info_rect)

	# Petit sceau de rareté au sommet.
	var seal_width := size.x * 0.76
	var seal_rect := Rect2((size.x - seal_width) * 0.5, size.y * 0.027, seal_width, size.y * 0.074)
	draw_style_box(_box(Color(dark_color, 0.96), 14, Color(frame_color, 0.72), 1), seal_rect)

	if rarity == "legendary":
		draw_arc(size * Vector2(0.5, 0.41), size.x * 0.42, -2.75, -0.38, 28, Color(1.0, 0.78, 0.28, 0.55), 3.0)
	elif rarity == "unique":
		var spectral := [Color("61e8ff"), Color("a879ff"), Color("ff8bc8"), Color("ffe074")]
		for index in range(4):
			var y := 2.5 + float(index) * 1.4
			draw_line(Vector2(24, y), Vector2(size.x - 24, y), Color(spectral[index], 0.65), 1.2)
	elif rarity == "ultimate":
		for index in range(4):
			var inset := 3.0 + float(index) * 1.7
			var line_color := Color("fff4c7") if index % 2 == 0 else Color("d89b32")
			draw_line(Vector2(26, inset), Vector2(size.x - 26, inset), Color(line_color, 0.82), 1.4)
		draw_arc(size * Vector2(0.5, 0.40), size.x * 0.44, -2.85, -0.29, 36, Color(1.0, 0.88, 0.48, 0.70), 3.2)
		draw_circle(Vector2(20, 20), 3.2, Color("fff4c7"))
		draw_circle(Vector2(size.x - 20, 20), 3.2, Color("fff4c7"))

func _box(background: Color, radius: int, border: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	if border_width > 0:
		style.border_color = border
		style.border_width_left = border_width
		style.border_width_top = border_width
		style.border_width_right = border_width
		style.border_width_bottom = border_width
	return style

func _draw_back() -> void:
	var gold := Color("d4b45a")
	var violet := Color("8e68e8")
	draw_style_box(_box(Color(0.0, 0.0, 0.0, 0.48), 22), Rect2(3, 5, size.x - 6, size.y - 6))
	draw_style_box(_box(Color("140c28"), 21, gold, 3), Rect2(1, 1, size.x - 2, size.y - 2))
	draw_style_box(_box(Color("0b1028"), 16, Color(violet, 0.88), 1), Rect2(8, 8, size.x - 16, size.y - 16))
	var inset := Rect2(size.x * 0.11, size.y * 0.10, size.x * 0.78, size.y * 0.80)
	draw_style_box(_box(Color("181030"), 14, Color(gold, 0.72), 2), inset)
	var step := 18.0
	var lattice := inset.grow(-12.0)
	for row in range(12):
		for col in range(8):
			var point := inset.position + Vector2(16.0 + float(col) * step, 18.0 + float(row) * step)
			if lattice.has_point(point):
				draw_circle(point, 1.35, Color(gold, 0.22))
	var center := size * 0.5
	draw_circle(center, 40.0, Color("241848"))
	draw_arc(center, 36.0, 0.0, TAU, 42, Color(gold, 0.88), 2.2)
	draw_arc(center, 28.0, 0.0, TAU, 36, Color(violet, 0.55), 1.4)
	var gem := PackedVector2Array([
		center + Vector2(0, -22),
		center + Vector2(20, 0),
		center + Vector2(0, 22),
		center + Vector2(-20, 0)
	])
	draw_colored_polygon(gem, Color("765cff"))
	draw_polyline(PackedVector2Array([gem[0], gem[1], gem[2], gem[3], gem[0]]), Color("e5d6ff"), 2.0, true)
	if _font_bold:
		var label_width := size.x * 0.72
		var label_x := (size.x - label_width) * 0.5
		draw_string(_font_bold, Vector2(label_x, size.y * 0.78), "ORIGINE", HORIZONTAL_ALIGNMENT_CENTER, label_width, 15, Color("f2edff"))

func _gui_input(event: InputEvent) -> void:
	if not interactive or _flipping:
		return
	var is_press := false
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		is_press = mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		is_press = touch.pressed
	if not is_press:
		return
	if face_down:
		flip_to_front()
		accept_event()
		return
	if card_data.is_empty():
		return
	card_pressed.emit(card_data)
	accept_event()

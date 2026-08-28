class_name OriginCrateView
extends Control
## Représentation animée de la caisse unique « Origine », déclinée en 4 tailles.

var crate_id: String = "small"
var _time := 0.0
var _punch := 0.0
var _flash := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(0, 220)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func set_crate(value: String) -> void:
	if CardDatabase.CRATES.has(value):
		crate_id = value
		queue_redraw()

func punch() -> void:
	_punch = 0.11
	_flash = 1.0

func _process(delta: float) -> void:
	_time += delta
	_punch = move_toward(_punch, 0.0, delta * 0.55)
	_flash = move_toward(_flash, 0.0, delta * 2.8)
	queue_redraw()

func _draw() -> void:
	if not CardDatabase.CRATES.has(crate_id):
		return
	var crate: Dictionary = CardDatabase.CRATES[crate_id]
	var scale_by_size := {"small": 0.72, "medium": 0.82, "large": 0.93, "titan": 1.04}
	var crate_scale: float = scale_by_size[crate_id]
	var float_y := sin(_time * 1.7) * 4.0
	var rotation := sin(_time * 1.15) * 0.018
	var center := Vector2(size.x * 0.5, size.y * 0.50 + float_y)
	var pulse_scale := crate_scale * (1.0 + _punch)

	# Halo en coordonnées écran.
	var halo_alpha := 0.09 + sin(_time * 2.0) * 0.018 + _flash * 0.12
	for ring in range(4, 0, -1):
		draw_circle(center, 46.0 + ring * 24.0, Color(0.48, 0.31, 1.0, halo_alpha / float(ring)))

	draw_set_transform(center, rotation, Vector2.ONE * pulse_scale)
	var chest_w := 250.0
	var chest_h := 112.0
	var body_rect := Rect2(-chest_w * 0.5, -22.0, chest_w, chest_h)
	var lid_rect := Rect2(-chest_w * 0.5 - 7.0, -73.0, chest_w + 14.0, 62.0)

	# Ombre et corps.
	draw_style_box(_box(Color(0.0, 0.0, 0.0, 0.45), 22), Rect2(body_rect.position + Vector2(0, 10), body_rect.size))
	draw_style_box(_box(Color("211745"), 19, Color("8e68e8"), 4), body_rect)
	draw_style_box(_box(Color("3b276f"), 18, Color("d1b4ff"), 4), lid_rect)
	draw_rect(Rect2(-chest_w * 0.5 + 11.0, 7.0, chest_w - 22.0, 12.0), Color(0.66, 0.47, 1.0, 0.28))

	# Renforts métalliques.
	for x in [-88.0, 88.0]:
		draw_style_box(_box(Color("c18d42"), 5, Color("ffe099"), 2), Rect2(x - 12.0, -68.0, 24.0, 151.0))
	draw_style_box(_box(Color("b77a35"), 7, Color("ffdda0"), 2), Rect2(-chest_w * 0.5 - 5.0, -13.0, chest_w + 10.0, 22.0))

	# Gemme centrale.
	var gem := PackedVector2Array([
		Vector2(0, -45), Vector2(34, -7), Vector2(0, 40), Vector2(-34, -7)
	])
	draw_colored_polygon(gem, Color("765cff"))
	draw_polyline(PackedVector2Array([gem[0], gem[1], gem[2], gem[3], gem[0]]), Color("e5d6ff"), 4.0, true)
	draw_line(Vector2(0, -38), Vector2(0, 31), Color(0.75, 0.92, 1.0, 0.42), 3.0)
	draw_line(Vector2(-27, -7), Vector2(27, -7), Color(0.75, 0.92, 1.0, 0.42), 3.0)
	if _flash > 0.0:
		draw_circle(Vector2.ZERO, 30.0 + _flash * 18.0, Color(0.8, 0.9, 1.0, _flash * 0.24))

	# Marquage de série sur la caisse.
	var font := get_theme_default_font()
	draw_string(font, Vector2(-105, 57), "ORIGINE", HORIZONTAL_ALIGNMENT_CENTER, 210, 19, Color("f2edff"))
	draw_string(font, Vector2(-105, 82), "×%s CARTES" % CardDatabase.format_number(int(crate.cards)), HORIZONTAL_ALIGNMENT_CENTER, 210, 15, Color("c7bbdf"))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

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

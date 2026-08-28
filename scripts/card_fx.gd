extends Control
## Couche d’effets visuels dessinée au-dessus de l’illustration.

var rarity: String = "common"
var _time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func configure(value: String) -> void:
	rarity = value
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	if rarity in ["rare", "epic", "legendary", "unique", "ultimate"]:
		queue_redraw()

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var art_rect := Rect2(size.x * 0.055, size.y * 0.125, size.x * 0.89, size.y * 0.57)

	match rarity:
		"rare":
			_draw_orbiting_dust(art_rect, Color(0.25, 0.78, 1.0, 0.45), 6, 0.55)
		"epic":
			_draw_orbiting_dust(art_rect, Color(0.86, 0.38, 1.0, 0.62), 10, 0.9)
			var pulse := 0.15 + sin(_time * 2.2) * 0.05
			draw_arc(art_rect.get_center(), art_rect.size.x * 0.39, 0.0, TAU, 48, Color(0.65, 0.22, 1.0, pulse), 2.0)
		"legendary":
			_draw_orbiting_dust(art_rect, Color(1.0, 0.73, 0.22, 0.8), 14, 1.25)
			for ring in range(2):
				var radius := art_rect.size.x * (0.34 + float(ring) * 0.09)
				var alpha := 0.20 - float(ring) * 0.06 + sin(_time * 2.0 + ring) * 0.035
				draw_arc(art_rect.get_center(), radius, _time * 0.25, _time * 0.25 + 4.7, 40, Color(1.0, 0.55, 0.12, alpha), 2.5)
		"unique":
			_draw_chrome_effects(art_rect)
		"ultimate":
			_draw_ultimate_effects(art_rect)

func _draw_orbiting_dust(area: Rect2, color: Color, count: int, speed: float) -> void:
	for index in range(count):
		var seed := float(index) * 2.399
		var angle := seed + _time * speed * (0.28 + fmod(float(index), 3.0) * 0.08)
		var rx := area.size.x * (0.25 + fmod(float(index) * 0.071, 0.18))
		var ry := area.size.y * (0.27 + fmod(float(index) * 0.053, 0.16))
		var position := area.get_center() + Vector2(cos(angle) * rx, sin(angle) * ry)
		var radius := 1.2 + fmod(float(index), 3.0) * 0.65
		var twinkle := 0.55 + sin(_time * 3.0 + seed) * 0.35
		var particle_color := color
		particle_color.a *= twinkle
		draw_circle(position, radius, particle_color)

func _draw_chrome_effects(area: Rect2) -> void:
	# Reflet mobile façon feuille holographique.
	var travel := fmod(_time * 0.30, 1.55) - 0.28
	var x := area.position.x + area.size.x * travel
	var shine_width := area.size.x * 0.22
	var shine := PackedVector2Array([
		Vector2(x - shine_width, area.position.y),
		Vector2(x, area.position.y),
		Vector2(x + shine_width, area.end.y),
		Vector2(x, area.end.y)
	])
	draw_colored_polygon(shine, Color(1.0, 1.0, 1.0, 0.13))

	var spectral := [
		Color(0.35, 0.9, 1.0, 0.65),
		Color(0.78, 0.45, 1.0, 0.58),
		Color(1.0, 0.56, 0.78, 0.52),
		Color(1.0, 0.88, 0.4, 0.52)
	]
	for index in range(16):
		var angle := float(index) * 2.17 + _time * (0.16 + float(index % 3) * 0.035)
		var radius_x := area.size.x * (0.25 + fmod(float(index) * 0.043, 0.2))
		var radius_y := area.size.y * (0.26 + fmod(float(index) * 0.037, 0.18))
		var position := area.get_center() + Vector2(cos(angle) * radius_x, sin(angle) * radius_y)
		var sparkle_color: Color = spectral[index % spectral.size()]
		sparkle_color.a *= 0.55 + sin(_time * 4.0 + index) * 0.35
		_draw_star(position, 2.0 + float(index % 3), sparkle_color)

	for ring in range(3):
		var ring_color: Color = spectral[ring]
		ring_color.a = 0.11 + sin(_time * 1.7 + ring) * 0.025
		draw_arc(area.get_center(), area.size.x * (0.31 + ring * 0.065), _time * 0.18 + ring, _time * 0.18 + ring + 4.8, 48, ring_color, 2.0)

func _draw_ultimate_effects(area: Rect2) -> void:
	# Balayage or-blanc plus intense que le chrome.
	var travel := fmod(_time * 0.24, 1.65) - 0.32
	var x := area.position.x + area.size.x * travel
	var width := area.size.x * 0.28
	var shine := PackedVector2Array([
		Vector2(x - width, area.position.y),
		Vector2(x, area.position.y),
		Vector2(x + width, area.end.y),
		Vector2(x, area.end.y)
	])
	draw_colored_polygon(shine, Color(1.0, 0.91, 0.58, 0.16))
	_draw_orbiting_dust(area, Color(1.0, 0.84, 0.35, 0.85), 22, 1.45)
	var colors := [Color("62e4ff"), Color("6fa8ff"), Color("b983ff"), Color("ff9b55"), Color("fff0b0")]
	for ring in range(4):
		var ring_color: Color = colors[ring]
		ring_color.a = 0.18 + sin(_time * 2.1 + ring) * 0.035
		var radius := area.size.x * (0.27 + ring * 0.055)
		draw_arc(area.get_center(), radius, -_time * (0.16 + ring * 0.025) + ring, -_time * (0.16 + ring * 0.025) + ring + 5.0, 52, ring_color, 2.3)
	for index in range(12):
		var angle := float(index) * TAU / 12.0 + _time * 0.19
		var position := area.get_center() + Vector2(cos(angle) * area.size.x * 0.42, sin(angle) * area.size.y * 0.39)
		var star_color: Color = colors[index % colors.size()]
		star_color.a = 0.55 + sin(_time * 3.5 + index) * 0.25
		_draw_star(position, 2.6 + float(index % 3), star_color)

func _draw_star(position: Vector2, radius: float, color: Color) -> void:
	draw_line(position - Vector2(radius * 2.0, 0.0), position + Vector2(radius * 2.0, 0.0), color, 1.3)
	draw_line(position - Vector2(0.0, radius * 2.0), position + Vector2(0.0, radius * 2.0), color, 1.3)
	draw_circle(position, radius * 0.55, Color(color.r, color.g, color.b, minf(color.a + 0.2, 1.0)))

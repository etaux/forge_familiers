extends Control
## Fond léger et animé, sans ressource externe.

var _time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	# Grandes auréoles atmosphériques.
	draw_circle(Vector2(size.x * 0.15, size.y * 0.22), size.x * 0.42, Color(0.22, 0.12, 0.58, 0.075))
	draw_circle(Vector2(size.x * 0.92, size.y * 0.68), size.x * 0.48, Color(0.06, 0.38, 0.58, 0.05))

	# Poussières lentes et déterministes.
	for index in range(24):
		var base_x := fmod(float(index * 97 + 31), size.x)
		var travel := fmod(_time * (4.0 + float(index % 5)) + float(index * 73), size.y + 80.0)
		var y := size.y + 30.0 - travel
		var x := base_x + sin(_time * 0.32 + index) * 14.0
		var alpha := 0.08 + float(index % 4) * 0.025
		var radius := 0.8 + float(index % 3) * 0.55
		draw_circle(Vector2(x, y), radius, Color(0.69, 0.64, 1.0, alpha))

	var ring_center := Vector2(size.x * 0.5, size.y * 0.31)
	for ring in range(3):
		draw_arc(ring_center, 105.0 + ring * 32.0, _time * 0.035 + ring, _time * 0.035 + ring + 3.6, 44, Color(0.52, 0.41, 1.0, 0.035), 1.4)

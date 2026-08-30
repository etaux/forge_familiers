class_name UIKit
extends RefCounted
## Design system V6 partagé par les pages et les overlays.

const COLOR_BG := Color("060918")
const COLOR_PANEL := Color("0d1530")
const COLOR_PANEL_SOFT := Color("162044")
const COLOR_TEXT := Color("f7f9ff")
const COLOR_MUTED := Color("aab4cc")
const COLOR_ACCENT := Color("8d70ff")
const COLOR_ACCENT_LIGHT := Color("d2c4ff")
const COLOR_CYAN := Color("62e4ff")
const COLOR_GOLD := Color("ffd36a")
const COLOR_GREEN := Color("76e5ac")
const PAGE_ACCENTS := {
	"farm": Color("62e4ff"),
	"collection": Color("6fa8ff"),
	"albums": Color("ffd36a"),
	"fusion": Color("b983ff"),
	"market": Color("ffb563")
}

var font_regular: Font
var font_semibold: Font
var font_bold: Font
var font_extrabold: Font

func _init() -> void:
	font_regular = AppFonts.make(500.0)
	font_semibold = AppFonts.make(650.0)
	font_bold = AppFonts.make(750.0)
	font_extrabold = AppFonts.make(900.0)

func make_theme() -> Theme:
	var app_theme := Theme.new()
	app_theme.default_font = font_regular
	app_theme.default_font_size = 14
	app_theme.set_font(&"font", &"Label", font_regular)
	app_theme.set_font(&"font", &"Button", font_bold)
	app_theme.set_font(&"font", &"LineEdit", font_semibold)
	app_theme.set_font(&"font", &"OptionButton", font_bold)
	app_theme.set_font(&"font", &"SpinBox", font_semibold)
	app_theme.set_font_size(&"font_size", &"Button", 14)
	app_theme.set_font_size(&"font_size", &"LineEdit", 14)
	app_theme.set_font_size(&"font_size", &"OptionButton", 14)
	app_theme.set_font_size(&"font_size", &"SpinBox", 14)
	app_theme.set_color(&"font_color", &"LineEdit", COLOR_TEXT)
	app_theme.set_color(&"font_placeholder_color", &"LineEdit", Color(COLOR_MUTED, 0.72))
	var scroll_track := box(Color(0.035, 0.045, 0.095, 0.60), 7)
	var scroll_grabber := box(Color(0.35, 0.31, 0.62, 0.78), 7)
	var scroll_hover := box(Color(0.48, 0.41, 0.82, 0.95), 7)
	for scroll_type in [&"VScrollBar", &"HScrollBar"]:
		app_theme.set_stylebox(&"scroll", scroll_type, scroll_track)
		app_theme.set_stylebox(&"scroll_focus", scroll_type, scroll_track)
		app_theme.set_stylebox(&"grabber", scroll_type, scroll_grabber)
		app_theme.set_stylebox(&"grabber_highlight", scroll_type, scroll_hover)
		app_theme.set_stylebox(&"grabber_pressed", scroll_type, scroll_hover)
	app_theme.set_stylebox(&"background", &"ProgressBar", box(Color(0.035, 0.05, 0.11, 0.95), 7, Color(0.22, 0.26, 0.43, 0.7), 1))
	app_theme.set_stylebox(&"fill", &"ProgressBar", box(Color(0.38, 0.72, 0.94, 0.95), 7))
	return app_theme

func box(background: Color, radius: int, border: Color = Color.TRANSPARENT, border_width: int = 0, content_margin: int = 0) -> StyleBoxFlat:
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
	if content_margin > 0:
		style.content_margin_left = content_margin
		style.content_margin_right = content_margin
		style.content_margin_top = content_margin
		style.content_margin_bottom = content_margin
	return style

func label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", AppFonts.readable_size(font_size))
	if font_size >= 20:
		node.add_theme_font_override("font", font_extrabold)
	elif font_size >= 14:
		node.add_theme_font_override("font", font_bold)
	elif font_size >= 10:
		node.add_theme_font_override("font", font_semibold)
	else:
		node.add_theme_font_override("font", font_regular)
	node.add_theme_color_override("font_color", color)
	node.horizontal_alignment = alignment
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return node

func set_margins(container: MarginContainer, left: int, right: int, top: int, bottom: int) -> void:
	container.add_theme_constant_override("margin_left", left)
	container.add_theme_constant_override("margin_right", right)
	container.add_theme_constant_override("margin_top", top)
	container.add_theme_constant_override("margin_bottom", bottom)

func chip(text: String, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var chip_style := box(Color(accent.darkened(0.68), 0.88), 14, Color(accent, 0.62), 1, 0)
	chip_style.content_margin_left = 11
	chip_style.content_margin_right = 11
	chip_style.content_margin_top = 5
	chip_style.content_margin_bottom = 5
	panel.add_theme_stylebox_override("panel", chip_style)
	var value_label := label(text, 10, accent, HORIZONTAL_ALIGNMENT_CENTER)
	panel.add_child(value_label)
	panel.set_meta("value_label", value_label)
	return panel

func stat_chip(title: String, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(112, 60)
	var stat_style := box(Color(0.075, 0.10, 0.205, 0.98), 19, Color(accent, 0.58), 1, 10)
	stat_style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	stat_style.shadow_size = 5
	stat_style.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", stat_style)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", -3)
	panel.add_child(content)
	content.add_child(label(title, 10, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var value_label := label("0", 18, accent, HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(value_label)
	panel.set_meta("value_label", value_label)
	return panel

func style_action_button(button: Button, accent: Color, filled: bool) -> void:
	var background := Color(accent.darkened(0.54), 0.98) if filled else Color(0.055, 0.085, 0.165, 0.98)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", font_bold)
	button.add_theme_font_size_override("font_size", maxi(12, button.get_theme_font_size("font_size")))
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.56, 0.60, 0.72, 0.72))
	var normal := box(background, 18, Color(accent, 0.86), 2, 9)
	normal.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
	normal.shadow_size = 5
	normal.shadow_offset = Vector2(0, 3)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", box(background.lightened(0.10), 18, accent.lightened(0.18), 2, 9))
	button.add_theme_stylebox_override("pressed", box(background.darkened(0.10), 18, accent, 2, 9))
	button.add_theme_stylebox_override("focus", box(Color.TRANSPARENT, 18, Color(accent, 0.95), 3, 8))
	button.add_theme_stylebox_override("disabled", box(Color(0.055, 0.065, 0.115, 0.80), 18, Color(0.28, 0.30, 0.40, 0.70), 1, 9))

func style_line_edit(input: LineEdit, accent: Color) -> void:
	input.add_theme_font_override("font", font_semibold)
	input.add_theme_font_size_override("font_size", 14)
	input.add_theme_color_override("font_color", COLOR_TEXT)
	input.add_theme_color_override("font_placeholder_color", Color(COLOR_MUTED, 0.70))
	input.add_theme_color_override("caret_color", accent)
	input.add_theme_stylebox_override("normal", box(Color(0.055, 0.075, 0.15, 0.98), 16, Color(0.32, 0.38, 0.58, 0.68), 1, 12))
	input.add_theme_stylebox_override("focus", box(Color(0.065, 0.085, 0.175, 1.0), 16, accent, 2, 11))
	input.add_theme_stylebox_override("read_only", box(Color(0.045, 0.055, 0.11, 0.9), 16, Color(0.22, 0.25, 0.35, 0.7), 1, 12))

func style_option_button(button: OptionButton, accent: Color) -> void:
	button.add_theme_font_override("font", font_bold)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", box(Color(0.065, 0.085, 0.17, 0.98), 16, Color(accent, 0.62), 1, 10))
	button.add_theme_stylebox_override("hover", box(Color(0.085, 0.105, 0.205, 1.0), 16, accent, 2, 9))
	button.add_theme_stylebox_override("pressed", box(Color(0.05, 0.065, 0.14, 1.0), 16, accent, 2, 9))
	button.add_theme_stylebox_override("focus", box(Color.TRANSPARENT, 16, accent, 2, 9))

func style_spin_box(spin: SpinBox, accent: Color) -> void:
	var input := spin.get_line_edit()
	input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	style_line_edit(input, accent)

func mini_art(path: String, color: Color, size := Vector2(70, 84)) -> PanelContainer:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = size
	frame.add_theme_stylebox_override("panel", box(Color(0.02, 0.025, 0.07, 1.0), 13, color, 2, 4))
	var art := TextureRect.new()
	art.texture = load(path)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(art)
	return frame

func overlay_panel(min_width: float, min_height: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(min_width, min_height)
	var overlay_style := box(Color(0.055, 0.072, 0.155, 1.0), 30, Color(0.58, 0.48, 0.98, 0.68), 2, 20)
	overlay_style.shadow_color = Color(0.0, 0.0, 0.0, 0.58)
	overlay_style.shadow_size = 14
	overlay_style.shadow_offset = Vector2(0, 7)
	panel.add_theme_stylebox_override("panel", overlay_style)
	return panel

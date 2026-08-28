class_name AppFonts
extends RefCounted
## Typographie centralisée : Nunito variable, lisible sur écran mobile.

const SOURCE: FontFile = preload("res://assets/fonts/Nunito-Variable.ttf")

static func make(weight: float = 500.0) -> FontVariation:
	var font := FontVariation.new()
	font.base_font = SOURCE
	font.variation_opentype = {&"wght": weight}
	return font

static func readable_size(requested: int) -> int:
	if requested <= 8:
		return 11
	if requested == 9:
		return 12
	if requested == 10:
		return 12
	if requested == 11:
		return 13
	if requested == 12:
		return 14
	if requested == 13:
		return 15
	if requested == 14:
		return 16
	if requested >= 20:
		return requested + 2
	return requested

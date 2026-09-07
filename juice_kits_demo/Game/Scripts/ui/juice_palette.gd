# The colours and the font. Change these and the whole kit changes with them.
class_name JuicePalette
extends RefCounted


const INK := Color("101426")
const CREAM := Color("f5efdc")
const GOLD := Color("ffc233")
const PINK := Color("ff4f8b")
const CYAN := Color("4fd6ff")
const MINT := Color("6ee7a0")
const RED := Color("ff5c5c")

const NIGHT_HIGH := Color("070a18")
const NIGHT_MID := Color("141a35")
const NIGHT_LOW := Color("2b2a5c")

const FONT_PATH := "res://Game/Assets/fonts/Bungee-Regular.ttf"

static var _font: Font


static func font() -> Font:
	if _font != null:
		return _font
	if ResourceLoader.exists(FONT_PATH):
		var loaded := load(FONT_PATH)
		if loaded is Font:
			_font = loaded
			return _font
	_font = ThemeDB.fallback_font
	return _font


static func clear_cache() -> void:
	_font = null


static func accent(index: int) -> Color:
	var wheel := [GOLD, CYAN, PINK, MINT, RED]
	return wheel[posmod(index, wheel.size())]

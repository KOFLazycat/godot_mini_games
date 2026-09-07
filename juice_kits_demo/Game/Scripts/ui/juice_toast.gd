# One notification plate. Pops in, rattles, holds, slides out, frees itself.
# It sizes itself from its own text in _draw rather than letting a container do
# it, because the plate is skewed and a container would lay out the bounding box
# instead of the shape.
@tool
class_name JuiceToast
extends Control


signal finished

@export var message: String = "TOAST":
	set(value):
		message = value
		queue_redraw()

@export var font: Font
@export var font_size: int = 22
@export var plate: Color = JuicePalette.PINK
@export var label_color: Color = JuicePalette.CREAM
@export var shadow_color: Color = JuicePalette.INK
@export var icon: Texture2D
@export var skew: float = 14.0
@export var hold: float = 1.4
@export var padding: Vector2 = Vector2(22.0, 12.0)

var amount: float = 0.0:
	set(value):
		amount = value
		queue_redraw()

var shake: float = 0.0:
	set(value):
		shake = value
		queue_redraw()

var _time: float = 0.0
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if shake > 0.001:
		_time += delta
		queue_redraw()


func play() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()

	amount = 0.0
	shake = 1.0

	_tween = create_tween()
	_tween.tween_property(self, ^"amount", 1.0, 0.24) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, ^"shake", 0.0, 0.5)
	_tween.tween_interval(hold)
	_tween.tween_property(self, ^"amount", 0.0, 0.26) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween.tween_callback(func() -> void: finished.emit())


func measured_width() -> float:
	var use_font := font if font != null else JuicePalette.font()
	if use_font == null:
		return 0.0
	var text_width := use_font.get_string_size(
		message, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var icon_width := (font_size + 10.0) if icon != null else 0.0
	return text_width + icon_width + padding.x * 2.0


func _draw() -> void:
	var use_font := font if font != null else JuicePalette.font()
	if use_font == null or amount <= 0.001 or message.is_empty():
		return

	var measured := use_font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var icon_width := (font_size + 10.0) if icon != null else 0.0
	var box := Vector2(measured.x + icon_width, measured.y) + padding * 2.0

	var slide := (1.0 - amount) * 90.0
	var centre := Vector2(box.x * 0.5 + slide, size.y * 0.5)
	if shake > 0.001:
		centre += Vector2(sin(_time * 88.0), cos(_time * 71.0)) * shake * 6.0

	var grow := 0.86 + 0.14 * amount

	var shape := PackedVector2Array([
		Vector2(skew, 0.0),
		Vector2(box.x, 0.0),
		Vector2(box.x - skew, box.y),
		Vector2(0.0, box.y),
	])
	for i in shape.size():
		shape[i] = centre + (shape[i] - box * 0.5) * grow

	var shade := shadow_color
	shade.a *= amount * 0.85
	var shadow := PackedVector2Array(shape)
	for i in shadow.size():
		shadow[i] += Vector2(5.0, 5.0)
	draw_colored_polygon(shadow, shade)

	var fill := plate
	fill.a *= amount
	draw_colored_polygon(shape, fill)

	var text_left := centre.x - box.x * 0.5 * grow + padding.x

	if icon != null:
		var icon_size := float(font_size)
		var tint := label_color
		tint.a *= amount
		draw_texture_rect(
			icon,
			Rect2(Vector2(text_left, centre.y - icon_size * 0.5), Vector2(icon_size, icon_size)),
			false, tint
		)
		text_left += icon_size + 10.0

	var ink := label_color
	ink.a *= amount
	var baseline := centre.y + (use_font.get_ascent(font_size) - use_font.get_descent(font_size)) * 0.5
	draw_string(use_font, Vector2(text_left, baseline), message,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)

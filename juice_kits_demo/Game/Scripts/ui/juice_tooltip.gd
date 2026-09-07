# A little floating plate that pops up when you hover something.
# Drawn the same way as the toasts, and it bobs gently while it is open so it
# does not look like a static box that appeared.
# One instance is enough for a whole screen, just call show_for() with a
# different anchor each time.
@tool
class_name JuiceTooltip
extends Control

@export var font: Font
@export var font_size: int = 15
@export var plate: Color = JuicePalette.INK
@export var text_color: Color = JuicePalette.CREAM
@export var edge_color: Color = JuicePalette.GOLD
@export var skew: float = 8.0
@export var padding: Vector2 = Vector2(16.0, 9.0)
@export var float_height: float = 6.0

var message: String = ""

var amount: float = 0.0:
	set(value):
		amount = value
		queue_redraw()

var _time: float = 0.0
var _anchor: Vector2 = Vector2.ZERO
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 200


func _process(delta: float) -> void:
	if amount > 0.001:
		_time += delta
		queue_redraw()


# Pops the tip up centred above anchor_rect. Pass the hovered control's rect.
func show_for(text: String, anchor_rect: Rect2) -> void:
	message = text
	_anchor = Vector2(anchor_rect.get_center().x, anchor_rect.position.y)
	_time = 0.0

	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, ^"amount", 1.0, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func hide_tip() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, ^"amount", 0.0, 0.14) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _draw() -> void:
	var use_font := font if font != null else JuicePalette.font()
	if use_font == null or amount <= 0.001 or message.is_empty():
		return

	var measured := use_font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var box := measured + padding * 2.0

	# Rises into place as it fades in, then keeps bobbing.
	var rise := (1.0 - amount) * 14.0
	var bob := sin(_time * 2.6) * float_height * 0.5
	var centre := _anchor + Vector2(0.0, -box.y * 0.5 - 18.0 + rise + bob)

	# Nudge back on screen if the anchor sits near an edge.
	var half := box.x * 0.5
	centre.x = clampf(centre.x, half + 8.0, maxf(size.x - half - 8.0, half + 8.0))

	var grow := 0.9 + 0.1 * amount
	var shape := PackedVector2Array([
		Vector2(skew, 0.0),
		Vector2(box.x, 0.0),
		Vector2(box.x - skew, box.y),
		Vector2(0.0, box.y),
	])
	for i in shape.size():
		shape[i] = centre + (shape[i] - box * 0.5) * grow

	var fill := plate
	fill.a *= amount * 0.95
	draw_colored_polygon(shape, fill)

	var outline := PackedVector2Array(shape)
	outline.append(shape[0])
	var edge := edge_color
	edge.a *= amount
	draw_polyline(outline, edge, 2.0)

	var ink := text_color
	ink.a *= amount
	var baseline := centre.y + (use_font.get_ascent(font_size) - use_font.get_descent(font_size)) * 0.5
	draw_string(use_font, Vector2(centre.x - measured.x * 0.5, baseline), message,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)

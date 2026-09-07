# A number that counts up instead of snapping. Both the roll time and the punch
# scale with how big the change was, so +5 and +5000 do not look the same.
@tool
class_name JuiceCounter
extends Control


signal reached(value: float)

# Backing field. value's setter calls set_value(), so set_value() must never
# assign to value or it recurses until the stack blows.
var _value: float = 0.0

@export var value: float = 0.0:
	set(new_value):
		set_value(new_value)
	get:
		return _value

@export var prefix: String = ""
@export var suffix: String = ""
@export var whole_numbers: bool = true
@export var decimals: int = 1
@export var group_digits: bool = true

@export_group("Style")
@export var font: Font
@export var font_size: int = 44
@export var color: Color = JuicePalette.CREAM
@export var gain_color: Color = JuicePalette.MINT
@export var loss_color: Color = JuicePalette.RED
@export var shadow_color: Color = JuicePalette.INK
@export var shadow_offset: Vector2 = Vector2(4.0, 4.0)
@export var alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT

@export_group("Animation")
@export var roll_time: float = 0.55
@export var min_roll_time: float = 0.12
@export var max_roll_time: float = 1.1
@export var punch: float = 0.22

var _displayed: float = 0.0:
	set(new_value):
		_displayed = new_value
		queue_redraw()

var _scale: float = 1.0:
	set(new_value):
		_scale = new_value
		queue_redraw()

var _tint: Color = Color.WHITE:
	set(new_value):
		_tint = new_value
		queue_redraw()

var _roll_tween: Tween
var _punch_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_displayed = _value
	_tint = color


func set_value(new_value: float, immediate: bool = false) -> void:
	var previous := _value
	_value = new_value

	if not is_inside_tree() or immediate or is_equal_approx(previous, new_value):
		_displayed = new_value
		return

	if _roll_tween != null and _roll_tween.is_valid():
		_roll_tween.kill()

	var magnitude := absf(new_value - previous)
	var reference := maxf(absf(previous), 1.0)
	var duration := clampf(
		roll_time * clampf(magnitude / reference, 0.15, 2.0),
		min_roll_time, max_roll_time
	)

	_roll_tween = create_tween()
	_roll_tween.tween_property(self, ^"_displayed", new_value, duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_roll_tween.tween_callback(func() -> void: reached.emit(new_value))

	_react(new_value > previous)


func _react(is_gain: bool) -> void:
	if _punch_tween != null and _punch_tween.is_valid():
		_punch_tween.kill()

	_scale = 1.0 + punch
	_tint = gain_color if is_gain else loss_color

	_punch_tween = create_tween().set_parallel(true)
	_punch_tween.tween_property(self, ^"_scale", 1.0, 0.4) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	# Colour comes back faster than the scale so the flash punctuates instead of
	# leaving the number permanently tinted.
	_punch_tween.tween_property(self, ^"_tint", color, 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func formatted() -> String:
	var body: String
	if whole_numbers:
		body = str(int(round(_displayed)))
	else:
		body = String.num(_displayed, decimals)

	if group_digits and whole_numbers:
		body = _group(body)
	return prefix + body + suffix


func _group(digits: String) -> String:
	var negative := digits.begins_with("-")
	if negative:
		digits = digits.substr(1)

	var out := ""
	var count := 0
	for i in range(digits.length() - 1, -1, -1):
		out = digits[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if negative else "") + out


func _draw() -> void:
	var use_font := font if font != null else JuicePalette.font()
	if use_font == null:
		return

	var text := formatted()
	var measured := use_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)

	var anchor_x := 0.0
	match alignment:
		HORIZONTAL_ALIGNMENT_CENTER:
			anchor_x = (size.x - measured.x) * 0.5
		HORIZONTAL_ALIGNMENT_RIGHT:
			anchor_x = size.x - measured.x
		_:
			anchor_x = 0.0

	var baseline := size.y * 0.5 \
		+ (use_font.get_ascent(font_size) - use_font.get_descent(font_size)) * 0.5
	var origin := Vector2(anchor_x, baseline)

	var pivot := Vector2(anchor_x + measured.x * 0.5, size.y * 0.5)
	var draw_transform := Transform2D(0.0, Vector2(_scale, _scale), 0.0, pivot - pivot * _scale)

	draw_set_transform_matrix(draw_transform)
	draw_string(use_font, origin + shadow_offset, text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, shadow_color)
	draw_string(use_font, origin, text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, _tint)
	draw_set_transform_matrix(Transform2D.IDENTITY)

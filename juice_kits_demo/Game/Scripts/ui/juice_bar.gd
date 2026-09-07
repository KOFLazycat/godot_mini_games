# Progress bar with a ghost fill that lags behind a loss. That trailing band is
# the whole point, it shows you how much you just took while you can still react
# to it.
@tool
class_name JuiceBar
extends Control


signal emptied
signal filled

# Backing field. Same recursion trap as JuiceCounter.
var _value: float = 1.0

@export_range(0.0, 1.0, 0.001) var value: float = 1.0:
	set(new_value):
		set_value(new_value)
	get:
		return _value

@export_group("Style")
@export var fill_color: Color = JuicePalette.MINT
@export var ghost_color: Color = JuicePalette.RED
@export var gain_color: Color = JuicePalette.CREAM
@export var track_color: Color = Color("1b2036")
@export var border_color: Color = JuicePalette.INK
@export var skew: float = 10.0
@export var border_width: float = 3.0
@export_range(0, 40, 1) var segments: int = 0

@export_group("Animation")
@export var fill_time: float = 0.16
@export var ghost_time: float = 0.45
@export var ghost_delay: float = 0.25
@export var shake_on_loss: bool = true

var _fill: float = 1.0:
	set(new_value):
		_fill = new_value
		queue_redraw()

var _ghost: float = 1.0:
	set(new_value):
		_ghost = new_value
		queue_redraw()

var _flash: float = 0.0:
	set(new_value):
		_flash = new_value
		queue_redraw()

var _shake: float = 0.0:
	set(new_value):
		_shake = new_value
		queue_redraw()

var _time: float = 0.0
var _fill_tween: Tween
var _ghost_tween: Tween
var _flash_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill = _value
	_ghost = _value


func _process(delta: float) -> void:
	if _shake > 0.001:
		_time += delta
		queue_redraw()


func set_value(new_value: float, immediate: bool = false) -> void:
	var previous := _value
	_value = clampf(new_value, 0.0, 1.0)

	if not is_inside_tree() or immediate:
		_fill = _value
		_ghost = _value
		queue_redraw()
		return

	if is_equal_approx(previous, _value):
		return

	if _fill_tween != null and _fill_tween.is_valid():
		_fill_tween.kill()
	if _ghost_tween != null and _ghost_tween.is_valid():
		_ghost_tween.kill()

	_fill_tween = create_tween()
	_fill_tween.tween_property(self, ^"_fill", _value, fill_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# On a loss the ghost holds where it was, waits, then drains. On a gain it
	# leads so the new stretch flashes bright as it fills.
	if _value < previous:
		_ghost_tween = create_tween()
		_ghost_tween.tween_interval(ghost_delay)
		_ghost_tween.tween_property(self, ^"_ghost", _value, ghost_time) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		if shake_on_loss:
			_rattle(clampf((previous - _value) * 3.0, 0.2, 1.0))
	else:
		_ghost = _value
		_pulse()

	if _value <= 0.001:
		emptied.emit()
	elif _value >= 0.999:
		filled.emit()


func _rattle(strength: float) -> void:
	_shake = strength
	var tween := create_tween()
	tween.tween_property(self, ^"_shake", 0.0, 0.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _pulse() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash = 1.0
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, ^"_flash", 0.0, 0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _slice(amount: float, offset: Vector2) -> PackedVector2Array:
	var width := size.x * clampf(amount, 0.0, 1.0)
	return PackedVector2Array([
		Vector2(skew, 0.0) + offset,
		Vector2(width + skew, 0.0) + offset,
		Vector2(width, size.y) + offset,
		Vector2(0.0, size.y) + offset,
	])


func _draw() -> void:
	var offset := Vector2.ZERO
	if _shake > 0.001:
		offset = Vector2(sin(_time * 96.0), cos(_time * 77.0)) * _shake * 5.0

	draw_colored_polygon(_slice(1.0, offset), track_color)

	if _ghost > _fill + 0.001:
		draw_colored_polygon(_slice(_ghost, offset), ghost_color)

	if _fill > 0.001:
		var fill := fill_color
		if _flash > 0.001:
			fill = fill.lerp(gain_color, _flash)
		draw_colored_polygon(_slice(_fill, offset), fill)

	if segments > 1:
		var notch := border_color
		notch.a *= 0.85
		for i in range(1, segments):
			var x := size.x * float(i) / float(segments)
			draw_line(
				Vector2(x + skew, 0.0) + offset,
				Vector2(x, size.y) + offset,
				notch, border_width * 0.7
			)

	if border_width > 0.0:
		var frame := _slice(1.0, offset)
		frame.append(frame[0])
		draw_polyline(frame, border_color, border_width)

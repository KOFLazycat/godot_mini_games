# The button. A skewed plate with an offset shadow, drawn in _draw, no StyleBox
# anywhere.
# Four animation channels, each with its own tween so they can overlap without
# fighting: select (hover), press, intro (entrance) and shake (what you get when
# you press a disabled one).
@tool
class_name JuiceButton
extends Control


enum IntroStyle {
	SLIDE,
	DROP,
	RISE,
	POP,
	FLIP,
	FADE,
}

signal pressed
signal hovered

@export var text: String = "BUTTON":
	set(value):
		text = value
		queue_redraw()

@export var disabled: bool = false:
	set(value):
		disabled = value
		queue_redraw()

@export var font: Font
@export var font_size: int = 30

@export_group("Transition")
@export var intro_style: IntroStyle = IntroStyle.SLIDE
@export var vertical_travel: float = 240.0

@export_group("Shape")
@export var skew: float = 20.0
@export var shadow_offset: Vector2 = Vector2(7.0, 7.0)
@export var select_slide: float = 24.0
@export var select_grow: float = 0.07
@export var press_squash: float = 0.1
@export var intro_travel: float = 520.0
@export var exit_travel: float = 620.0

@export_group("Colors")
@export var fill_idle: Color = JuicePalette.CREAM
@export var fill_selected: Color = JuicePalette.GOLD
@export var fill_disabled: Color = Color("5b5f73")
@export var text_color: Color = JuicePalette.INK
@export var shadow_color: Color = JuicePalette.INK

@export_group("Juice")
@export var juicy_press: bool = true
@export var hover_sound: StringName = &"click"
@export var press_sound: StringName = &"confirm"
@export var blocked_sound: StringName = &"error"

var selected: bool = false

var select_amount: float = 0.0:
	set(value):
		select_amount = value
		queue_redraw()

var press_amount: float = 0.0:
	set(value):
		press_amount = value
		queue_redraw()

var intro_amount: float = 1.0:
	set(value):
		intro_amount = value
		queue_redraw()

var shake_amount: float = 0.0:
	set(value):
		shake_amount = value
		queue_redraw()

var _select_tween: Tween
var _press_tween: Tween
var _intro_tween: Tween
var _shake_tween: Tween
var _from_side: float = -1.0
var _travel: float = 520.0
var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size.y = maxf(custom_minimum_size.y, font_size * 2.0)
	if not Engine.is_editor_hint():
		mouse_entered.connect(_on_mouse_entered)
		focus_entered.connect(func() -> void: set_selected(true))
		focus_exited.connect(func() -> void: set_selected(false))


func _process(delta: float) -> void:
	if shake_amount > 0.001:
		_time += delta
		queue_redraw()


func set_selected(value: bool) -> void:
	if selected == value:
		return
	selected = value

	if value and is_inside_tree() and intro_amount > 0.5 and not disabled:
		Juice.play_sfx(hover_sound, null, -10.0)

	if _select_tween != null and _select_tween.is_valid():
		_select_tween.kill()
	_select_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_select_tween.tween_property(self, ^"select_amount", 1.0 if value else 0.0, 0.22)


func press() -> void:
	if disabled:
		_refuse()
		return

	if _press_tween != null and _press_tween.is_valid():
		_press_tween.kill()
	_press_tween = create_tween()
	_press_tween.tween_property(self, ^"press_amount", 1.0, 0.06)
	_press_tween.tween_property(self, ^"press_amount", 0.0, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	Juice.play_sfx(press_sound, null, -4.0)

	if juicy_press:
		Juice.shake(0.1)
		Juice.hitstop(0.03)

	pressed.emit()


func _refuse() -> void:
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	shake_amount = 1.0
	_shake_tween = create_tween()
	_shake_tween.tween_property(self, ^"shake_amount", 0.0, 0.45) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	Juice.play_sfx(blocked_sound, null, -6.0)


func play_intro(delay: float = 0.0, from_left: bool = true) -> void:
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()

	_from_side = -1.0 if from_left else 1.0
	_travel = intro_travel
	intro_amount = 0.0

	_intro_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_intro_tween.tween_interval(delay)
	_intro_tween.tween_property(self, ^"intro_amount", 1.0, 0.45)


func play_outro(delay: float = 0.0, to_left: bool = false) -> float:
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()

	_from_side = -1.0 if to_left else 1.0
	_travel = exit_travel

	_intro_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_intro_tween.tween_interval(delay)
	_intro_tween.tween_property(self, ^"intro_amount", 0.0, 0.3)
	return delay + 0.3


func _on_mouse_entered() -> void:
	hovered.emit()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT and button.pressed:
			hovered.emit()
			press()
			accept_event()
	elif event.is_action_pressed(&"ui_accept"):
		press()
		accept_event()


func _draw() -> void:
	var use_font := font if font != null else JuicePalette.font()
	if use_font == null or intro_amount <= 0.001:
		return

	var box := size
	var centre := box * 0.5
	var grow := 1.0 + select_amount * select_grow - press_amount * press_squash
	var slide := select_amount * select_slide

	if shake_amount > 0.001:
		slide += sin(_time * 74.0) * shake_amount * 9.0
		slide += sin(_time * 131.0) * shake_amount * 4.0

	var entry := _entry_transform()
	var alpha: float = entry["alpha"]
	var offset: Vector2 = entry["offset"] + Vector2(slide, 0.0)
	var scale: Vector2 = entry["scale"] * grow

	var shape := PackedVector2Array([
		Vector2(skew, 0.0),
		Vector2(box.x, 0.0),
		Vector2(box.x - skew, box.y),
		Vector2(0.0, box.y),
	])
	for i in shape.size():
		shape[i] = centre + (shape[i] - centre) * scale + offset

	var shadow := PackedVector2Array(shape)
	for i in shadow.size():
		shadow[i] += shadow_offset * (1.0 - press_amount * 0.75)

	var shade := shadow_color
	shade.a *= alpha * 0.9
	draw_colored_polygon(shadow, shade)

	var fill := fill_disabled if disabled else fill_idle.lerp(fill_selected, select_amount)
	fill.a *= alpha
	draw_colored_polygon(shape, fill)

	var ink := text_color
	ink.a *= alpha * (0.5 if disabled else 1.0)
	var measured := use_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := centre.y + (use_font.get_ascent(font_size) - use_font.get_descent(font_size)) * 0.5

	draw_set_transform_matrix(
		Transform2D(0.0, scale, 0.0, centre - centre * scale + offset))
	draw_string(
		use_font, Vector2(centre.x - measured.x * 0.5, baseline),
		text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink
	)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _entry_transform() -> Dictionary:
	var away := 1.0 - intro_amount
	var alpha := clampf(intro_amount, 0.0, 1.0)
	var offset := Vector2.ZERO
	var scale := Vector2.ONE

	# Scales get floored at 0 below. intro_amount overshoots past 1 and dips under
	# 0 because of the BACK ease, and a negative scale mirrors the polygon.
	match intro_style:
		IntroStyle.SLIDE:
			offset.x = away * _travel * _from_side
		IntroStyle.DROP:
			offset.y = -away * vertical_travel
		IntroStyle.RISE:
			offset.y = away * vertical_travel
		IntroStyle.POP:
			scale = Vector2.ONE * maxf(intro_amount, 0.0)
		IntroStyle.FLIP:
			scale.x = maxf(intro_amount, 0.0)
		IntroStyle.FADE:
			offset.y = away * 12.0

	return {"offset": offset, "scale": scale, "alpha": alpha}

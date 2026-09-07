# Floating combat text. The labels are pooled because a busy fight throws a lot
# of these, and allocating a Label plus a Tween per hit stutters on exactly the
# frames you care about.
class_name DamageNumbers
extends Node2D


const _POOL_LIMIT := 64
const _GRAVITY := 420.0

var _config: JuiceConfig
var _pool: Array[Label] = []


func setup(config: JuiceConfig) -> void:
	_config = config


func spawn(
	world_position: Vector2,
	text: String,
	crit: bool = false,
	color_override: Variant = null
) -> Label:
	if _config == null:
		return null

	var label := _acquire()
	label.text = text

	var font_size := 32 if crit else 22
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_constant_override(&"outline_size", 8 if crit else 6)
	label.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.85))

	var color: Color
	if color_override is Color:
		color = color_override
	else:
		color = _config.damage_number_crit_color if crit else _config.damage_number_color
	label.add_theme_color_override(&"font_color", color)

	label.reset_size()
	label.pivot_offset = label.size * 0.5
	var start := world_position - label.size * 0.5

	label.position = start
	label.scale = Vector2.ONE * (0.4 if crit else 0.6)
	label.modulate = Color(1, 1, 1, 1)
	label.visible = true

	_animate(label, start, crit)
	return label


func clear() -> void:
	for child in get_children():
		if child is Label:
			_release(child)


func _animate(label: Label, start: Vector2, crit: bool) -> void:
	var lifetime: float = _config.damage_number_lifetime * (1.25 if crit else 1.0)
	var rise: float = _config.damage_number_rise * (1.3 if crit else 1.0)
	var drift := randf_range(-_config.damage_number_spread, _config.damage_number_spread)

	var tween := label.create_tween()
	tween.set_parallel(true)

	var travel := func(t: float) -> void:
		if not is_instance_valid(label):
			return
		var elapsed := t * lifetime
		label.position = start + Vector2(
			drift * t,
			-rise * elapsed + 0.5 * _GRAVITY * elapsed * elapsed
		)
	tween.tween_method(travel, 0.0, 1.0, lifetime)

	tween.tween_property(label, ^"scale", Vector2.ONE * (1.35 if crit else 1.1), lifetime * 0.16) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(label, ^"scale", Vector2.ONE, lifetime * 0.2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.set_parallel(false)
	# Held opaque for most of its life and only faded at the end. Fading from the
	# start makes the number unreadable while it still matters.
	tween.tween_interval(lifetime * 0.3)
	tween.tween_property(label, ^"modulate:a", 0.0, lifetime * 0.34)
	tween.tween_callback(_release.bind(label))


func _acquire() -> Label:
	while not _pool.is_empty():
		var pooled: Label = _pool.pop_back()
		if is_instance_valid(pooled):
			return pooled

	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 100
	add_child(label)
	return label


func _release(label: Label) -> void:
	if not is_instance_valid(label):
		return
	label.visible = false
	if _pool.size() < _POOL_LIMIT:
		if label not in _pool:
			_pool.append(label)
	else:
		label.queue_free()

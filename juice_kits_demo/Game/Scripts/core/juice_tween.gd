# Punch, squash, pop in and out. Static helpers, call them on any CanvasItem.
# They record the node's resting scale the first time they touch it and always
# return there, so spamming punches can never leave something stuck at the wrong
# size.
class_name JuiceTween
extends RefCounted


const _META_REST_SCALE := &"_juice_rest_scale"
const _META_REST_ROTATION := &"_juice_rest_rotation"
const _META_REST_POSITION := &"_juice_rest_position"
const _META_REST_MODULATE := &"_juice_rest_modulate"


static func punch_scale(node: CanvasItem, amount: float = 0.25, duration: float = 0.32) -> Tween:
	if not _can_juice(node):
		return null
	var rest := _rest_scale(node)
	_kill(node, &"scale")

	var tween := node.create_tween()
	node.set_meta(&"_juice_tween_scale", tween)
	# Fast out, slow settle. An even in and out reads as a wobble, not an impact.
	tween.tween_property(node, ^"scale", rest * (1.0 + amount), duration * 0.22) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, ^"scale", rest, duration * 0.78) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return tween


static func squash_stretch(
	node: CanvasItem,
	amount: float = 0.3,
	duration: float = 0.36,
	axis: Vector2 = Vector2.RIGHT
) -> Tween:
	if not _can_juice(node):
		return null
	var rest := _rest_scale(node)
	_kill(node, &"scale")

	var a := absf(axis.normalized().x)
	var stretch := Vector2(
		lerpf(1.0 / (1.0 + amount), 1.0 + amount, a),
		lerpf(1.0 + amount, 1.0 / (1.0 + amount), a)
	)

	var tween := node.create_tween()
	node.set_meta(&"_juice_tween_scale", tween)
	tween.tween_property(node, ^"scale", rest * stretch, duration * 0.2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, ^"scale", rest, duration * 0.8) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return tween


static func pop_in(node: CanvasItem, duration: float = 0.4, from: float = 0.0) -> Tween:
	if not _can_juice(node):
		return null
	var rest := _rest_scale(node)
	_kill(node, &"scale")

	node.scale = rest * from
	var tween := node.create_tween()
	node.set_meta(&"_juice_tween_scale", tween)
	tween.tween_property(node, ^"scale", rest, duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween


static func pop_out(node: CanvasItem, duration: float = 0.25, free_when_done: bool = false) -> Tween:
	if not is_instance_valid(node):
		return null
	_rest_scale(node)
	_kill(node, &"scale")

	var tween := node.create_tween()
	node.set_meta(&"_juice_tween_scale", tween)
	tween.tween_property(node, ^"scale", Vector2.ZERO, duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if free_when_done:
		tween.tween_callback(node.queue_free)
	return tween


static func punch_rotation(node: CanvasItem, angle_degrees: float = 8.0, duration: float = 0.4) -> Tween:
	if not _can_juice(node):
		return null
	var rest: float = _rest(node, _META_REST_ROTATION, node.rotation)
	_kill(node, &"rotation")

	var tween := node.create_tween()
	node.set_meta(&"_juice_tween_rotation", tween)
	tween.tween_property(node, ^"rotation", rest + deg_to_rad(angle_degrees), duration * 0.2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, ^"rotation", rest, duration * 0.8) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return tween


static func shake_position(node: CanvasItem, strength: float = 6.0, duration: float = 0.3) -> Tween:
	if not _can_juice(node):
		return null
	var rest: Vector2 = _rest(node, _META_REST_POSITION, node.position)
	_kill(node, &"position")

	var step := func(t: float) -> void:
		if not is_instance_valid(node):
			return
		var falloff := 1.0 - t
		node.position = rest + Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		) * falloff

	var settle := func() -> void:
		if is_instance_valid(node):
			node.position = rest

	var tween := node.create_tween()
	node.set_meta(&"_juice_tween_position", tween)
	tween.tween_method(step, 0.0, 1.0, duration)
	tween.tween_callback(settle)
	return tween


static func flash_modulate(node: CanvasItem, color: Color = Color.WHITE, duration: float = 0.12) -> Tween:
	if not _can_juice(node):
		return null
	var rest: Color = _rest(node, _META_REST_MODULATE, node.modulate)
	_kill(node, &"modulate")

	var tween := node.create_tween()
	node.set_meta(&"_juice_tween_modulate", tween)
	tween.tween_property(node, ^"modulate", color, duration * 0.3)
	tween.tween_property(node, ^"modulate", rest, duration * 0.7)
	return tween


static func center_pivot(control: Control) -> void:
	if is_instance_valid(control):
		control.pivot_offset = control.size * 0.5


static func restore(node: CanvasItem) -> void:
	if not is_instance_valid(node):
		return
	for key in [&"scale", &"rotation", &"position", &"modulate"]:
		_kill(node, key)
	if node.has_meta(_META_REST_SCALE):
		node.scale = node.get_meta(_META_REST_SCALE)
	if node.has_meta(_META_REST_ROTATION):
		node.rotation = node.get_meta(_META_REST_ROTATION)
	if node.has_meta(_META_REST_POSITION):
		node.position = node.get_meta(_META_REST_POSITION)
	if node.has_meta(_META_REST_MODULATE):
		node.modulate = node.get_meta(_META_REST_MODULATE)


static func _can_juice(node: CanvasItem) -> bool:
	if not is_instance_valid(node) or not node.is_inside_tree():
		return false
	var juice := node.get_node_or_null(^"/root/Juice")
	return juice == null or juice.enabled


static func _rest_scale(node: CanvasItem) -> Vector2:
	return _rest(node, _META_REST_SCALE, node.scale)


static func _rest(node: CanvasItem, meta: StringName, fallback: Variant) -> Variant:
	if not node.has_meta(meta):
		node.set_meta(meta, fallback)
	return node.get_meta(meta)


static func _kill(node: CanvasItem, key: StringName) -> void:
	var meta := StringName("_juice_tween_" + key)
	if not node.has_meta(meta):
		return
	var previous: Tween = node.get_meta(meta)
	if is_instance_valid(previous) and previous.is_valid():
		previous.kill()
	node.remove_meta(meta)

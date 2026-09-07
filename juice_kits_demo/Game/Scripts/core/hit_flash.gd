# Whitens a sprite for a few frames when it gets hit. Cheapest effect in the kit
# for how much it sells an impact.
class_name HitFlash
extends RefCounted


const SHADER_PATH := "res://Game/Assets/shaders/hit_flash.gdshader"
const _META_MATERIAL := &"_juice_flash_material"
const _META_FOREIGN := &"_juice_flash_foreign_material"

static var _shader: Shader


static func flash(
	node: CanvasItem,
	color: Color = Color.WHITE,
	duration: float = 0.09
) -> Tween:
	if not is_instance_valid(node) or not node.is_inside_tree():
		return null

	var material := _ensure_material(node)
	if material == null:
		return JuiceTween.flash_modulate(node, color, duration)

	material.set_shader_parameter(&"flash_color", color)
	material.set_shader_parameter(&"flash_amount", 1.0)

	var tween := node.create_tween()
	tween.tween_interval(duration * 0.34)
	tween.tween_method(
		_set_amount.bind(material),
		1.0, 0.0, duration * 0.66
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tween


static func clear(node: CanvasItem) -> void:
	if not is_instance_valid(node):
		return
	if node.has_meta(_META_MATERIAL):
		node.material = null
		node.remove_meta(_META_MATERIAL)
	node.remove_meta(_META_FOREIGN)


static func clear_cache() -> void:
	_shader = null


static func _set_amount(value: float, material: ShaderMaterial) -> void:
	if is_instance_valid(material):
		material.set_shader_parameter(&"flash_amount", value)


static func _ensure_material(node: CanvasItem) -> ShaderMaterial:
	if node.has_meta(_META_FOREIGN):
		return null
	if node.has_meta(_META_MATERIAL):
		var existing = node.get_meta(_META_MATERIAL)
		if existing is ShaderMaterial and node.material == existing:
			return existing
		node.remove_meta(_META_MATERIAL)

	# Node already has its own material. Fall back rather than overwrite it.
	if node.material != null:
		node.set_meta(_META_FOREIGN, true)
		return null

	if _shader == null:
		if not ResourceLoader.exists(SHADER_PATH):
			push_warning("HitFlash: missing %s" % SHADER_PATH)
			node.set_meta(_META_FOREIGN, true)
			return null
		_shader = load(SHADER_PATH)

	var material := ShaderMaterial.new()
	material.shader = _shader
	node.material = material
	node.set_meta(_META_MATERIAL, material)
	return material

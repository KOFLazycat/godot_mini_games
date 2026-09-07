# The CRT filter and the full screen flashes. The Juice autoload builds this,
# you never place it in a scene.
# Two kinds of value live here. The look (curvature, scanlines, grain) you set
# once and leave. The pulses (aberration, vignette, warp) get tweened per hit and
# add on top of the look.
class_name ScreenFX
extends CanvasLayer


const SHADER_PATH := "res://Game/Assets/shaders/crt.gdshader"
const NOISE_PATH := "res://Game/Assets/textures/noise.png"

enum Look {
	OFF,
	SUBTLE,
	ARCADE,
	HANDHELD,
	BROKEN,
}

signal look_changed(look: Look)

var current_look: Look = Look.OFF

var _flash: ColorRect
var _quad: ColorRect
var _material: ShaderMaterial
var _look_tween: Tween

var crt_curvature: float = 0.0: set = _set_curvature
var crt_scanlines: float = 0.0: set = _set_scanlines
var crt_mask: float = 0.0: set = _set_mask
var crt_grain: float = 0.0: set = _set_grain
var crt_flicker: float = 0.0: set = _set_flicker
var crt_bloom: float = 0.0: set = _set_bloom
var crt_brightness: float = 1.0: set = _set_brightness
var crt_saturation: float = 1.0: set = _set_saturation
var crt_vignette: float = 0.0: set = _set_crt_vignette

var pulse_aberration: float = 0.0: set = _set_pulse_aberration
var pulse_vignette: float = 0.0: set = _set_pulse_vignette
var pulse_warp: float = 0.0: set = _set_pulse_warp


func _init() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_flash = _make_fullscreen_rect()
	_flash.color = Color(1, 1, 1, 0)
	add_child(_flash)

	_quad = _make_fullscreen_rect()
	_quad.color = Color.WHITE
	_quad.visible = false
	if ResourceLoader.exists(SHADER_PATH):
		_material = ShaderMaterial.new()
		_material.shader = load(SHADER_PATH)
		if ResourceLoader.exists(NOISE_PATH):
			_material.set_shader_parameter(&"noise_texture", load(NOISE_PATH))
		_quad.material = _material
	add_child(_quad)
	_push()


func _process(_delta: float) -> void:
	if _material == null or not _quad.visible:
		return
	_material.set_shader_parameter(&"clock", Time.get_ticks_msec() / 1000.0)


func _make_fullscreen_rect() -> ColorRect:
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func set_look(look: Look, duration: float = 0.45) -> void:
	current_look = look
	var values := _look_values(look)

	if _look_tween != null and _look_tween.is_valid():
		_look_tween.kill()

	if duration <= 0.0:
		for key in values:
			set(key, values[key])
		look_changed.emit(look)
		return

	_look_tween = create_tween().set_parallel(true)
	for key in values:
		_look_tween.tween_property(self, NodePath(key), values[key], duration) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_look_tween.chain().tween_callback(func() -> void: look_changed.emit(look))


func _look_values(look: Look) -> Dictionary:
	match look:
		Look.SUBTLE:
			return {
				"crt_curvature": 0.03, "crt_scanlines": 0.07, "crt_mask": 0.06,
				"crt_grain": 0.035, "crt_flicker": 0.0, "crt_bloom": 0.18,
				"crt_brightness": 1.02, "crt_saturation": 1.0, "crt_vignette": 0.18,
			}
		Look.ARCADE:
			return {
				"crt_curvature": 0.22, "crt_scanlines": 0.26, "crt_mask": 0.34,
				"crt_grain": 0.06, "crt_flicker": 0.25, "crt_bloom": 0.5,
				"crt_brightness": 1.1, "crt_saturation": 1.12, "crt_vignette": 0.32,
			}
		Look.HANDHELD:
			return {
				"crt_curvature": 0.0, "crt_scanlines": 0.1, "crt_mask": 0.55,
				"crt_grain": 0.02, "crt_flicker": 0.0, "crt_bloom": 0.1,
				"crt_brightness": 1.05, "crt_saturation": 0.72, "crt_vignette": 0.22,
			}
		Look.BROKEN:
			return {
				"crt_curvature": 0.38, "crt_scanlines": 0.4, "crt_mask": 0.45,
				"crt_grain": 0.22, "crt_flicker": 0.8, "crt_bloom": 0.7,
				"crt_brightness": 1.0, "crt_saturation": 0.65, "crt_vignette": 0.5,
			}
		_:
			return {
				"crt_curvature": 0.0, "crt_scanlines": 0.0, "crt_mask": 0.0,
				"crt_grain": 0.0, "crt_flicker": 0.0, "crt_bloom": 0.0,
				"crt_brightness": 1.0, "crt_saturation": 1.0, "crt_vignette": 0.0,
			}


func flash(color: Color = Color(1, 1, 1, 0.55), duration: float = 0.12) -> Tween:
	if _flash == null:
		return null
	_flash.color = color
	var tween := create_tween()
	tween.tween_property(_flash, ^"color:a", 0.0, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tween


func chromatic(amount: float = 0.006, duration: float = 0.22) -> Tween:
	if _material == null:
		return null
	pulse_aberration = amount
	var tween := create_tween()
	tween.tween_property(self, ^"pulse_aberration", 0.0, duration) \
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	return tween


func vignette_pulse(amount: float = 0.5, duration: float = 0.4) -> Tween:
	if _material == null:
		return null
	pulse_vignette = amount
	var tween := create_tween()
	tween.tween_property(self, ^"pulse_vignette", 0.0, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tween


func warp(amount: float = 0.5, duration: float = 0.35) -> Tween:
	if _material == null:
		return null
	pulse_warp = amount
	var tween := create_tween()
	tween.tween_property(self, ^"pulse_warp", 0.0, duration) \
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	return tween


func glitch(strength: float = 1.0, duration: float = 0.3) -> void:
	warp(0.5 * strength, duration)
	chromatic(0.012 * strength, duration)
	flash(Color(0.7, 0.9, 1.0, 0.16 * strength), duration * 0.4)


func fade_to(color: Color = Color.BLACK, duration: float = 0.4) -> Tween:
	if _flash == null:
		return null
	_flash.color = Color(color.r, color.g, color.b, _flash.color.a)
	var tween := create_tween()
	tween.tween_property(_flash, ^"color:a", color.a, duration)
	return tween


func fade_from(color: Color = Color.BLACK, duration: float = 0.4) -> Tween:
	if _flash == null:
		return null
	_flash.color = color
	var tween := create_tween()
	tween.tween_property(_flash, ^"color:a", 0.0, duration)
	return tween


func reset() -> void:
	if _flash != null:
		_flash.color = Color(1, 1, 1, 0)
	pulse_aberration = 0.0
	pulse_vignette = 0.0
	pulse_warp = 0.0


func _set_curvature(value: float) -> void:
	crt_curvature = value
	_push()


func _set_scanlines(value: float) -> void:
	crt_scanlines = value
	_push()


func _set_mask(value: float) -> void:
	crt_mask = value
	_push()


func _set_grain(value: float) -> void:
	crt_grain = value
	_push()


func _set_flicker(value: float) -> void:
	crt_flicker = value
	_push()


func _set_bloom(value: float) -> void:
	crt_bloom = value
	_push()


func _set_brightness(value: float) -> void:
	crt_brightness = value
	_push()


func _set_saturation(value: float) -> void:
	crt_saturation = value
	_push()


func _set_crt_vignette(value: float) -> void:
	crt_vignette = value
	_push()


func _set_pulse_aberration(value: float) -> void:
	pulse_aberration = value
	_push()


func _set_pulse_vignette(value: float) -> void:
	pulse_vignette = value
	_push()


func _set_pulse_warp(value: float) -> void:
	pulse_warp = value
	_push()


func _push() -> void:
	if _material == null or _quad == null:
		return

	_material.set_shader_parameter(&"curvature", crt_curvature)
	_material.set_shader_parameter(&"scanline_strength", crt_scanlines)
	_material.set_shader_parameter(&"mask_strength", crt_mask)
	_material.set_shader_parameter(&"grain", crt_grain)
	_material.set_shader_parameter(&"flicker", crt_flicker)
	_material.set_shader_parameter(&"bloom", crt_bloom)
	_material.set_shader_parameter(&"brightness", crt_brightness)
	_material.set_shader_parameter(&"saturation", crt_saturation)
	_material.set_shader_parameter(&"aberration", pulse_aberration)
	_material.set_shader_parameter(&"vignette", clampf(crt_vignette + pulse_vignette, 0.0, 1.0))
	_material.set_shader_parameter(&"warp", pulse_warp)

	# Hide the quad entirely when nothing is on. It is a full screen pass that
	# reads the screen texture, not something to leave running for free.
	_quad.visible = (
		crt_curvature > 0.001 or crt_scanlines > 0.001 or crt_mask > 0.001
		or crt_grain > 0.001 or crt_flicker > 0.001 or crt_bloom > 0.001
		or crt_vignette > 0.001 or pulse_aberration > 0.0001
		or pulse_vignette > 0.001 or pulse_warp > 0.001
		or absf(crt_brightness - 1.0) > 0.001 or absf(crt_saturation - 1.0) > 0.001
	)

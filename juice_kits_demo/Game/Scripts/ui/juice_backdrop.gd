# The animated background. Sky gradient, stars, sun, parallax ridges and poles,
# all drawn, no images except the sun glow.
# It cycles through five palettes and cross fades every colour, so a menu left
# open slowly moves from dusk to night to dawn.
@tool
class_name JuiceBackdrop
extends Control


class Palette extends RefCounted:
	var name: String
	var sky_top: Color
	var sky_mid: Color
	var sky_low: Color
	var sun: Color
	var ridge_near: Color
	var ridge_far: Color

	func _init(
		p_name: String, top: String, mid: String, low: String,
		p_sun: String, near: String, far: String
	) -> void:
		name = p_name
		sky_top = Color(top)
		sky_mid = Color(mid)
		sky_low = Color(low)
		sun = Color(p_sun)
		ridge_near = Color(near)
		ridge_far = Color(far)

	func blend(other: Palette, t: float) -> Palette:
		var out := Palette.new(other.name, "000000", "000000", "000000", "000000", "000000", "000000")
		out.sky_top = sky_top.lerp(other.sky_top, t)
		out.sky_mid = sky_mid.lerp(other.sky_mid, t)
		out.sky_low = sky_low.lerp(other.sky_low, t)
		out.sun = sun.lerp(other.sun, t)
		out.ridge_near = ridge_near.lerp(other.ridge_near, t)
		out.ridge_far = ridge_far.lerp(other.ridge_far, t)
		return out


@export_group("Colour cycle")
@export_range(1.0, 300.0, 0.5) var cycle_seconds: float = 22.0
@export_range(0.05, 1.0, 0.01) var blend_fraction: float = 0.45
@export var cycle_enabled: bool = true
@export_range(0, 4, 1) var fixed_palette: int = 0:
	set(value):
		fixed_palette = value
		queue_redraw()

@export_group("Sky")
@export_range(0.2, 0.95, 0.01) var horizon: float = 0.66

@export_group("Sun")
@export var draw_sun: bool = true
@export_range(0.0, 1.0, 0.01) var sun_x: float = 0.5
@export_range(-0.2, 0.4, 0.005) var sun_lift: float = 0.05
@export var sun_radius: float = 120.0
@export_range(1.0, 6.0, 0.1) var glow_spread: float = 3.4

@export_group("Ridges")
@export_range(1, 8, 1) var layer_count: int = 5
@export_range(8, 256, 1) var steps: int = 72
@export_range(0.0, 1.0, 0.01) var near_base: float = 0.95
@export_range(0.0, 1.0, 0.01) var far_base: float = 0.63
@export_range(0.0, 0.5, 0.005) var near_amp: float = 0.045
@export_range(0.0, 0.5, 0.005) var far_amp: float = 0.1
@export var near_speed: float = 30.0
@export var far_speed: float = 4.0

@export_group("Poles")
@export var poles: bool = true
@export var pole_gap: float = 330.0
@export var pole_height: float = 124.0
@export var pole_width: float = 7.0
@export var pole_arm: float = 32.0

@export_group("Stars")
@export var star_count: int = 90
@export var star_size: float = 1.9

@export_group("Scrim")
@export var scrim_color: Color = Color(0.01, 0.02, 0.04, 0.55)
@export_range(0.0, 1.0, 0.01) var scrim_height: float = 0.4

@export var seed_value: int = 20260815:
	set(value):
		seed_value = value
		_build()
		queue_redraw()

const GLOW_PATH := "res://Game/Assets/textures/glow_wide.png"

var _time: float = 0.0
var _layers: Array[Dictionary] = []
var _stars: Array[Dictionary] = []
var _palettes: Array[Palette] = []
var _glow: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(GLOW_PATH):
		_glow = load(GLOW_PATH)
	_build()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func current_palette() -> Palette:
	if _palettes.is_empty():
		_build_palettes()
	if not cycle_enabled:
		return _palettes[posmod(fixed_palette, _palettes.size())]

	var period := maxf(cycle_seconds, 0.1)
	var progress := _time / period
	var index := int(floor(progress)) % _palettes.size()
	var next := (index + 1) % _palettes.size()
	var phase := fposmod(progress, 1.0)

	# Hold on a palette, then cross fade over the tail of the period, so each one
	# gets time to be looked at instead of being permanently mid transition.
	var hold := 1.0 - clampf(blend_fraction, 0.05, 1.0)
	if phase <= hold:
		return _palettes[index]

	var t := (phase - hold) / maxf(1.0 - hold, 0.001)
	return _palettes[index].blend(_palettes[next], smoothstep(0.0, 1.0, t))


func _build_palettes() -> void:
	_palettes = [
		Palette.new("DUSK",  "061316", "113036", "21545a", "ff8c3c", "030c0e", "1d434a"),
		Palette.new("NIGHT", "05060f", "0d1230", "1b2050", "6a7cff", "02030a", "171c3d"),
		Palette.new("EMBER", "1a0f14", "43171f", "8c2f35", "ffb15c", "0d0508", "4b1d26"),
		Palette.new("DAWN",  "1a1030", "4a2350", "b0525f", "ffc36b", "120a1c", "43284e"),
		Palette.new("NEON",  "0b0416", "2a0a3d", "5c1259", "ff4f8b", "07020e", "360f4a"),
	]


func _build() -> void:
	_build_palettes()
	_layers.clear()
	_stars.clear()

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	for i in maxi(layer_count, 1):
		var depth := float(i) / float(maxi(layer_count - 1, 1))
		_layers.append({
			"depth": depth,
			"base": lerpf(far_base, near_base, depth),
			"amp": lerpf(far_amp, near_amp, depth),
			"speed": lerpf(far_speed, near_speed, depth),
			"waves": [
				{"k": rng.randf_range(0.7, 1.3), "a": rng.randf_range(0.5, 1.0), "p": rng.randf() * TAU},
				{"k": rng.randf_range(1.8, 3.1), "a": rng.randf_range(0.2, 0.5), "p": rng.randf() * TAU},
				{"k": rng.randf_range(4.0, 6.5), "a": rng.randf_range(0.08, 0.2), "p": rng.randf() * TAU},
			],
		})

	for i in star_count:
		_stars.append({
			"at": Vector2(rng.randf(), rng.randf() * 0.55),
			"size": rng.randf_range(0.5, 1.0),
			"rate": rng.randf_range(0.4, 1.8),
			"phase": rng.randf() * TAU,
		})


func _ridge_y(layer: Dictionary, x: float) -> float:
	var shift := _time * float(layer["speed"])
	var span := maxf(size.x, 1.0)
	var reach := 0.0
	for wave in layer["waves"]:
		reach += float(wave["a"]) * sin(
			(x + shift) / span * TAU * float(wave["k"]) + float(wave["p"]))
	return size.y * (float(layer["base"]) + reach * float(layer["amp"]))


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	if _layers.is_empty():
		_build()

	var palette := current_palette()

	_draw_sky(palette)
	_draw_stars(palette)
	if draw_sun:
		_draw_sun(palette)
	for layer in _layers:
		_draw_ridge(layer, palette)
	_draw_scrim()


func _draw_sky(palette: Palette) -> void:
	var split := size.y * horizon
	draw_polygon(
		PackedVector2Array([
			Vector2.ZERO, Vector2(size.x, 0.0), Vector2(size.x, split), Vector2(0.0, split)]),
		PackedColorArray([palette.sky_top, palette.sky_top, palette.sky_mid, palette.sky_mid]))
	draw_polygon(
		PackedVector2Array([
			Vector2(0.0, split), Vector2(size.x, split),
			Vector2(size.x, size.y), Vector2(0.0, size.y)]),
		PackedColorArray([palette.sky_mid, palette.sky_mid, palette.sky_low, palette.sky_low]))


func _draw_stars(palette: Palette) -> void:
	var brightness := palette.sky_top.get_luminance()
	var visibility := clampf(1.0 - brightness * 5.0, 0.0, 1.0)
	if visibility <= 0.01:
		return

	for star in _stars:
		var at: Vector2 = star["at"]
		var beat: float = 0.55 + 0.45 * sin(_time * float(star["rate"]) + float(star["phase"]))
		var tint := Color(1, 1, 1, 0.55 * beat * visibility * (1.0 - at.y / 0.6))
		if tint.a <= 0.01:
			continue
		draw_circle(at * size, star_size * float(star["size"]), tint)


func _draw_sun(palette: Palette) -> void:
	var at := Vector2(size.x * sun_x, size.y * (horizon - sun_lift))

	if _glow != null:
		var reach := sun_radius * glow_spread
		var halo := palette.sun
		halo.a *= 0.55
		draw_texture_rect(
			_glow, Rect2(at - Vector2(reach, reach), Vector2(reach, reach) * 2.0), false, halo)

	draw_circle(at, sun_radius, palette.sun)


func _draw_ridge(layer: Dictionary, palette: Palette) -> void:
	var depth: float = layer["depth"]
	var tint := palette.ridge_far.lerp(palette.ridge_near, depth)

	var shape := PackedVector2Array()
	for i in steps + 1:
		var x := size.x * float(i) / float(steps)
		shape.append(Vector2(x, _ridge_y(layer, x)))
	shape.append(Vector2(size.x, size.y))
	shape.append(Vector2(0.0, size.y))
	draw_colored_polygon(shape, tint)

	if poles and is_equal_approx(depth, 1.0):
		_draw_poles(layer, tint)


func _draw_poles(layer: Dictionary, tint: Color) -> void:
	var shift := fposmod(_time * float(layer["speed"]) * 1.35, pole_gap)
	var x := -shift
	while x < size.x + pole_gap:
		var top := _ridge_y(layer, x) - pole_height
		draw_rect(Rect2(x - pole_width * 0.5, top, pole_width, pole_height + 20.0), tint)
		draw_rect(Rect2(x - pole_arm * 0.5, top, pole_arm, pole_width * 0.8), tint)
		x += pole_gap


func _draw_scrim() -> void:
	if scrim_color.a <= 0.0:
		return
	var clear := scrim_color
	clear.a = 0.0
	var low := size.y * scrim_height
	draw_polygon(
		PackedVector2Array([
			Vector2.ZERO, Vector2(size.x, 0.0), Vector2(size.x, low), Vector2(0.0, low)]),
		PackedColorArray([scrim_color, scrim_color, clear, clear]))

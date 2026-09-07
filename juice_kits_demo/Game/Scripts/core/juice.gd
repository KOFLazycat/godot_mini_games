# The autoload. Everything goes through here.
# Juice.shake(), Juice.hitstop(), Juice.toast(), Juice.impact() and so on.
# Juice.enabled = false kills every effect at once, which is how I check whether
# an effect is actually doing anything or just costing frames.
extends Node


signal enabled_changed(is_enabled: bool)

const CONFIG_PATH := "res://Game/Assets/juice_config.tres"

# Autoloads sit before the main scene in the tree, so without this every
# damage number draws behind the game.
const WORLD_Z_INDEX := 100

var enabled: bool = true:
	set(value):
		if enabled == value:
			return
		enabled = value
		if not enabled:
			_silence()
		enabled_changed.emit(enabled)

var intensity: float = 1.0:
	set(value):
		intensity = clampf(value, 0.0, 2.0)

var config: JuiceConfig
var time: JuiceTime
var screen: ScreenFX
var numbers: DamageNumbers
var sfx: JuiceSfx
var toasts: ToastLayer

var world: Node2D

var _cameras: Array[ShakeCamera2D] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	config = _load_config()
	enabled = config.enabled
	intensity = config.master_intensity

	time = JuiceTime.new()
	time.name = "JuiceTime"
	time.setup(config)
	add_child(time)

	world = Node2D.new()
	world.name = "JuiceWorld"
	world.z_index = WORLD_Z_INDEX
	add_child(world)

	numbers = DamageNumbers.new()
	numbers.name = "DamageNumbers"
	numbers.setup(config)
	world.add_child(numbers)

	sfx = JuiceSfx.new()
	sfx.name = "JuiceSfx"
	add_child(sfx)
	sfx.setup(config)

	toasts = ToastLayer.new()
	toasts.name = "ToastLayer"
	add_child(toasts)

	screen = ScreenFX.new()
	screen.name = "ScreenFX"
	add_child(screen)


func _exit_tree() -> void:
	HitFlash.clear_cache()
	JuicePalette.clear_cache()


func _load_config() -> JuiceConfig:
	if ResourceLoader.exists(CONFIG_PATH):
		var loaded := load(CONFIG_PATH)
		if loaded is JuiceConfig:
			return loaded
		push_warning("Juice: %s is not a JuiceConfig. Using built-in defaults." % CONFIG_PATH)
	return JuiceConfig.new()


func impact(world_position: Vector2, strength: float = 0.5) -> void:
	if not enabled:
		return
	strength = clampf(strength, 0.0, 1.0)

	shake_at(world_position, lerpf(0.18, 0.75, strength))
	hitstop(lerpf(0.035, 0.13, strength))

	# The screen wide stuff only really opens up past halfway, so ordinary hits
	# do not wash out the big ones.
	if strength > 0.25:
		flash(Color(1, 1, 1, lerpf(0.0, 0.4, strength)), 0.1)
	if strength > 0.45:
		chromatic(lerpf(0.0, 0.009, strength))
		zoom_punch(lerpf(0.0, 0.05, strength))
	rumble(lerpf(0.15, 0.7, strength), lerpf(0.2, 0.9, strength), lerpf(0.1, 0.3, strength))
	play_sfx(&"hit_heavy" if strength > 0.5 else &"hit_light", world_position)


func register_camera(camera: ShakeCamera2D) -> void:
	if camera not in _cameras:
		_cameras.append(camera)


func unregister_camera(camera: ShakeCamera2D) -> void:
	_cameras.erase(camera)


func get_camera() -> ShakeCamera2D:
	_cameras = _cameras.filter(func(c: ShakeCamera2D) -> bool: return is_instance_valid(c))
	if _cameras.is_empty():
		return null
	var viewport := get_viewport()
	if viewport != null:
		var active := viewport.get_camera_2d()
		if active is ShakeCamera2D:
			return active
	return _cameras.back()


func shake(amount: float = 0.4) -> void:
	if not enabled:
		return
	var camera := get_camera()
	if camera != null:
		camera.add_trauma(amount * intensity)


func shake_at(world_position: Vector2, amount: float = 0.5, radius: float = 600.0) -> void:
	if not enabled:
		return
	var camera := get_camera()
	if camera == null:
		return
	var distance := camera.global_position.distance_to(world_position)
	var falloff := 1.0 - clampf(distance / maxf(radius, 1.0), 0.0, 1.0)
	if falloff <= 0.0:
		return
	camera.add_trauma(amount * falloff * falloff * intensity)


func kick(direction: Vector2, strength: float = 12.0) -> void:
	if not enabled:
		return
	var camera := get_camera()
	if camera != null:
		camera.kick(direction, strength * intensity)


func zoom_punch(amount: float = 0.06, duration: float = 0.28) -> void:
	if not enabled:
		return
	var camera := get_camera()
	if camera != null:
		camera.zoom_punch(amount * intensity, duration)


func hitstop(duration: float = -1.0, scale: float = -1.0) -> void:
	if not enabled:
		return
	time.hitstop(duration, scale)


func slowmo(scale: float = -1.0, duration: float = -1.0) -> void:
	if not enabled:
		return
	time.slowmo(scale, duration)


func punch(node: CanvasItem, amount: float = -1.0, duration: float = -1.0) -> void:
	if not enabled:
		return
	if amount < 0.0:
		amount = config.punch_amount
	if duration < 0.0:
		duration = config.punch_duration
	JuiceTween.punch_scale(node, amount * intensity, duration)


func squash(node: CanvasItem, amount: float = -1.0, axis: Vector2 = Vector2.RIGHT) -> void:
	if not enabled:
		return
	if amount < 0.0:
		amount = config.squash_amount
	JuiceTween.squash_stretch(node, amount * intensity, config.punch_duration, axis)


func pop_in(node: CanvasItem, duration: float = 0.4) -> void:
	if not enabled:
		return
	JuiceTween.pop_in(node, duration)


func pop_out(node: CanvasItem, duration: float = 0.25, free_when_done: bool = false) -> void:
	if not enabled:
		if free_when_done and is_instance_valid(node):
			node.queue_free()
		return
	JuiceTween.pop_out(node, duration, free_when_done)


func hit_flash(node: CanvasItem, color: Color = Color.WHITE, duration: float = -1.0) -> void:
	if not enabled:
		return
	if duration < 0.0:
		duration = config.hit_flash_duration
	HitFlash.flash(node, color, duration)


func damage_number(
	world_position: Vector2,
	value: Variant,
	crit: bool = false,
	color: Variant = null
) -> Label:
	if not enabled or numbers == null:
		return null
	return numbers.spawn(world_position, str(value), crit, color)


func toast(
	message: String,
	color: Color = JuicePalette.PINK,
	hold: float = 1.4,
	icon: Texture2D = null
) -> JuiceToast:
	if not enabled or toasts == null:
		return null
	return toasts.push(message, color, hold, icon)


func flash(color: Color = Color(1, 1, 1, 0.0), duration: float = -1.0) -> void:
	if not enabled or screen == null:
		return
	if color.a <= 0.0:
		color = config.flash_color
	if duration < 0.0:
		duration = config.flash_duration
	screen.flash(color, duration)


func chromatic(amount: float = -1.0, duration: float = -1.0) -> void:
	if not enabled or screen == null:
		return
	if amount < 0.0:
		amount = config.chromatic_amount
	if duration < 0.0:
		duration = config.chromatic_duration
	screen.chromatic(amount * intensity, duration)


func vignette(amount: float = 0.5, duration: float = 0.4) -> void:
	if not enabled or screen == null:
		return
	screen.vignette_pulse(amount * intensity, duration)


func warp(amount: float = 0.5, duration: float = 0.35) -> void:
	if not enabled or screen == null:
		return
	screen.warp(amount * intensity, duration)


func glitch(strength: float = 1.0, duration: float = 0.3) -> void:
	if not enabled or screen == null:
		return
	screen.glitch(strength * intensity, duration)


func set_look(look: ScreenFX.Look, duration: float = 0.45) -> void:
	if screen != null:
		screen.set_look(look, duration)


func fade_to(color: Color = Color.BLACK, duration: float = 0.4) -> Tween:
	if screen == null:
		return null
	return screen.fade_to(color, duration)


func fade_from(color: Color = Color.BLACK, duration: float = 0.4) -> Tween:
	if screen == null:
		return null
	return screen.fade_from(color, duration)


func play_sfx(
	bank_name: StringName,
	position: Variant = null,
	volume_offset_db: float = 0.0
) -> Node:
	if not enabled or sfx == null:
		return null
	return sfx.play(bank_name, position, volume_offset_db)


func rumble(weak: float = -1.0, strong: float = -1.0, duration: float = -1.0) -> void:
	if not enabled:
		return
	if weak < 0.0:
		weak = config.rumble_weak
	if strong < 0.0:
		strong = config.rumble_strong
	if duration < 0.0:
		duration = config.rumble_duration
	for device in Input.get_connected_joypads():
		Input.start_joy_vibration(
			device,
			clampf(weak * intensity, 0.0, 1.0),
			clampf(strong * intensity, 0.0, 1.0),
			duration
		)


func stop_rumble() -> void:
	for device in Input.get_connected_joypads():
		Input.stop_joy_vibration(device)


func _silence() -> void:
	if time != null:
		time.reset()
	for camera in _cameras:
		if is_instance_valid(camera):
			camera.reset()
	if screen != null:
		screen.reset()
	if numbers != null:
		numbers.clear()
	if sfx != null:
		sfx.stop_all()
	if toasts != null:
		toasts.clear()
	stop_rumble()

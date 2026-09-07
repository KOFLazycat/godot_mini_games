# Camera2D with screen shake. Put this script on your camera and Juice.shake()
# starts working.
# It takes trauma rather than "shake for N seconds at strength S". Overlapping
# hits then add up into one shake instead of fighting each other, and trauma is
# squared before use so small hits stay subtle while big ones still slam.
class_name ShakeCamera2D
extends Camera2D


@export var max_offset: Vector2 = Vector2(26.0, 18.0)
@export_range(0.0, 0.5, 0.001) var max_roll: float = 0.06
@export_range(0.1, 10.0, 0.05) var decay: float = 2.4
@export_range(1.0, 120.0, 1.0) var frequency: float = 42.0
@export_range(1.0, 4.0, 0.1) var shake_power: float = 2.0
@export var ignore_time_scale: bool = true

@export_group("Recoil Kick")
@export_range(1.0, 400.0, 1.0) var kick_stiffness: float = 120.0
@export_range(1.0, 60.0, 0.5) var kick_damping: float = 14.0

var trauma: float = 0.0:
	set(value):
		trauma = clampf(value, 0.0, 1.0)

var _noise := FastNoiseLite.new()
var _noise_time: float = 0.0
var _base_offset: Vector2 = Vector2.ZERO
var _base_rotation: float = 0.0
var _base_zoom: Vector2 = Vector2.ONE
var _kick: Vector2 = Vector2.ZERO
var _kick_velocity: Vector2 = Vector2.ZERO
var _zoom_offset: float = 0.0
var _last_real_ms: int = 0


func _ready() -> void:
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 1.0
	_noise.seed = randi()

	_base_offset = offset
	_base_rotation = rotation
	_base_zoom = zoom
	_last_real_ms = Time.get_ticks_msec()

	var juice := get_node_or_null(^"/root/Juice")
	if juice != null:
		juice.register_camera(self)


func _exit_tree() -> void:
	var juice := get_node_or_null(^"/root/Juice")
	if juice != null:
		juice.unregister_camera(self)


func add_trauma(amount: float) -> void:
	trauma = trauma + amount


func kick(direction: Vector2, strength: float = 12.0) -> void:
	_kick_velocity += direction.normalized() * strength * 10.0


func zoom_punch(amount: float = 0.06, duration: float = 0.28) -> void:
	var tween := create_tween()
	tween.tween_property(self, "_zoom_offset", amount, duration * 0.25) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_zoom_offset", 0.0, duration * 0.75) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func reset() -> void:
	trauma = 0.0
	_kick = Vector2.ZERO
	_kick_velocity = Vector2.ZERO
	_zoom_offset = 0.0
	offset = _base_offset
	rotation = _base_rotation
	zoom = _base_zoom


func rebase() -> void:
	_base_offset = offset
	_base_rotation = rotation
	_base_zoom = zoom


func _process(delta: float) -> void:
	var real_now := Time.get_ticks_msec()
	var real_delta := float(real_now - _last_real_ms) / 1000.0
	_last_real_ms = real_now

	var dt := real_delta if ignore_time_scale else delta
	# A long stall would otherwise fling the spring across the screen.
	dt = minf(dt, 0.1)

	_update_kick(dt)

	if trauma <= 0.0:
		if _kick.is_zero_approx() and is_zero_approx(_zoom_offset):
			offset = _base_offset + _kick
			rotation = _base_rotation
			zoom = _base_zoom
			return
	else:
		trauma = maxf(trauma - decay * dt, 0.0)

	_noise_time += dt * frequency

	var amount := pow(trauma, shake_power)
	var shake_offset := Vector2(
		max_offset.x * amount * _noise.get_noise_2d(_noise_time, 0.0),
		max_offset.y * amount * _noise.get_noise_2d(0.0, _noise_time)
	)

	offset = _base_offset + shake_offset + _kick
	rotation = _base_rotation + max_roll * amount * _noise.get_noise_2d(_noise_time, 100.0)
	zoom = _base_zoom * (1.0 + _zoom_offset)


func _update_kick(dt: float) -> void:
	if _kick.is_zero_approx() and _kick_velocity.is_zero_approx():
		return
	var accel := -kick_stiffness * _kick - kick_damping * _kick_velocity
	_kick_velocity += accel * dt
	_kick += _kick_velocity * dt
	if _kick.length_squared() < 0.01 and _kick_velocity.length_squared() < 0.01:
		_kick = Vector2.ZERO
		_kick_velocity = Vector2.ZERO

# Hitstop and slow motion. Owns Engine.time_scale.
# Hitstop always beats slowmo, a hit landing during bullet time should still
# read as a hit.
class_name JuiceTime
extends Node


signal hitstop_started(duration: float)
signal hitstop_ended()
signal slowmo_started(scale: float)
signal slowmo_ended()

const _EPSILON := 0.001

var _config: JuiceConfig

var _hitstop_end_ms: int = 0
var _hitstop_scale: float = 0.0
var _hitstop_active: bool = false

var _slowmo_active: bool = false
var _slowmo_start_ms: int = 0
var _slowmo_scale: float = 1.0
var _slowmo_blend_in_ms: int = 0
var _slowmo_hold_ms: int = 0
var _slowmo_blend_out_ms: int = 0


func _init(config: JuiceConfig = null) -> void:
	_config = config
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup(config: JuiceConfig) -> void:
	_config = config


func hitstop(duration: float = -1.0, scale: float = -1.0) -> void:
	if duration < 0.0:
		duration = _config.hitstop_duration
	if scale < 0.0:
		scale = _config.hitstop_scale
	if duration <= 0.0:
		return

	var end_ms := Time.get_ticks_msec() + int(duration * 1000.0)
	if end_ms <= _hitstop_end_ms:
		return

	_hitstop_end_ms = end_ms
	_hitstop_scale = scale
	if not _hitstop_active:
		_hitstop_active = true
		hitstop_started.emit(duration)
	_apply()


func slowmo(
	scale: float = -1.0,
	duration: float = -1.0,
	blend_in: float = -1.0,
	blend_out: float = -1.0
) -> void:
	if scale < 0.0:
		scale = _config.slowmo_scale
	if duration < 0.0:
		duration = _config.slowmo_duration
	if blend_in < 0.0:
		blend_in = _config.slowmo_blend_in
	if blend_out < 0.0:
		blend_out = _config.slowmo_blend_out

	_slowmo_scale = maxf(scale, 0.01)
	_slowmo_start_ms = Time.get_ticks_msec()
	_slowmo_blend_in_ms = int(blend_in * 1000.0)
	_slowmo_hold_ms = int(duration * 1000.0)
	_slowmo_blend_out_ms = int(blend_out * 1000.0)
	if not _slowmo_active:
		_slowmo_active = true
		slowmo_started.emit(_slowmo_scale)
	_apply()


func reset() -> void:
	var was_hitstop := _hitstop_active
	var was_slowmo := _slowmo_active
	_hitstop_active = false
	_hitstop_end_ms = 0
	_slowmo_active = false
	Engine.time_scale = 1.0
	if was_hitstop:
		hitstop_ended.emit()
	if was_slowmo:
		slowmo_ended.emit()


func is_hitstopped() -> bool:
	return _hitstop_active


func is_slowmo() -> bool:
	return _slowmo_active


# Timed off the system clock, not delta. delta is scaled by Engine.time_scale,
# so a freeze written against it would freeze its own countdown.
func _process(_delta: float) -> void:
	if not (_hitstop_active or _slowmo_active):
		return

	var now := Time.get_ticks_msec()

	if _hitstop_active and now >= _hitstop_end_ms:
		_hitstop_active = false
		hitstop_ended.emit()

	if _slowmo_active:
		var total := _slowmo_blend_in_ms + _slowmo_hold_ms + _slowmo_blend_out_ms
		if now - _slowmo_start_ms >= total:
			_slowmo_active = false
			slowmo_ended.emit()

	_apply()


func _apply() -> void:
	var target := 1.0
	if _slowmo_active:
		target = _current_slowmo_scale()
	if _hitstop_active:
		target = _hitstop_scale

	if absf(Engine.time_scale - target) > _EPSILON:
		Engine.time_scale = target


func _current_slowmo_scale() -> float:
	var elapsed := Time.get_ticks_msec() - _slowmo_start_ms

	if elapsed < _slowmo_blend_in_ms:
		var t := float(elapsed) / float(maxi(_slowmo_blend_in_ms, 1))
		return lerpf(1.0, _slowmo_scale, smoothstep(0.0, 1.0, t))

	var hold_end := _slowmo_blend_in_ms + _slowmo_hold_ms
	if elapsed < hold_end:
		return _slowmo_scale

	if _slowmo_blend_out_ms <= 0:
		return 1.0

	var t_out := float(elapsed - hold_end) / float(_slowmo_blend_out_ms)
	return lerpf(_slowmo_scale, 1.0, smoothstep(0.0, 1.0, clampf(t_out, 0.0, 1.0)))

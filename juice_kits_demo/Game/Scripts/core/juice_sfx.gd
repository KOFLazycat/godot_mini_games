# Sound playback. Pools the players, randomises pitch slightly, and drops
# duplicate sounds fired within a few ms of each other.
# That last part matters, identical samples starting on the same frame sum to
# double amplitude and clip.
class_name JuiceSfx
extends Node


# Prebuilt resource. Scanning res:// at runtime works in the editor but not in
# an exported build.
const LIBRARY_PATH := "res://Game/Assets/sfx_library.tres"

var library: SfxLibrary

var _config: JuiceConfig
var _positional: Array[AudioStreamPlayer2D] = []
var _flat: Array[AudioStreamPlayer] = []
var _last_played_ms: Dictionary = {}


func setup(config: JuiceConfig) -> void:
	_config = config
	if ResourceLoader.exists(LIBRARY_PATH):
		var loaded := load(LIBRARY_PATH)
		if loaded is SfxLibrary:
			library = loaded
	if library == null:
		library = SfxLibrary.new()
		push_warning(
			"JuiceSfx: no library at %s" % LIBRARY_PATH
		)


func play(
	bank_name: StringName,
	position: Variant = null,
	volume_offset_db: float = 0.0,
	force: bool = false
) -> Node:
	if library == null:
		return null
	var bank := library.get_bank(bank_name)
	if bank == null or bank.is_empty():
		return null
	if not force and _is_duplicate(bank_name):
		return null

	var stream := bank.pick()
	if stream == null:
		return null

	_last_played_ms[bank_name] = Time.get_ticks_msec()
	var pitch := bank.pick_pitch()
	var volume := bank.volume_db + volume_offset_db

	if position is Vector2:
		var player := _acquire_positional()
		player.stream = stream
		player.pitch_scale = pitch
		player.volume_db = volume
		player.global_position = position
		player.play()
		return player

	var flat := _acquire_flat()
	flat.stream = stream
	flat.pitch_scale = pitch
	flat.volume_db = volume
	flat.play()
	return flat


func stop_all() -> void:
	for player in _positional:
		if is_instance_valid(player):
			player.stop()
	for player in _flat:
		if is_instance_valid(player):
			player.stop()


func bank_names() -> Array:
	return library.bank_names() if library != null else []


func _is_duplicate(bank_name: StringName) -> bool:
	var window: float = _config.sfx_dedupe_ms if _config != null else 25.0
	if window <= 0.0:
		return false
	var last: int = _last_played_ms.get(bank_name, -100000)
	return Time.get_ticks_msec() - last < int(window)


func _acquire_positional() -> AudioStreamPlayer2D:
	for player in _positional:
		if is_instance_valid(player) and not player.playing:
			return player

	if _positional.size() >= _voice_limit():
		var oldest: AudioStreamPlayer2D = _positional.pop_front()
		_positional.append(oldest)
		return oldest

	var created := AudioStreamPlayer2D.new()
	created.bus = _bus()
	created.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(created)
	_positional.append(created)
	return created


func _acquire_flat() -> AudioStreamPlayer:
	for player in _flat:
		if is_instance_valid(player) and not player.playing:
			return player

	if _flat.size() >= _voice_limit():
		var oldest: AudioStreamPlayer = _flat.pop_front()
		_flat.append(oldest)
		return oldest

	var created := AudioStreamPlayer.new()
	created.bus = _bus()
	created.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(created)
	_flat.append(created)
	return created


func _voice_limit() -> int:
	return _config.sfx_voice_count if _config != null else 24


func _bus() -> StringName:
	if _config != null and AudioServer.get_bus_index(_config.sfx_bus) != -1:
		return _config.sfx_bus
	return &"Master"

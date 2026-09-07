# A group of interchangeable takes of the same sound. Picks a random one and
# never the same twice in a row, since repeats are what give away a canned sound.
@tool
class_name SfxBank
extends Resource


@export var streams: Array[AudioStream] = []
@export_range(-40.0, 12.0, 0.5) var volume_db: float = 0.0
@export var pitch_range: Vector2 = Vector2(0.92, 1.08)

var _last_index: int = -1


func pick() -> AudioStream:
	if streams.is_empty():
		return null
	if streams.size() == 1:
		return streams[0]

	# True random repeats far more often than players expect, and a repeat is
	# exactly the thing that gives away a canned sound.
	var index := randi() % streams.size()
	if index == _last_index:
		index = (index + 1 + randi() % (streams.size() - 1)) % streams.size()
	_last_index = index
	return streams[index]


func pick_pitch() -> float:
	return randf_range(pitch_range.x, pitch_range.y)


func is_empty() -> bool:
	return streams.is_empty()

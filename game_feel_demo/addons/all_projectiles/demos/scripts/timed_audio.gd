class_name TimedAudio
extends AudioStreamPlayer


func timed_free(_stream: AudioStream, headstart: float = 0.0, db: float = 0.0) -> void:
	pitch_scale = randf_range(0.95, 1.05)
	volume_db += db

	stream = _stream
	play(headstart)
	finished.connect(queue_free)

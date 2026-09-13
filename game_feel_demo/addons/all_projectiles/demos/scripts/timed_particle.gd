class_name TimedParticle
extends CPUParticles2D



func timed_free(_emitting: bool = false, temp: bool = false, _scale: float = 1.0) -> void:
	emitting = _emitting
	get_tree().create_timer(lifetime, false).timeout.connect(queue_free)

	if (temp):
		var explo: Node2D = $Explosion
		explo.rotation = randf_range(0, TAU)

		var buffer: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_pause_mode(Tween.TWEEN_PAUSE_STOP)
		buffer.tween_property($Explosion, "scale", Vector2.ONE * _scale, 0.25)
		buffer.parallel().tween_property($Explosion, "modulate", Color(0.945, 0.537, 0.086, 0.0), 0.25)
		buffer.parallel().tween_property($Shockwave, "scale", Vector2.ONE * _scale * 0.7, 0.25)
		buffer.parallel().tween_property($Shockwave, "modulate", Color(0.945, 0.537, 0.086, 0.25), 0.25)
		buffer.tween_callback(turn_off_childs)
	else:
		turn_off_childs.call_deferred()



func turn_off_childs() -> void:
	for child: Node2D in get_children():
		if (child is CPUParticles2D):
			var buffer: CPUParticles2D = child as CPUParticles2D
			buffer.emitting = false
		else:
			child.visible = false

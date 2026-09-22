extends LimboState


@export var animationPlayer: AnimationPlayer
@export var animationName: StringName


func _enter() -> void:
	if animationPlayer and animationPlayer.has_animation(animationName):
		animationPlayer.play(animationName, 0.1)
		await animationPlayer.animation_finished
	if is_active():
		get_root().dispatch(EVENT_FINISHED)


#func _update(_delta: float) -> void:
	#var horizontal_move: float = Input.get_axis(&"move_left", &"move_right")
	#var vertical_move: float = Input.get_axis(&"move_up", &"move_down")
	#if horizontal_move != 0.0 or vertical_move != 0.0:
		#get_root().dispatch(EVENT_FINISHED)

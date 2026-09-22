extends LimboState

@export var animationPlayer: AnimationPlayer
@export var animationName: StringName


func _enter() -> void:
	if animationPlayer and animationPlayer.has_animation(animationName):
		animationPlayer.play(animationName, 0.1)
		await animationPlayer.animation_finished
	if is_active():
		get_root().dispatch(EVENT_FINISHED)

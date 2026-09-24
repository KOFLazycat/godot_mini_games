extends LimboState

@export var animationPlayer: AnimationPlayer

@onready var bloodSpawner: BloodSpawner = $BloodSpawner


func _enter() -> void:
	var effectSpec: GameplayEffectSpec = get_cargo() as GameplayEffectSpec
	if effectSpec and animationPlayer:
		var targetData: GameplayAbilityTargetData = effectSpec.context.target_data
		var hitResults: Array[Dictionary] = targetData.get_hits_for_node(agent)
		
		for res: Dictionary in hitResults:
			bloodSpawner.spawnBloodFromData(res["position"], res["normal"], res["damage_direction"], false, false, false)
			if (res["position"].x < agent.sprite.global_position.x):
				animationPlayer.play("BackHit")
				animationPlayer.clear_queue()
				animationPlayer.queue("BackOvershoot")
			else: 
				animationPlayer.play("FrontHit")
				animationPlayer.clear_queue()
				animationPlayer.queue("FrontOvershoot")
			Juicee.flash(agent.sprite, Color.WHITE)
			await animationPlayer.animation_finished
	if is_active():
		get_root().dispatch(EVENT_FINISHED)

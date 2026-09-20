class_name GAbilityFireball
extends GameplayAbility

@export var damage_effect: GameplayEffect

func _activate_ability() -> bool:
	# 1. Pay the mana cost and trigger the cooldown automatically
	commit_ability()
	
	# 2. Trigger the casting audio/visuals via the Cue Manager
	#execute_cue(GameplayTags.Example_Cue_Vfx_Fireball_Impact)
	
	# 3. Spawn the physical projectile
	var ownerEntity: Entity = owner_asc.get_parent() as Entity
	if ownerEntity == null:
		return false
	var projectileComponent: ProjectileComponent = ownerEntity.getComponent(ProjectileComponent)
	if projectileComponent == null:
		return false
	projectileComponent.requestProjectile()
	#
	## Pass the ability reference and the damage data down to the fireball
	#fireball.setup(self, damage_effect) 
	#
	#get_tree().current_scene.add_child(fireball)
	
	return true

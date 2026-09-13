class_name Attack2DModifier
extends TimedModifier


## Attack2D instance being modified by this effect.
var attack: Attack2D:
	get:
		return get_target()
	set(value):
		set_target(value)




func copy(base: TimedModifier) -> void:
	super(base)

	if (base is Attack2DModifier):
		var buffer: Attack2DModifier = base as Attack2DModifier

		attack = buffer.attack


func clone() -> Attack2DModifier:
	var modifier: Attack2DModifier = Attack2DModifier.new()
	modifier.copy(self)

	return modifier




func validate_modifier(_attack: Attack2D) -> bool:
	if (on_validation.is_valid()): 
		return on_validation.call(self, _attack)
	if (_attack.attack_modifiers.has(name)):
		return false
	return true


func disable() -> void:
	if (attack.attack_modifiers[name].stacks > 1):
		attack.attack_modifiers[name].stacks -= 1
	else:
		attack.attack_modifiers.erase(name)
	copies.erase(self)
	attack = null
	super()
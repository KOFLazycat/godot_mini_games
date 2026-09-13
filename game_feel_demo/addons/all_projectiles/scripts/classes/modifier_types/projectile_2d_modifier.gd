class_name Projectile2DModifier
extends TimedModifier


## Projectile2D instance being modified by this effect.
var projectile: Projectile2D:
	get:
		return get_target()
	set(value):
		set_target(value)




func copy(base: TimedModifier) -> void:
	super(base)

	if (base is Projectile2DModifier):
		var buffer: Projectile2DModifier = base as Projectile2DModifier

		projectile = buffer.projectile


func clone() -> Projectile2DModifier:
	var modifier: Projectile2DModifier = Projectile2DModifier.new()
	modifier.copy(self)

	return modifier




func validate_modifier(_projectile: Projectile2D) -> bool:
	if (on_validation.is_valid()): 
		return on_validation.call(self, _projectile)
	if (_projectile.projectile_modifiers.has(name)):
		return false
	return true


func disable() -> void:
	if (projectile.projectile_modifiers[name].stacks > 1):
		projectile.projectile_modifiers[name].stacks -= 1
	else:
		projectile.projectile_modifiers.erase(name)
	copies.erase(self)
	projectile = null
	super()

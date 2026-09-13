class_name MyModifier
extends TimedModifier


## This is an extension of Your Custom Target
## Change its type to the one you are targeting (must extend RefCounted)
## This template uses Projectile2D as an example
var my_target: Projectile2D:
	get:
		return get_target()
	set(value):
		set_target(value)


func enter() -> void:
	super()
	print("enter")


func exit() -> void:
	super()
	print("exit")


func update(delta: float) -> void:
	super(delta) 




## Your Target Class must have a Dictionary[StringName, TimedModifier] property to function properly
func validate_modifier(_my_target: Projectile2D) -> bool:
	if (on_validation.is_valid()): 
		return on_validation.call(self, _my_target)
	if (_my_target.projectile_modifiers.has(name)):
		return false
	return true


## Your Target Class must have a Dictionary[StringName, TimedModifier] property to function properly
func disable() -> void:
	if (my_target.projectile_modifiers[name].stacks > 1):
		my_target.projectile_modifiers[name].stacks -= 1
	else:
		my_target.projectile_modifiers.erase(name)
	copies.erase(self)
	my_target = null
	super()




func copy(base: TimedModifier) -> void:
	super(base)

	if (base is MyModifier):
		var buffer: MyModifier = base as MyModifier
		my_target = buffer.my_target

		# Your custom class properties are copied here
		# my_property = base.my_property


# Match the return types with your own 'class_name'
# Otherwise your 'custom modifier' will not work properly
func clone() -> MyModifier:
	var modifier: MyModifier = MyModifier.new()
	modifier.copy(self)

	return modifier
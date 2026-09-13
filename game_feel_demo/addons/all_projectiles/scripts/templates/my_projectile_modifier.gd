class_name MyProjectileModifier
extends Projectile2DModifier


func enter() -> void:
	super()
	print("p enter")


func exit() -> void:
	super()
	print("p exit")


func update(delta: float) -> void:
	super(delta) 


func validate_modifier(_projectile: Projectile2D) -> bool:
	return super(_projectile)


func disable() -> void:
	super()




func copy(base: TimedModifier) -> void:
	super(base)

	if (base is MyProjectileModifier):
		# Your custom class properties are copied here
		# my_property = base.my_property
		pass


# Match the return types with your own 'class_name'
# Otherwise your 'custom projectile modifier' will not work properly
func clone() -> MyProjectileModifier:
	var modifier: MyProjectileModifier = MyProjectileModifier.new()
	modifier.copy(self)

	return modifier
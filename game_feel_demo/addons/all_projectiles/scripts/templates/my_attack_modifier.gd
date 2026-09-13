class_name MyAttackModifier
extends Attack2DModifier


func enter() -> void:
	super()
	print("a enter")


func exit() -> void:
	super()
	print("a exit")


func update(delta: float) -> void:
	super(delta) 


func validate_modifier(_attack: Attack2D) -> bool:
	return super(_attack)


func disable() -> void:
	super()




func copy(base: TimedModifier) -> void:
	super(base)

	if (base is MyAttackModifier):
		# Your custom class properties are copied here
		# my_property = base.my_property
		pass


# Match the return types with your own 'class_name'
# Otherwise your 'custom attack modifier' will not work properly
func clone() -> MyAttackModifier:
	var modifier: MyAttackModifier = MyAttackModifier.new()
	modifier.copy(self)

	return modifier
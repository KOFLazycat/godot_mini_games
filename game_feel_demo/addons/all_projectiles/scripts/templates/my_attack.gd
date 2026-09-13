class_name MyAttack
extends Attack2D


func _init(_resource: AttackBlueprint2D = null, _proj_caller: Node2D = null) -> void:
	if (_resource == null):
		return
	super(_resource, _proj_caller)


func start() -> void:
	super()
	# Example code
	print("hi :D")


func disable() -> void:
	super()




func charge_enter() -> void:
	super()

func charge_update(_delta: float) -> void:
	super(_delta)

func charge_exit() -> void:
	super()


func anticipate_enter() -> void:
	super()

func anticipate_update(_delta: float) -> void:
	super(_delta)

func anticipate_exit() -> void:
	super()


func main_enter() -> void:
	super()

func main_update(_delta: float) -> void:
	super(_delta)

func main_exit() -> void:
	super()


func recovery_enter() -> void:
	super()

func recovery_update(_delta: float) -> void:
	super(_delta)

func recovery_exit() -> void:
	super()



func copy(base: Attack2D) -> void:
	super(base)

	if (base is MyAttack):
		# Your custom class properties are copied here
		# my_property = base.my_property
		pass


# Match the return types with your own 'class_name'
# Otherwise your 'custom attack' will not work properly
func clone() -> MyAttack:
	var attack: MyAttack = MyAttack.new()
	attack.copy(self)

	return attack
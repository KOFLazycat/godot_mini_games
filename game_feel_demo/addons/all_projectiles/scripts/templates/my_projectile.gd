class_name MyProjectile
extends AreaProjectile2D


func _init(_resource: ProjectileBlueprint2D = null, _pi: PackedInfo = null) -> void:
	if (_resource == null):
		return
	super(_resource, _pi)
	
	# Set your init here

	if (_pi != null):
		assign(_pi)


# This is Your Projectile Start Method
func assign(pi: PackedInfo) -> void:
	super(pi)

	# Example code
	direction = Vector2.UP


func move(delta: float) -> void:
	super(delta)


func area_monitor_callback(status: int, area_rid: RID, instance_id: int, area_shape_index: int, self_shape_index: int) -> void:
	super(status, area_rid, instance_id, area_shape_index, self_shape_index)


func body_monitor_callback(status: int, body_rid: RID, instance_id: int, body_shape_index: int, self_shape_index: int) -> void:
	super(status, body_rid, instance_id, body_shape_index, self_shape_index)


func expire() -> void:
	super()



func copy(base: Projectile2D, pi: PackedInfo = null) -> void:
	super(base, pi)

	if (base is MyProjectile):
		# Your custom class properties are copied here
		# my_property = base.my_property
		pass
	
	if (pi != null):
		assign(pi)


# Match the return types with your own 'class_name'
# Otherwise your 'custom projectile' will not work properly
func clone(_pi: PackedInfo = null) -> MyProjectile:
	var proj: MyProjectile = MyProjectile.new()
	proj.copy(self)

	if (_pi != null):
		proj.assign(_pi)
	
	return proj
class_name InstancedProjectile2D
extends Projectile2D


## Shared root node of the currently loaded main scene used for projectile instancing
static var current_scene: Node

## Path to the mandatory Area2D element or child component in the InstancedProjectile2D instance scene
var collision_path: NodePath
## Scene file to be initialized as a projectile.
## Your scene must have an Area2D child Node to be valid.
var scene: PackedScene

## In-world projectile scene instance
var instance: Node2D
## Mandatory InstancedProjectile2D scene area collision component
var area: Area2D



func _init(_resource: ProjectileBlueprint2D = null, _pi: PackedInfo = null) -> void:
	if (_resource == null):
		return
	super(_resource, _pi)
	
	collision_path = _resource.collision_path
	scene = _resource.instance

	if (_pi != null):
		assign(_pi)


func reset() -> void:
	_init(resource)
	



func assign(_pi : PackedInfo) -> void:
	super(_pi)

	# Projectile2D Instantiate
	instance = scene.instantiate()
	instance.position = position
	current_scene.add_child(instance)

	# Collision linking
	area = instance.get_node_or_null(collision_path)
	if (area == null):
		printerr("Invalid projectile creation. \"%s\" doesn't have a valid \"Area2D\" component at path \"%s\"" % [resource.resource_path, collision_path])
		is_expired = true
		return

	area.monitorable = area_monitoreable
	area.collision_layer = collision_layer
	area.collision_mask = collision_mask
	area.area_shape_entered.connect(area_monitor_callback)
	area.body_shape_entered.connect(body_monitor_callback)


	headstart += _pi.headstart
	if (_pi.start_method.is_valid()):
		on_start = _pi.start_method
	if (on_start.is_valid()):
		on_start.call(self)

	if (headstart > 0):
		move(headstart)
	if (look_at):
		instance.look_at(position + direction) 
	
	if (wait_time > 0):
		disable_movement()
		disable_collisions()
		disable_graphics()


func activate_waiting_projectile() -> void:
	super()
	if (look_at):
		instance.look_at(position + direction) 




func copy(base: Projectile2D, _pi: PackedInfo = null) -> void:
	super(base)

	if (base is InstancedProjectile2D):
		var buffer: InstancedProjectile2D = base as InstancedProjectile2D

		collision_path = buffer.collision_path
		scene = buffer.scene

	if (_pi != null):
		assign(_pi)


func clone(_pi: PackedInfo = null) -> InstancedProjectile2D:
	var proj: InstancedProjectile2D = InstancedProjectile2D.new()
	proj.copy(self)

	if (_pi != null):
		proj.assign(_pi)

	return proj




func area_monitor_callback(area_rid: RID, collider_node: Node2D, area_shape_index: int, self_shape_index: int) -> void:
	var target_node: Node2D = validate_target(collider_node)
	if (use_custom_area_collision):
		on_area_collision.call(self, area_rid, collider_node, target_node, area_shape_index, self_shape_index)
		return
	
	if !validate_collision(area_rid, target_node):
		return

	if target_node.has_method(on_hit_call):
		target_node.call(on_hit_call, self)
	on_pierced(area_rid)


func body_monitor_callback(body_rid: RID, collider_node: Node2D, body_shape_index: int, self_shape_index: int) -> void:
	var target_node: Node2D = validate_target(collider_node)
	if (use_custom_body_collision):
		on_body_collision.call(self, body_rid, collider_node, target_node, body_shape_index, self_shape_index)
		return
	
	if !validate_collision(body_rid, target_node):
		return

	if target_node.has_method(on_hit_call):
		target_node.call(on_hit_call, self)
	on_pierced(body_rid)



func disable() -> void:
	instance.queue_free()
	super()





func get_transform_2D() -> Transform2D:
	return instance.transform

func set_transform_2D(t: Transform2D) -> void:
	instance.transform = t

func enable_collisions() -> void:
	for child: Node in area.get_children():
		if (child is CollisionShape2D):
			(child as CollisionShape2D).disabled = false

func disable_collisions() -> void:
	for child: Node in area.get_children():
		if (child is CollisionShape2D):
			(child as CollisionShape2D).disabled = true

func enable_graphics() -> void:
	instance.visible = true

func disable_graphics() -> void:
	instance.visible = false

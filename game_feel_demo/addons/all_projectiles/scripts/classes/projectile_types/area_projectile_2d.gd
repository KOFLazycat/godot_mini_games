class_name AreaProjectile2D
extends Projectile2D


## Visual texture of the projectile
var graphics: Texture2D;
## Half-size of the assigned texture for visual centering
var texture_size: Vector2;   

## Collision shape RID for physics queries
var shape: RID
## PhysicsServer2D area RID for collision detection
var area: RID

## Size of the projectile Collision in Pixels.
## The Collision radius of the projectile is affected by the size of the projectile itself.
var radius: int;
var _transform: Transform2D

## If true the projectile instance will be batch drawn
var can_be_drawn: bool


func _init(_resource: ProjectileBlueprint2D = null, _pi: PackedInfo = null) -> void:
	if (_resource == null):
		return
	super(_resource, _pi)

	# Maybe this can be in a "Physic stuff" class?
	graphics = _resource.texture;
	texture_size = _resource.texture.get_size()/2

	radius = _resource.radius;

	can_be_drawn = true
	# Until here

	if (_pi != null):
		assign(_pi)


func reset() -> void:
	_init(resource)




func assign(_pi : PackedInfo) -> void:
	super(_pi)

	shape = PhysicsServer2D.circle_shape_create()
	PhysicsServer2D.shape_set_data(shape, radius) 

	area = PhysicsServer2D.area_create()
	PhysicsServer2D.area_add_shape(area, shape)
	PhysicsServer2D.area_set_collision_layer(area, collision_layer)
	PhysicsServer2D.area_set_collision_mask(area, collision_mask)

	PhysicsServer2D.area_set_monitorable(area, area_monitoreable)
	PhysicsServer2D.area_set_area_monitor_callback(area, area_monitor_callback)
	PhysicsServer2D.area_set_monitor_callback(area, body_monitor_callback)

	PhysicsServer2D.area_set_space(area, _pi.world_2d)

	
	headstart += _pi.headstart
	if (_pi.start_method.is_valid()):
		on_start = _pi.start_method
	if (on_start.is_valid()):
		on_start.call(self)

	if (headstart > 0):
		move(headstart)
	if (look_at):
		transform = Transform2D(atan2(direction.y, direction.x), Vector2.ONE * size, 0.0, position)
	else:
		transform = Transform2D(0.0, Vector2.ONE * size, 0.0, position)
	
	if (wait_time > 0):
		disable_movement()
		disable_collisions()
		disable_graphics()


func activate_waiting_projectile() -> void:
	super()
	if (look_at):
		transform = Transform2D(atan2(direction.y, direction.x), Vector2.ONE * size, 0.0, position)
	else:
		transform = Transform2D(0.0, Vector2.ONE * size, 0.0, position)




func copy(base: Projectile2D, _pi: PackedInfo = null) -> void:
	super(base)

	if (base is AreaProjectile2D):
		var buffer: AreaProjectile2D = base as AreaProjectile2D

		graphics = buffer.graphics;
		texture_size = buffer.texture_size

		radius = buffer.radius;

		can_be_drawn = buffer.can_be_drawn
	
	if (_pi != null):
		assign(_pi)


func clone(_pi: PackedInfo = null) -> AreaProjectile2D:
	var proj: AreaProjectile2D = AreaProjectile2D.new()
	proj.copy(self)

	if (_pi != null):
		proj.assign(_pi)
	
	return proj




func area_monitor_callback(status: int, area_rid: RID, instance_id: int, area_shape_index: int, self_shape_index: int) -> void:
	if (status != PhysicsServer2D.AREA_BODY_ADDED):
		return
	
	var collider_node: Node2D = instance_from_id(instance_id)
	var target_node: Node2D = validate_target(collider_node)
	if (use_custom_area_collision):
		on_area_collision.call(self, area_rid, collider_node, target_node, area_shape_index, self_shape_index)
		return
	
	if !validate_collision(area_rid, target_node):
		return
	
	if target_node.has_method(on_hit_call):
		target_node.call(on_hit_call, self)
	on_pierced(area_rid)


func body_monitor_callback(status: int, body_rid: RID, instance_id: int, body_shape_index: int, self_shape_index: int) -> void:
	if (status != PhysicsServer2D.AREA_BODY_ADDED):
		return
	
	var collider_node: Node2D = instance_from_id(instance_id)
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
	PhysicsServer2D.free_rid(area)
	PhysicsServer2D.free_rid(shape)
	super()





func get_transform_2D() -> Transform2D:
	return _transform

func set_transform_2D(t: Transform2D) -> void:
	_transform = t
	PhysicsServer2D.area_set_transform(area, t)

func enable_collisions() -> void:
		PhysicsServer2D.area_set_shape_disabled(area, 0, false)

func disable_collisions() -> void:
		PhysicsServer2D.area_set_shape_disabled(area, 0, true)

func enable_graphics() -> void:
	can_be_drawn = true

func disable_graphics() -> void:
	can_be_drawn = false

func draw_on_canvas(canvas: CanvasItem) -> void:
	if !(can_be_drawn):
		return
	
	canvas.draw_set_transform_matrix(transform)
	canvas.draw_texture(graphics, -texture_size)

	if (ProjectileProcessor2D.visible_collisions):
		canvas.draw_circle(Vector2.ZERO, radius, Color(0.0, 0.6, 0.7, 0.42))
		canvas.draw_circle(Vector2.ZERO, radius, Color(0.0, 0.6, 0.7, 1), false)

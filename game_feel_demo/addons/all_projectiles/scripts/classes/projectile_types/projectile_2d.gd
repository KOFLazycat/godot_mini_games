class_name Projectile2D
extends RefCounted


signal projectile_requested(_projectile: Projectile2D, _position: Vector2, _destination: Vector2, _target: Node2D,
	move_method: Callable, start_method: Callable, collision_method: Callable, expired_method: Callable)
signal modifier_requested(_projectile_modifier: Projectile2DModifier)


const PROJ_CALLER_GROUP_NAME: StringName = "projectile_caller_group"
const PROJ_PROCESSOR_GROUP_NAME: StringName = "projectile_processor_group"
const PROJ_WRAPPER_GROUP_NAME: StringName = "projectile_wrapper_group"
const PROJ_STEP_TARGET_NAME: StringName = "step"


enum ProjectileType{
	AREA  = 0, 
	#PHYSIC = 1,
	INSTANTIATED = 2
}

enum ProjectileDirectionality{
	STRICT     = 0,
	ADAPTATIVE = 1,
	MODIFIABLE = 2
}

enum ProjectileSpread{
	NONE     = 0,
	LINEAR   = 1,
	ANGULAR  = 2,
	CIRCULAR = 3,
	EVENLY   = 4
}


## Shared physics space state for collision queries
static var current_space: PhysicsDirectSpaceState2D

## Variable state for projectile update validation
var is_active: bool
## Variable state for projectile lifetime & pierce validation
var is_expired: bool
## If true the projectile itself is connected with the ProjectileProcessor2D and can request and modify projectiles
var is_linked: bool
## Defines if the projectile can move at all
var can_move: bool


## Current projectile transform
var transform: Transform2D:
	get:
		return get_transform_2D()
	set(value):
		set_transform_2D(value)
## Current world position
var position: Vector2
## Current movement direction vector (normalized)
var direction: Vector2
## Fixed projectile destination
var destination: Vector2

## Fixed projectile blueprint 
var resource: ProjectileBlueprint2D
## Current manager (Null if not created by one)
var attack: Attack2D
## Current assigned target (Null if no target)
var target: Node2D


## Applied uniform Scale of the projectile
var size: float
## Remaining lifetime in seconds
var lifetime: float
## Current movement speed in pixels/second
var speed: float


## Physics layers of the projectile itself
var collision_layer: int
## Physics layers that can interact with the projectile
var collision_mask: int


## Name of the method that the projectile will try to call upon collision
var on_hit_call: StringName
## If true the projectile can interact with other areas
var area_monitoreable: bool

## Sum of health points that this projectile removes from targets on collision
var damage: int
## Remaining pierces before expiration
var pierce: int

## If true the projectile will look at the direction it travels
var look_at: bool


# Homing
## If true the projectile will actively follow its targets
var seeking: bool
## The projectile will actively seek targets on these Collision layers. Use it so your projectiles don't seek into walls
var seeking_mask: int
## Current rotation speed (in deg/sec) for seeking projectiles
var angular_speed: float
## Angular speed used after the first hit (Useful for ricochet behaviors)
var after_hit_angular_speed: float
## Radius of the circle cast shape searching for secondary targets on seeking projectiles
var cast_radius: float
## RID used to search for new targets on seeking projectiles 
var cast_shape: RID
## Parameters used to search for new targets on seeking shape casting
var query: PhysicsShapeQueryParameters2D


# Piercing
## If true the projectile will ignore all potential collisions in the way to hit its assigned target
var lock_to_target: bool
## If true the projectile will be able to hit already hit targets
var allow_rehit: bool
## Fixed time between consecutive collisions on identical targets
var rehit_cooldown: float
## Current wait time until next allowed rehit
var rehit_lifetime: float
## List of already hit RID's for piercing and rehit avoidance
var excluded_targets: Array[RID]


# Instances
## Amount of projectiles instantiated on creation
var instances: int
## Type of direction the projectile will take once instantiated
var proj_directionality: ProjectileDirectionality

## Creation identifier for projectiles with multiple instances (0 otherwise)
var index: int
## Time between each instance generation
var spawn_interval: float
## Time before the projectile enters in action
var wait_time: float

## Type of spread the projectile instances will have once instantiated
var proj_spread: ProjectileSpread
## Fixed amount of radial extension in which angular spread projectiles will be evenly distributed (in degrees)
var angular_spread: float
## Fixed amount of linear extension in which linear and angular projectiles will be evenly distributed (in pixels)
var vertical_spread: float
## If true linear and angular projectiles positions will be randomly spread
var randomize_positions: bool
## If true the spread of angular and circular projectiles will be randomized exclusively between its edges
var randomize_spread: bool

## Random amount of deviation the velocity vector of the projectile can differ once instantiated (in pixels)
var linear_deviation: float
## Current projectile direction deviation vector 
var deviation_vector: Vector2
## Movement advantage applied at the start (in secons)
var headstart: float


## Flag for first hit behavior tracking
var first_hit: bool 


# Callables
## Projectile custom start callback
var on_start: Callable

## If true the projectile uses a custom move method
var use_custom_movement: bool
## Projectile custom move callback
var on_move: Callable

## If true the projectile uses a custom area collision method
var use_custom_area_collision: bool
## Projectile custom area collision callback
var on_area_collision: Callable
## If true the projectile uses a custom body collision method
var use_custom_body_collision: bool
## Projectile custom body collision callback
var on_body_collision: Callable

## Projectile custom expiration callback
var on_expired: Callable


## This dictionary is shared between all projectiles created by its original blueprint.
## If you change its values, you will change them in all their projectiles.
var global_properties: Dictionary[StringName, Variant]
## This dictionary is independent in all projectiles created by its original blueprint.
## Modifying it will only affect this projectile instance.
var individual_properties: Dictionary[StringName, Variant]


## Name of the Secondary projectile on the Global Database to be instantiated once the main projectile runs out of pierce or lifetime
var on_expired_projectile_id: StringName


## If true the projectile_modifiers dictionary will be independent in all projectile instances requested by your ProjectileCaller2Ds.
## This may seem like the optimal behavior but it is recommended to set it to false.
var instance_projectile_modifiers: bool
## Dictionary of all modifiers affecting this projectile
var projectile_modifiers: Dictionary[StringName, Projectile2DModifier]




func add_modifier(modifier: Projectile2DModifier) -> bool:
	if (projectile_modifiers.has(modifier.name)):
		modifier.stacks = projectile_modifiers[modifier.name].stacks
		modifier.copies = projectile_modifiers[modifier.name].copies

	if !(modifier.validate_modifier(self)):
		return false

	projectile_modifiers[modifier.name] = modifier
	modifier.projectile = self

	modifier_requested.emit(modifier)
	return true



func remove_modifier(modifier_name: StringName) -> bool:
	if !(projectile_modifiers.has(modifier_name)):
		return false

	var stacks: int = projectile_modifiers[modifier_name].copies.size()
	for i: int in stacks:
		var element: TimedModifier = projectile_modifiers[modifier_name].copies.pop_back()
		element.exit()
	return true




func _init(_resource: ProjectileBlueprint2D = null, _pi: PackedInfo = null) -> void:
	if (_resource == null):
		return
	resource = _resource
	attack = null

	is_linked = false
	can_move = true
	
	size = _resource.size
	lifetime = _resource.lifetime
	speed = _resource.linear_speed

	collision_layer = _resource.collision_layer
	collision_mask = _resource.collision_mask

	on_hit_call = _resource.on_hit_call
	area_monitoreable = _resource.area_monitoreable

	damage = _resource.damage
	pierce = _resource.pierce

	look_at = _resource.look_at
 
	# Homing
	seeking = _resource.seeking
	seeking_mask = _resource.seeking_mask
	angular_speed = _resource.angular_speed
	after_hit_angular_speed = _resource.after_hit_angular_speed
	cast_radius = _resource.cast_radius

	# Pierce
	lock_to_target = _resource.lock_to_target
	allow_rehit = _resource.allow_rehit
	rehit_cooldown = _resource.rehit_cooldown
	rehit_lifetime = _resource.lifetime

	# Instances
	instances = _resource.instances
	proj_directionality = _resource.proj_directionality

	index = 0
	spawn_interval = _resource.spawn_interval
	wait_time = 0

	proj_spread = _resource.proj_spread
	angular_spread = _resource.angular_spread
	vertical_spread = _resource.vertical_spread
	randomize_positions = _resource.randomize_positions
	randomize_spread = _resource.randomize_spread

	linear_deviation = _resource.linear_deviation
	# headstart = _resource.headstart

	first_hit = true

	# Callables
	use_custom_movement = false
	use_custom_area_collision = false
	use_custom_body_collision = false

	# Custom Properties
	global_properties = _resource.global_properties
	if !(_resource.individual_properties.is_empty()):
		individual_properties = _resource.individual_properties.duplicate(true)
	
	# Secondary Projectiles
	on_expired_projectile_id = _resource.on_expired_projectile_id

	# Projectile Modifiers
	instance_projectile_modifiers = false
	projectile_modifiers = {}

	if (_pi != null):
		assign(_pi)


func reset() -> void:
	_init(resource)
	



func assign(_pi: PackedInfo) -> void:
	is_active = true
	is_expired = false
	
	# Individual values
	position = _pi.position
	destination = _pi.destination
	direction = _pi.direction
	target = _pi.target

	index = _pi.instance_id
	determine_initial_position()
	determine_initial_direction()

	if (_pi.override_wait_time): wait_time = 0
	elif (instances > 0 && index == 0): wait_time = 0.0001
	else: wait_time = index * spawn_interval
	# else: 
	# 	wait_time = index * spawn_interval
	# 	if (instances > 0 && index == 0):
	# 		wait_time = 0.0001

	deviation_vector = Vector2(randf_range(-linear_deviation, linear_deviation), randf_range(-linear_deviation, linear_deviation))

	cast_shape = PhysicsServer2D.circle_shape_create()
	PhysicsServer2D.shape_set_data(cast_shape, cast_radius)
	if (query == null):
		query = PhysicsShapeQueryParameters2D.new()
	query.collide_with_areas = area_monitoreable
	query.collision_mask = seeking_mask
	query.shape_rid = cast_shape

	# Custom Methods
	if (_pi.move_method.is_valid()):
		on_move = _pi.move_method
		use_custom_movement = true
	
	if (_pi.collision_method.is_valid()):
		on_area_collision = _pi.collision_method
		on_body_collision = _pi.collision_method
		use_custom_area_collision = true
		use_custom_body_collision = true
	
	if (_pi.expired_method.is_valid()):
		on_expired = _pi.expired_method




func activate_waiting_projectile() -> void:
	if (attack != null && attack.caller != null):
		if (attack.override_position):
			position = attack.caller.global_position + attack.attack_offset
		if (attack.override_direction):
			destination = position + attack.caller.global_transform.x

	# determine_initial_position()
	# determine_initial_direction()

	enable_graphics()
	enable_collisions()
	enable_movement()
	# InstancedProjectile2D.current_scene.get_tree().process_frame.connect(enable_movement, CONNECT_ONE_SHOT)




func copy(base: Projectile2D, _pi: PackedInfo = null) -> void:
	resource = base.resource
	attack = base.attack

	is_linked = base.is_linked
	can_move = base.can_move

	size = base.size
	lifetime = base.lifetime
	speed = base.speed

	collision_layer = base.collision_layer
	collision_mask = base.collision_mask

	on_hit_call = base.on_hit_call
	area_monitoreable = base.area_monitoreable

	damage = base.damage
	pierce = base.pierce

	look_at = base.look_at

	# Homing
	seeking = base.seeking
	seeking_mask = base.seeking_mask
	angular_speed = base.angular_speed
	after_hit_angular_speed = base.after_hit_angular_speed
	cast_radius = base.cast_radius

	# Pierce
	lock_to_target = base.lock_to_target
	allow_rehit = base.allow_rehit
	rehit_cooldown = base.rehit_cooldown
	rehit_lifetime = base.rehit_lifetime

	# Instances
	instances = base.instances
	proj_directionality = base.proj_directionality

	index = base.index
	spawn_interval = base.spawn_interval
	wait_time = base.wait_time

	proj_spread = base.proj_spread
	angular_spread = base.angular_spread
	vertical_spread = base.vertical_spread
	randomize_positions = base.randomize_positions
	randomize_spread = base.randomize_spread

	linear_deviation = base.linear_deviation
	deviation_vector = base.deviation_vector
	headstart = base.headstart

	first_hit = base.first_hit

	# Callables
	use_custom_movement = base.use_custom_movement
	use_custom_area_collision = base.use_custom_area_collision
	use_custom_body_collision = base.use_custom_body_collision

	on_start = base.on_start
	on_move = base.on_move
	on_area_collision = base.on_area_collision
	on_body_collision = base.on_body_collision
	on_expired = base.on_expired
	
	# User defined properties
	global_properties = base.global_properties
	if !(base.individual_properties.is_empty()):
		individual_properties = base.individual_properties.duplicate(true)

	# Secondary Projectiles
	on_expired_projectile_id = base.on_expired_projectile_id

	# Projectile Modifiers
	instance_projectile_modifiers = base.instance_projectile_modifiers
	if (instance_projectile_modifiers):
		projectile_modifiers = base.projectile_modifiers.duplicate(true)
	else:
		projectile_modifiers = base.projectile_modifiers



func clone(_pi: PackedInfo = null) -> Projectile2D:
	var proj: Projectile2D = Projectile2D.new()
	proj.copy(self)

	if (_pi != null):
		proj.assign(_pi)
	
	return proj



func link_to_processor(processor_instance: ProjectileProcessor2D) -> void:
	projectile_requested.connect(processor_instance.add_projectiles_resource)
	modifier_requested.connect(processor_instance.add_modifier)
	is_linked = true




func set_on_start(method: Callable) -> Projectile2D:
	on_start = method
	return self

func set_on_move(method: Callable) -> Projectile2D:
	if (method.is_valid()):
		on_move = method
		use_custom_movement = true
	return self

func set_on_collision(method: Callable) -> Projectile2D:
	if (method.is_valid()):
		on_area_collision = method
		on_body_collision = method
		use_custom_area_collision = true
		use_custom_body_collision = true
	return self

func set_on_area_collision(method: Callable) -> Projectile2D:
	if (method.is_valid()):
		on_area_collision = method
		use_custom_area_collision = true
	return self

func set_on_body_collision(method: Callable) -> Projectile2D:
	if (method.is_valid()):
		on_body_collision = method
		use_custom_body_collision = true
	return self

func set_on_expired(method: Callable) -> Projectile2D:
	on_expired = method
	return self

func set_property(property: StringName, value: Variant) -> Projectile2D:
	set(property, value)
	return self

func add_global_property(property: StringName, value: Variant) -> Projectile2D:
	global_properties[property] = value
	return self

func add_individual_property(property: StringName, value: Variant) -> Projectile2D:
	individual_properties[property] = value
	return self




func update_lifetime(delta: float) -> bool:
	if (is_expired):
		expire()
		return false
	
	if (wait_time > 0):
		wait_time -= delta
		if (wait_time <= 0):
			activate_waiting_projectile()
			move(wait_time * -1)
		return true
	
	rehit_lifetime -= delta
	lifetime -= delta
	if lifetime < 0.0:
		is_expired = true
		expire()
		return false
	return true



func move(delta: float) -> void:
	if !(can_move):
		return

	var angle: float

	if (seeking):
		if (target != null):
			angle = seek_target(delta)
		else:
			try_retarget()


	if (use_custom_movement) and on_move.is_valid():
		var dir: Vector2 = on_move.call(self, delta)
		position += dir * speed * delta
		angle = transform.x.angle_to(dir)
	else:
		position += direction * speed * delta
	

	if (look_at):
		transform = transform.rotated(angle)
	transform.origin = position



func disable() -> void:
	PhysicsServer2D.free_rid(cast_shape)
	excluded_targets.clear()
	query.exclude = excluded_targets
	individual_properties.clear()
	is_active = false
	attack = null






func seek_target(_delta: float) -> float:
	var clamped_angle: float = clampf(direction.angle_to((target.global_position - position).normalized()), 
							   -deg_to_rad(angular_speed * _delta), deg_to_rad(angular_speed * _delta))
	
	direction = direction.rotated(clamped_angle)

	return clamped_angle


func try_retarget() -> void:
	# if (current_space == null):		# Redundant??
	# 	return
	query.transform = Transform2D(0.0, transform.origin)

	var result: Dictionary = current_space.get_rest_info(query)
	if (result):
		var id: int = result.collider_id
		var collider: CollisionObject2D = instance_from_id(id)
		target = validate_target(collider)






func validate_collision(colliding_rid: RID, colliding_node: Node) -> bool:
	if (is_expired):
		return false

	# While "target != null" isn't necessary, the resulting beheaviour will be prefered by the common user
	if (lock_to_target && target != null):
		if (target != colliding_node):
			return false

	if (excluded_targets.has(colliding_rid)):
		return false
	
	return true


func validate_target(collider: Node) -> Node:
	if (collider.is_in_group(PROJ_STEP_TARGET_NAME)):
		return validate_target(collider.get_parent())
	else:
		return collider



func on_pierced(pierced_rid: RID) -> void:
	if (first_hit):
		angular_speed = after_hit_angular_speed
		rehit_lifetime = rehit_cooldown
		first_hit = false

	if (allow_rehit):
		if (rehit_lifetime < 0):
			excluded_targets.clear()
			rehit_lifetime = rehit_cooldown

	excluded_targets.append(pierced_rid)
	query.exclude = excluded_targets
	target = null

	pierce -= 1;
	if (pierce < 1):
		is_expired = true


func expire() -> void:
	if !(on_expired_projectile_id.is_empty()):
		var proj: Projectile2D = APDatabase.get_projectile_2d(on_expired_projectile_id, false)
		if (proj != null):
			request_projectile(proj, position, position + transform.x)
	
	if (on_expired.is_valid()):
		on_expired.call(self)


func request_projectile(_projectile: Projectile2D, _position: Vector2, _destination: Vector2, _target: Node2D = null,
	 _move_method: Callable = Callable(), _start_method: Callable = Callable(), _collision_method: Callable = Callable(),
	 _expired_method: Callable = Callable()) -> void:

	projectile_requested.emit(_projectile, _position, _destination, _target,
		_move_method, _start_method, _collision_method, _expired_method)





func get_transform_2D() -> Transform2D:
	return Transform2D()

func set_transform_2D(_transform: Transform2D) -> void:
	pass

func enable_movement() -> void:
	can_move = true

func disable_movement() -> void:
	can_move = false

func enable_collisions() -> void:
	pass

func disable_collisions() -> void:
	pass

func enable_graphics() -> void:
	pass

func disable_graphics() -> void:
	pass

func draw_on_canvas(_canvas: CanvasItem) -> void:
	pass

func determine_initial_position() -> void:
	if (proj_directionality == Projectile2D.ProjectileDirectionality.MODIFIABLE):
		direction = (destination - position).normalized()
	else:
		direction = (destination - Vector2(position.x, destination.y)).normalized()
	
	if (proj_directionality == ProjectileDirectionality.ADAPTATIVE):
		position = Vector2(position.x, destination.y)
	
	var magnitude: float
	if (proj_spread == ProjectileSpread.LINEAR || proj_spread == ProjectileSpread.ANGULAR) && instances > 1:
		if (randomize_positions):
			magnitude = randf_range(-(vertical_spread / 2), vertical_spread / 2)
		else:
			var separation: float = vertical_spread / (instances - 1)
			magnitude = (vertical_spread / 2) - (index * separation)
	
	position = (direction.normalized().orthogonal() * magnitude) + position

func determine_initial_direction() -> void:
	var angle: float
	if (proj_spread == ProjectileSpread.ANGULAR):
		if (instances > 1):
			if (randomize_spread):
				angle = randf_range((-angular_spread / 2), (angular_spread / 2))
			else:
				var separation: float = angular_spread / (instances - 1)
				angle = -(angular_spread / 2) + (index * separation)
	if (proj_spread == ProjectileSpread.CIRCULAR):
		if (instances > 1):
			if (randomize_spread):
				angle = randf_range(0, 359)
			else:
				var separation: float = 360.0 / instances
				angle = index * separation
	
	if (angle != 0):
		direction = direction.rotated(deg_to_rad(angle))
		# direction = Vector2(direction.x * cos(angle) - direction.y * sin(angle), direction.x * sin(angle) + direction.y * cos(angle))
	
	if (speed != 0):
		direction += (deviation_vector / speed)

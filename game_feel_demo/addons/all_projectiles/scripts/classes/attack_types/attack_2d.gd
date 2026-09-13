class_name Attack2D
extends RefCounted


signal projectile_requested(_projectile: Projectile2D, _position: Vector2, _destination: Vector2, _target: Node2D,
	move_method: Callable, start_method: Callable, collision_method: Callable, expired_method: Callable)
signal modifier_requested(_attack_modifier: Attack2DModifier)
signal direct_projectile_request(_projectile: Projectile2D, _pi: PackedInfo)


enum AttackState{
	ATTACK_CHARGE 		= 0,
	ATTACK_ANTICIPATE 	= 1,
	ATTACK_MAIN 		= 2,
	ATTACK_RECOVERY 	= 3
}

enum AttackChargeType{
	CONTINUOUS = 0,
	DISCRETE  = 1,
	MANDATORY = 2
}

enum AttackChargeTrigger{
	ON_READY   = 0,
	ON_RELEASE = 1
}

enum InstancesSpawnType{
	ALL_AT_ONCE	= 0,
	ONE_BY_ONE	= 1
}

enum ExecutionType{
	MANDATORY 	 = 0,
	AS_REQUESTED = 1
}

enum OnInterruptedExecutionContinuation{
	REFRESH_SHOTS_AND_START_FROM_ZERO	= 0,
	CONTINUE_FROM_REMAINING_SHOTS		= 1,
	CONTINUE_BUT_NOT_REFRESH			= 2,
}


## Variable state for weapon update validation
var is_active: bool
## If true the attack itself is connected with the ProjectileProcessor2D and can request projectiles and modify attacks
var is_linked: bool


## Current phase of the attack lifecycle.
## Determines which callbacks and methods are executed.
var current_state: AttackState
## Remaining lifetime of the current attack phase in seconds
var current_state_lifetime: float
## Remnant for attacks with lifetimes below framerate.
## Only available on ONE_BY_ONE executions.
var sub_frame_excess: float


## Fixed attack blueprint 
var resource: AttackBlueprint2D
## Entity that initiated the attack.
## Used for flexible position and direction references.
var caller: ProjectileManager2D
## Reference to projectile requested
var projectile: Projectile2D
## Projectile spawn parameters
var pi: PackedInfo


## If true the original caller has requested the creation of more projectiles on this frame
var requested_interaction: bool
## If true the original caller has requested new projectiles on every frame without a break
var is_under_uninterrupted_request: bool
## Collective time accumulation for DISCRETE charged attacks
var accumulated_charge: float


## Duration of the charge phase in seconds
var attack_charge_time: float
## Duration of the anticipation phase in seconds
var attack_anticipate_time: float
## Duration of the main attack phase in seconds
var attack_duration_time: float
## Duration of the recovery phase in seconds
var attack_recovery_time: float
## Minimum duration for attack phases.
## Attack phases below this duration will be skipped.
var margin: float

## Added distance to projectile position on creation
var attack_offset: Vector2
## If true the attack ignores the given spawn positions and uses its own ProjectileManager node global position instead
var override_position: bool
## If true the attack will constantly update its projectile direction even if its execution request was unsuccessful
var override_direction: bool

## Charge accumulation tracking method
var charge_type: Attack2D.AttackChargeType
## Charge completion condition 
var charge_trigger: Attack2D.AttackChargeTrigger


## Fixed Projectile instances on request
var instances: int
## Current attack repetitions until expiration.
## Only available on ONE_BY_ONE executions.
var remaining_shots: int
## If true the attack can reload its remaining shoots
var can_reload: bool

## Determines the spawn type of projectiles with multiple instances timed spawn intervals:
## -> ALL_AT_ONCE: All projectile instances spawn simultaneously.
## -> ONE_BY_ONE: Projectile instances spawn sequentially with delays.
var spawn_type: InstancesSpawnType
## ONE_BY_ONE attacks continuation condition
var execution_type: ExecutionType
## ONE_BY_ONE attacks behavior when resuming interrupted attacks
var continuation_type: OnInterruptedExecutionContinuation
## If true overrides the attack_duration_time property with its assign projectile spawn_interval value
var override_attack_duration: bool


## This dictionary is shared between all attacks created by its original blueprint.
## If you change its values, you will change them in all their attacks.
var global_properties: Dictionary[StringName, Variant]
## This dictionary is independent in all attacks created by its original blueprint.
## Modifying it will only affect this attack instance.
var individual_properties: Dictionary[StringName, Variant]


## Attack custom start callback
var on_start: Callable

## Attack custom charge phase enter callback
var on_charge_enter: Callable
## Attack custom charge phase update callback
var on_charge_update: Callable
## Attack custom charge phase exit callback
var on_charge_exit: Callable
## Attack custom anticipate phase enter callback
var on_anticipate_enter: Callable
## Attack custom anticipate phase update callback
var on_anticipate_update: Callable
## Attack custom anticipate phase exit callback
var on_anticipate_exit: Callable
## Attack custom main phase enter callback
var on_main_enter: Callable
## Attack custom main phase update callback
var on_main_update: Callable
## Attack custom main phase exit callback
var on_main_exit: Callable
## Attack custom recovery phase enter callback
var on_recovery_enter: Callable
## Attack custom recovery phase update callback
var on_recovery_update: Callable
## Attack custom recovery phase exit callback
var on_recovery_exit: Callable

## Attack custom completion callback
var on_completed: Callable


## If true the attack_modifiers dictionary will be independent in all attack copies made by your ProjectileManager2Ds instead of being shared among all of them.
## This may seem like the optimal behavior but it is recommended to set it to false.
var instance_attack_modifiers: bool
## Dictionary of all modifiers affecting this attack
var attack_modifiers: Dictionary[StringName, Attack2DModifier]




func add_modifier(modifier: Attack2DModifier) -> bool:
	if (attack_modifiers.has(modifier.name)):
		modifier.stacks = attack_modifiers[modifier.name].stacks
		modifier.copies = attack_modifiers[modifier.name].copies

	if !(modifier.validate_modifier(self)):
		return false

	attack_modifiers[modifier.name] = modifier
	modifier.attack = self

	modifier_requested.emit(modifier)
	return true



func remove_modifier(modifier_name: StringName) -> bool:
	if !(attack_modifiers.has(modifier_name)):
		return false

	var stacks: int = attack_modifiers[modifier_name].copies.size()
	for i: int in stacks:
		var element: TimedModifier = attack_modifiers[modifier_name].copies.pop_back()
		element.exit()
	return true




func _init(_resource: AttackBlueprint2D = null, proj_caller: Node2D = null) -> void:
	if (_resource == null):
		return
	is_active = false
	is_linked = false

	current_state = AttackState.ATTACK_CHARGE
	current_state_lifetime = -1
	sub_frame_excess = 0

	resource = _resource
	caller = proj_caller
	projectile = null
	if (pi == null):
		pi = PackedInfo.new()

	requested_interaction = false
	accumulated_charge = 0

	attack_charge_time = _resource.attack_charge_time
	attack_anticipate_time = _resource.attack_anticipate_time
	attack_duration_time = _resource.attack_duration_time
	attack_recovery_time = _resource.attack_recovery_time
	margin = 0

	attack_offset = _resource.attack_offset
	override_position = _resource.override_position
	override_direction = _resource.override_direction

	charge_type = _resource.charge_type
	charge_trigger = _resource.charge_trigger

	instances = 0
	remaining_shots = 0
	can_reload = true

	spawn_type = _resource.spawn_type
	execution_type = _resource.execution_type
	continuation_type = _resource.continuation_type
	override_attack_duration = _resource.override_attack_duration

	global_properties = _resource.global_properties
	if !(_resource.individual_properties.is_empty()):
		individual_properties = _resource.individual_properties.duplicate(true)
	
	instance_attack_modifiers = false
	attack_modifiers = {}


func reset() -> void:
	_init(resource)




func assing(_projectile: Projectile2D, _caller: ProjectileManager2D, _pi: PackedInfo = pi) -> void:
	if (projectile == null):
		projectile = _projectile
	caller = _caller
	pi = _pi


func copy(base: Attack2D) -> void:
	is_active = base.is_active
	is_linked = base.is_linked

	current_state = base.current_state
	current_state_lifetime = base.current_state_lifetime
	sub_frame_excess = base.sub_frame_excess

	resource = base.resource
	caller = base.caller
	projectile = base.projectile
	pi = base.pi.clone()

	# External interaction
	requested_interaction = base.requested_interaction
	is_under_uninterrupted_request = base.is_under_uninterrupted_request
	accumulated_charge = base.accumulated_charge

	# Timings
	attack_charge_time = base.attack_charge_time
	attack_anticipate_time = base.attack_anticipate_time
	attack_duration_time = base.attack_duration_time
	attack_recovery_time = base.attack_recovery_time
	margin = base.margin

	attack_offset = base.attack_offset
	override_position = base.override_position
	override_direction = base.override_direction

	charge_type = base.charge_type
	charge_trigger = base.charge_trigger

	instances = base.instances
	remaining_shots = base.remaining_shots
	can_reload = base.can_reload

	spawn_type = base.spawn_type
	execution_type = base.execution_type
	continuation_type = base.continuation_type
	override_attack_duration = base.override_attack_duration

	# User defined properties
	global_properties = base.global_properties
	if !(base.individual_properties.is_empty()):
		individual_properties = base.individual_properties.duplicate(true)

	# Callables
	on_start = base.on_start

	on_charge_enter = base.on_charge_enter
	on_charge_update = base.on_charge_update
	on_charge_exit = base.on_charge_exit
	on_anticipate_enter = base.on_anticipate_enter
	on_anticipate_update = base.on_anticipate_update
	on_anticipate_exit = base.on_anticipate_exit
	on_main_enter = base.on_main_enter
	on_main_update = base.on_main_update
	on_main_exit = base.on_main_exit
	on_recovery_enter = base.on_recovery_enter
	on_recovery_update = base.on_recovery_update
	on_recovery_exit = base.on_recovery_exit

	on_completed = base.on_completed

	instance_attack_modifiers = base.instance_attack_modifiers
	if (instance_attack_modifiers):
		attack_modifiers = base.attack_modifiers.duplicate(true)
	else:
		attack_modifiers = base.attack_modifiers



func clone() -> Attack2D:
	var attack: Attack2D = Attack2D.new()
	attack.copy(self)

	return attack




func link_to_processor(processor_instance: ProjectileProcessor2D) -> void:
	# 先断开所有连接，确保重新连接
	if projectile_requested.is_connected(processor_instance.add_projectiles_resource):
		projectile_requested.disconnect(processor_instance.add_projectiles_resource)
	if modifier_requested.is_connected(processor_instance.add_modifier):
		modifier_requested.disconnect(processor_instance.add_modifier)
	if direct_projectile_request.is_connected(processor_instance._add_projectile):
		direct_projectile_request.disconnect(processor_instance._add_projectile)

	# 重新连接信号
	projectile_requested.connect(processor_instance.add_projectiles_resource)
	modifier_requested.connect(processor_instance.add_modifier)
	direct_projectile_request.connect(processor_instance._add_projectile)
	is_linked = true


func start() -> void:
	if !(validate_attack()):
		is_active = false
		return
	
	if (spawn_type == InstancesSpawnType.ONE_BY_ONE):
		if (continuation_type == OnInterruptedExecutionContinuation.REFRESH_SHOTS_AND_START_FROM_ZERO || remaining_shots <= 0):
			if (can_reload):
				instances = projectile.instances
				remaining_shots = projectile.instances
			else:
				is_active = false;
				return
		pi.override_wait_time = true

		if (override_attack_duration):
			attack_duration_time = projectile.spawn_interval

	is_active = true
	requested_interaction = true
	is_under_uninterrupted_request = true
	sub_frame_excess = 0

	if (on_start.is_valid()): on_start.call(self)
	change_state(AttackState.ATTACK_CHARGE)

	if (attack_duration_time <= 0):
		spawn_type = InstancesSpawnType.ALL_AT_ONCE
		attack_duration_time = resource.attack_duration_time


func validate_attack() -> bool:
	return is_linked && projectile != null


func disable() -> void:
	if on_completed.is_valid(): on_completed.call(self)
	projectile = null
	is_active = false


func reload(proj: Projectile2D) -> void:
	can_reload = true
	projectile = proj
	if (projectile != null):
		instances = projectile.instances
	remaining_shots = instances




func set_property(property: StringName, value: Variant) -> Attack2D:
	set(property, value)
	return self

func add_global_property(property: StringName, value: Variant) -> Attack2D:
	global_properties[property] = value
	return self

func add_individual_property(property: StringName, value: Variant) -> Attack2D:
	individual_properties[property] = value
	return self

func set_on_charge_enter(method: Callable) -> Attack2D:
	on_charge_enter = method
	return self
func set_on_charge_update(method: Callable) -> Attack2D:
	on_charge_update = method
	return self
func set_on_charge_exit(method: Callable) -> Attack2D:
	on_charge_exit = method
	return self
func set_on_anticipate_enter(method: Callable) -> Attack2D:
	on_anticipate_enter = method
	return self
func set_on_anticipate_update(method: Callable) -> Attack2D:
	on_anticipate_update = method
	return self
func set_on_anticipate_exit(method: Callable) -> Attack2D:
	on_anticipate_exit = method
	return self
func set_on_main_enter(method: Callable) -> Attack2D:
	on_main_enter = method
	return self
func set_on_main_update(method: Callable) -> Attack2D:
	on_main_update = method
	return self
func set_on_main_exit(method: Callable) -> Attack2D:
	on_main_exit = method
	return self
func set_on_recovery_enter(method: Callable) -> Attack2D:
	on_recovery_enter = method
	return self
func set_on_recovery_update(method: Callable) -> Attack2D:
	on_recovery_update = method
	return self
func set_on_recovery_exit(method: Callable) -> Attack2D:
	on_recovery_exit = method
	return self

func set_on_start(method: Callable) -> Attack2D:
	on_start = method
	return self
func set_on_completed(method: Callable) -> Attack2D:
	on_completed = method
	return self

func get_current_state_duration() -> float:
	match current_state:
		AttackState.ATTACK_CHARGE:
			return attack_charge_time
		AttackState.ATTACK_ANTICIPATE:
			return attack_anticipate_time
		AttackState.ATTACK_MAIN:
			return attack_duration_time
		AttackState.ATTACK_RECOVERY:
			return attack_recovery_time
		_:
			return -1




func is_charge_completed() -> bool:
	if !(is_active):
		return false
	if (charge_trigger == AttackChargeTrigger.ON_READY):
		return true
	return !requested_interaction


func update(_delta: float) -> bool:
	if !(requested_interaction):
		is_under_uninterrupted_request = false
	match current_state:
		AttackState.ATTACK_CHARGE:
			if on_charge_update.is_valid(): on_charge_update.call(self, _delta)
			else: charge_update(_delta)
		AttackState.ATTACK_ANTICIPATE:
			if on_anticipate_update.is_valid(): on_anticipate_update.call(self, _delta)
			else: anticipate_update(_delta)
		AttackState.ATTACK_MAIN:
			if on_main_update.is_valid(): on_main_update.call(self, _delta)
			else: main_update(_delta)
		AttackState.ATTACK_RECOVERY:
			if on_recovery_update.is_valid(): on_recovery_update.call(self, _delta)
			else: recovery_update(_delta)
	requested_interaction = false
	return is_active


func update_lifetime(_delta: float, local_margin: float = 0) -> bool:
	current_state_lifetime -= _delta
	if (current_state_lifetime < local_margin):
		return false
	return true




func change_state(state: AttackState) -> bool:
	if (state > AttackState.ATTACK_RECOVERY || !is_active):
		disable()
		return false

	var state_duration: float
	current_state = state
	match current_state:
		AttackState.ATTACK_CHARGE:
			state_duration = attack_charge_time
		AttackState.ATTACK_ANTICIPATE:
			state_duration = attack_anticipate_time
		AttackState.ATTACK_MAIN:
			state_duration = attack_duration_time
		AttackState.ATTACK_RECOVERY:
			state_duration = attack_recovery_time
	
	if (state_duration <= margin):
		return change_state(current_state + 1)
	
	match current_state:
		AttackState.ATTACK_CHARGE:
			if on_charge_enter.is_valid(): on_charge_enter.call(self)
			else: charge_enter()
		AttackState.ATTACK_ANTICIPATE:
			if on_anticipate_enter.is_valid(): on_anticipate_enter.call(self)
			else: anticipate_enter()
		AttackState.ATTACK_MAIN:
			if on_main_enter.is_valid(): on_main_enter.call(self)
			else: main_enter()
		AttackState.ATTACK_RECOVERY:
			if on_recovery_enter.is_valid(): on_recovery_enter.call(self)
			else: recovery_enter()

	return true




func charge_enter() -> void:
	current_state_lifetime = attack_charge_time
	if (charge_type == AttackChargeType.DISCRETE):
		current_state_lifetime -= accumulated_charge

func charge_update(_delta: float) -> void:
	if (charge_type != AttackChargeType.MANDATORY):
		accumulated_charge += _delta
		if !(requested_interaction):
			if (charge_type == AttackChargeType.CONTINUOUS):
				accumulated_charge = 0
			if (current_state_lifetime > 0):
				disable()
	if (!update_lifetime(_delta) && is_charge_completed()):
		if on_charge_exit.is_valid(): on_charge_exit.call(self)
		else: charge_exit()

func charge_exit() -> void:
	accumulated_charge = 0
	change_state(AttackState.ATTACK_ANTICIPATE)



func anticipate_enter() -> void:
	current_state_lifetime = attack_anticipate_time

func anticipate_update(_delta: float) -> void:
	if !(update_lifetime(_delta)):
		if on_anticipate_exit.is_valid(): on_anticipate_exit.call(self)
		else: anticipate_exit()

func anticipate_exit() -> void:
	change_state(AttackState.ATTACK_MAIN)



func main_enter() -> void:
	current_state_lifetime = attack_duration_time

	if (spawn_type == InstancesSpawnType.ALL_AT_ONCE):
		if (override_position && caller != null):
			pi.position = caller.global_position
		pi.position += attack_offset
		
		if (override_direction):
			pi.destination = pi.position + caller.global_transform.x

		request_projectile()
	else:
		pi.instance_id = instances - remaining_shots
		pi.world_2d = ProjectileProcessor2D.world_RID


func main_update(_delta: float) -> void:
	if (spawn_type == InstancesSpawnType.ALL_AT_ONCE):
		if !(update_lifetime(_delta)):
			if on_main_exit.is_valid(): on_main_exit.call(self)
			else: main_exit()
	else:
		var sum: float = sub_frame_excess
		var loops: int = 0
		while (sum < _delta && loops < 50 && current_state == AttackState.ATTACK_MAIN):
			sum += attack_duration_time
			pi.headstart = _delta - sum

			if (override_position && caller != null):
				pi.position = caller.global_position
			pi.position += attack_offset
			
			if (override_direction):
				pi.destination = pi.position + caller.global_transform.x
				
			direct_request()
			remaining_shots -= 1

			if on_main_exit.is_valid(): on_main_exit.call(self)
			else: main_exit()
			loops += 1
		sub_frame_excess = (_delta - sum) * -1
		

func main_exit() -> void:
	if (spawn_type == InstancesSpawnType.ALL_AT_ONCE):
		change_state(AttackState.ATTACK_RECOVERY)
	else:
		if (execution_type == ExecutionType.AS_REQUESTED):
			if !(is_under_uninterrupted_request):
				change_state(AttackState.ATTACK_RECOVERY)
		
		if (remaining_shots > 0):
			change_state(AttackState.ATTACK_MAIN)
		else:
			change_state(AttackState.ATTACK_RECOVERY)
			if (continuation_type == OnInterruptedExecutionContinuation.CONTINUE_BUT_NOT_REFRESH):
				can_reload = false



func recovery_enter() -> void:
	current_state_lifetime = attack_recovery_time

func recovery_update(_delta: float) -> void:
	if !(update_lifetime(_delta)):
		if on_recovery_exit.is_valid(): on_recovery_exit.call(self)
		else: recovery_exit()

func recovery_exit() -> void:
	disable()



func request_projectile(_projectile: Projectile2D = projectile) -> void:
	projectile_requested.emit(_projectile, pi.position, pi.destination, pi.target,
		pi.move_method, pi.start_method, pi.collision_method, pi.expired_method)

func direct_request(_projectile: Projectile2D = projectile, _pi: PackedInfo = pi) -> void:
	direct_projectile_request.emit(_projectile, _pi)

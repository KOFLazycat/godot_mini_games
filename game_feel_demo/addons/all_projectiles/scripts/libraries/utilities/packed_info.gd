class_name PackedInfo
extends RefCounted


## Projectile start position
var position: Vector2
## Initial projectile movement direction
var direction: Vector2

## Original destination the projectile is being headed.
## Used for non-seeking projectiles with fixed destinations.
var destination: Vector2
## The target node that projectiles should home-in.
## Required for seeking projectiles with target-tracking behavior.
var target: Node2D

## Individual instance identifier for projectiles with multiple instances
var instance_id: int

# Maybe just made it static
## The physics server world RID for non-instanced projectiles
var world_2d: RID

## Projectile custom movement callback
var move_method: Callable
## Projectile custom initialization callback
var start_method: Callable
## Projectile custom collision handling callback
var collision_method: Callable
## Projectile custom expiration callback
var expired_method: Callable

## Flag to bypass built-in wait time behavior.
## Used for complex attack patterns with custom timing.
var override_wait_time: bool
## Projectile initial movement advantage.
## Simulates projectiles that have been already moving before creation.
var headstart: float


func _init() -> void:
	position = Vector2.ZERO
	direction = Vector2.ZERO
	destination = Vector2.ZERO
	target = null

	instance_id = 1

	world_2d = RID()

	move_method = Callable()
	start_method = Callable()
	collision_method = Callable()
	expired_method = Callable()

	override_wait_time = false
	headstart = 0


func reassing_all(_position: Vector2, _direction: Vector2, _destination: Vector2, _target: Node2D, _instance_id: int, 
	_world_2d: RID, _move_method: Callable, _start_method: Callable, _collision_method: Callable,
	_expired_method: Callable, _override_wait_time: bool = false, _headstart: float = 0) -> void:

	position = _position
	direction = _direction
	destination = _destination
	target = _target

	instance_id = _instance_id
	world_2d = _world_2d

	move_method = _move_method
	start_method = _start_method
	collision_method = _collision_method
	expired_method = _expired_method

	override_wait_time = _override_wait_time
	headstart = _headstart


func reassing_simple(_position: Vector2, _destination: Vector2, _target: Node2D, _move_method: Callable, 
	_start_method: Callable, _collision_method: Callable, _expired_method: Callable) -> void:

	position = _position
	destination = _destination
	target = _target

	move_method = _move_method
	start_method = _start_method
	collision_method = _collision_method
	expired_method = _expired_method


func clone() -> PackedInfo:
	var pi: PackedInfo = PackedInfo.new()
	pi.copy(self)

	return pi


func copy(base: PackedInfo) -> void:
	position = base.position
	direction = base.direction
	destination = base.destination
	target = base.target

	instance_id = base.instance_id
	world_2d = base.world_2d

	move_method = base.move_method
	start_method = base.start_method
	collision_method = base.collision_method
	expired_method = base.expired_method

	override_wait_time = base.override_wait_time
	headstart = base.headstart

class_name TimedModifier
extends RefCounted


## Variable state for modifier update validation
var is_active: bool

## Unique identifier. 
## Used to distinguish between different modifiers regardless of type.
var name: StringName
## Remaining lifetime in seconds
var lifetime: float
## Original modifier duration in seconds
var duration: float

## Object currently being affected by this modifier
var target: RefCounted

## Current number of times this modifier has been applied to the same target
var stacks: int
## Stacking instances of this modifier
var copies: Array[TimedModifier]

## Modifier custom application callback
var on_enter: Callable
## Modifier custom expiration callback
var on_exit: Callable

## If true, the modifier never expires and remains active indefinitely
var is_permanent: bool
## If true, the modifier uses a custom update method
var use_custom_update_method: bool
## Modifier custom update callback
var on_update: Callable

## Modifier custom validation callback
var on_validation: Callable

## This dictionary is shared between all cloned instances.
## If you change its values, you will change them in all cloned modifiers.
var global_properties: Dictionary[StringName, Variant]
## This dictionary is independent between all cloned instances.
## Modifying it will only affect this modifier instance.
var individual_properties: Dictionary[StringName, Variant]




func _init(_name: StringName = StringName(), _duration: float = 1.0, _on_enter: Callable = Callable(), _on_exit: Callable = Callable(),
	_on_update: Callable = Callable(), _on_validation: Callable = Callable()) -> void:

	if (_name.is_empty()):
		return

	is_active = false
	
	name = _name
	lifetime = _duration
	duration = _duration

	stacks = 0
	copies = []

	on_enter = _on_enter
	on_exit = _on_exit

	on_update = _on_update
	
	use_custom_update_method = false
	if (on_update.is_valid()):
		use_custom_update_method = true

	is_permanent = false
	if (_duration < 0):
		is_permanent = true
	
	on_validation = _on_validation

	global_properties = {}
	individual_properties = {}




func copy(base: TimedModifier) -> void:
	is_active = base.is_active

	name = base.name
	lifetime = base.lifetime
	duration = base.duration

	stacks = base.stacks
	if !(base.copies.is_empty()):
		copies = base.copies.duplicate(true)

	on_enter = base.on_enter
	on_exit = base.on_exit

	is_permanent = base.is_permanent
	use_custom_update_method = base.use_custom_update_method
	on_update = base.on_update

	on_validation = base.on_validation

	global_properties = base.global_properties
	if !(base.individual_properties.is_empty()):
		individual_properties = base.individual_properties.duplicate(true)


func clone() -> TimedModifier:
	var modifier: TimedModifier = TimedModifier.new()
	modifier.copy(self)

	return modifier




func set_property(property: StringName, value: Variant) -> TimedModifier:
	set(property, value)
	return self


func add_global_property(property: StringName, value: Variant) -> TimedModifier:
	global_properties[property] = value
	return self


func add_individual_property(property: StringName, value: Variant) -> TimedModifier:
	individual_properties[property] = value
	return self




func update_lifetime(delta: float) -> bool:
	if !(is_active):
		return false

	if (use_custom_update_method): on_update.call(self, target, delta)
	else: update(delta)

	if (is_permanent):
		return true

	lifetime -= delta
	if lifetime < 0.0:
		exit()
		return false
	return true




func enter() -> void:
	if (on_enter.is_valid()): 
		on_enter.call(self, target)
	stacks += 1
	copies.append(self)
	is_active = true


func exit() -> void:
	if (on_exit.is_valid()):
		on_exit.call(self, target)
	disable()




func update(_delta: float) -> void:
	pass


func disable() -> void:
	individual_properties.clear()
	is_active = false




func get_target() -> RefCounted:
	return target

func set_target(_target: RefCounted) -> void:
	target = _target

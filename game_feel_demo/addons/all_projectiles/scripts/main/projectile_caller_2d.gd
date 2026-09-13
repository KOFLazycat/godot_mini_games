## A node able to request the creation of projectiles to the main processor.
## Can hold multiple projectile blueprints.

@icon("res://addons/all_projectiles/icons/projectile_caller_2d.svg")

class_name ProjectileCaller2D
extends Node2D


@export_group("Database")
## If true, the caller will automatically add all its unregistered projectiles to the global database
@export var auto_add_projectiles_to_database: bool = true
## If true, the caller will get new projectile copies when requesting from the database (Instead of the references themselves)
@export var get_projectile_copies_from_database: bool = true
@export_group("")
@export var projectile_resources: Array[ProjectileBlueprint2D]

var projectiles: Array[Projectile2D]
var projectile_processor: ProjectileProcessor2D




func request_projectile(index: int, _position: Vector2, destination: Vector2, target: Node2D = null, 
	move_method: Callable = Callable(), start_method: Callable = Callable(), collision_method: Callable = Callable(),
	expired_method: Callable = Callable()) -> bool:
	
	if !validate_request(index):
		return false
	projectile_processor.add_projectiles_resource(projectiles[index], _position, destination, target, 
	move_method, start_method, collision_method, expired_method)
	return true


func request_projectile_from_database(id: StringName, _position: Vector2, destination: Vector2, target: Node2D = null, 
	move_method: Callable = Callable(), start_method: Callable = Callable(), collision_method: Callable = Callable(),
	expired_method: Callable = Callable()) -> bool:
	
	if !(verify_projectile_from_database(id)):
		return false

	projectile_processor.add_projectiles_resource(APDatabase.get_projectile_2d(id), _position, destination, target, 
	move_method, start_method, collision_method, expired_method)
	return true




func append_projectiles_from_database(names: Array, include_blueprints: bool = false) -> void:
	for i: int in names.size():
		var key: StringName = str(names[i])
		add_projectile_from_database(key, include_blueprints)


func add_projectile_from_database(id: StringName, include_blueprints: bool = false) -> bool:
	if !(verify_projectile_from_database(id)):
		return false

	projectiles.append(APDatabase.get_projectile_2d(id, get_projectile_copies_from_database))
	if (include_blueprints):
		projectile_resources.append(APDatabase.get_projectile_blueprint_2d(id))
	return true


func reassing_projectiles_from_database(names: Array, include_blueprints: bool = false) -> void:
	projectiles.clear()
	projectiles.resize(names.size())

	if (include_blueprints):
		projectile_resources.clear()
		projectile_resources.resize(names.size())

	for i: int in names.size():
		var key: StringName = str(names[i])
		set_projectile_from_database(i, key, include_blueprints)


func set_projectile_from_database(index: int, id: StringName, include_blueprints: bool = false) -> bool:
	if !(verify_projectile_from_database(id)):
		return false

	if !(index < projectiles.size()):
		projectiles.resize(index + 1)
	
	projectiles[index] = APDatabase.get_projectile_2d(id, get_projectile_copies_from_database)
	if (include_blueprints):
		if !(index < projectile_resources.size()):
			projectile_resources.resize(index + 1)
		projectile_resources[index] = APDatabase.get_projectile_blueprint_2d(id)
	return true


func verify_projectile_from_database(id: StringName) -> bool:
	if !(APDatabase.projectile_2d_dictionary.has(id)):
		printerr("Projectile '%s' does not exist in the database." % id)
		return false
	return true




func add_projectile_modifier(index: int, modifier: Projectile2DModifier) -> bool:
	if !(validate_proj_processor()):
		return false

	if !(validate_proj(index)):
		return false
	
	return projectiles[index].add_modifier(modifier)


func remove_projectile_modifier(index: int, id: StringName) -> bool:
	if !(validate_proj(index)):
		return false

	return projectiles[index].remove_modifier(id)


func remove_modifier_stacks_from_projectile(index: int, id: StringName, stacks: int = -1) -> bool:
	if !(validate_proj(index)):
		return false
	
	if !(projectiles[index].projectile_modifiers.has(id)):
		return false

	if (stacks < 0):
		stacks = projectiles[index].projectile_modifiers[id].copies.size()
	else:
		stacks = clampi(stacks, 0, projectiles[index].projectile_modifiers[id].copies.size())

	for i: int in stacks:
		var element: TimedModifier = projectiles[index].projectile_modifiers[id].copies.pop_back()
		element.exit()
	return true





func get_projectile(index: int) -> Projectile2D:
	if !(validate_proj(index)):
		return Projectile2D.new()
	
	return projectiles[index]


func set_projectile(index: int, projectile: Projectile2D, auto_assign_blueprint: bool = true) -> void:
	if !(index < projectiles.size()):
		projectiles.resize(index + 1)

	if (auto_assign_blueprint):
		if (validate_proj_resource(index)):
			projectile._init(projectile_resources[index])
	
	if (auto_add_projectiles_to_database && projectile.resource != null):
		APDatabase.set_projectile_2d(projectile.resource.name, projectile)
		projectiles[index] = APDatabase.get_projectile_2d(projectile.resource.name)
	else:
		projectiles[index] = projectile


func get_projectile_blueprint(index: int) -> ProjectileBlueprint2D:
	if !(validate_proj_resource(index)):
		return ProjectileBlueprint2D.new()

	return projectile_resources[index]




func validate_request(index: int) -> bool:
	return validate_proj_processor() && validate_proj(index)



func validate_proj(index: int) -> bool:

	if (projectiles.is_empty()):
		printerr("Projectile_Caller doesn't have any built Projectiles")
		push_error("Projectile_Caller doesn't have any built Projectiles")
		return false

	if (index > projectiles.size() - 1 || index < 0):
		printerr("Projectile_Caller 'Projectile' call is invalid (Out of bounds get index '%d')" % index)
		push_error("Projectile_Caller 'Projectile' call is invalid (Out of bounds get index '%d')" % index)
		return false

	if (projectiles[index] == null):
		printerr("Projectile_Caller doesn't have an assigned Projectile at index %d or is invalid" % index)
		push_error("Projectile_Caller doesn't have an assigned Projectile at index %d or is invalid" % index)
		return false
	
	if (!projectiles[index].is_linked && projectile_processor != null):
		projectiles[index].link_to_processor(projectile_processor)

	return true


func validate_proj_resource(index: int) -> bool:

	if (projectile_resources.is_empty()):
		printerr("Projectile_Caller doesn't have any assigned Projectile_Resorces")
		push_error("Projectile_Caller doesn't have any assigned Projectile_Resorces")
		return false

	if (index > projectile_resources.size() - 1 || index < 0):
		printerr("Projectile_Caller 'Resource' call is invalid (Out of bounds get index '%d')" % index)
		push_error("Projectile_Caller 'Resource' call is invalid (Out of bounds get index '%d')" % index)
		return false

	if (projectile_resources[index] == null):
		printerr("Projectile_Caller doesn't have an assigned Projectile_Resorce at index %d or is invalid" % index)
		push_error("Projectile_Caller doesn't have an assigned Projectile_Resorce at index %d or is invalid" % index)
		return false
	
	return true




func validate_proj_processor() -> bool:

	if (projectile_processor != null):
		return true

	# Try to find a valid ProjPross in the SceneTree singleton
	projectile_processor = get_tree().get_first_node_in_group(Projectile2D.PROJ_PROCESSOR_GROUP_NAME)
	if (projectile_processor != null):
		return true
	
	# Create a valid ProjPross in the current scene
	projectile_processor = ProjectileProcessor2D.new()
	projectile_processor.name = "ProjectileProcessor2D"
	get_tree().current_scene.add_child(projectile_processor)

	if (projectile_processor != null):
		return true
	
	printerr("Projectile_Caller cannot find a valid Projectile_Processor")
	return false





func _enter_tree() -> void:
	add_to_group(Projectile2D.PROJ_CALLER_GROUP_NAME)

	projectiles.resize(projectile_resources.size())

	for i: int in projectile_resources.size():
		if projectile_resources[i] == null:
			continue
		
		if (auto_add_projectiles_to_database):
			projectiles[i] = APDatabase.register_and_get_projectile_2d(projectile_resources[i], get_projectile_copies_from_database)
		else:
			projectiles[i] = ProjectileFactory.create_projectile(projectile_resources[i])


func _exit_tree() -> void:
	remove_from_group(Projectile2D.PROJ_CALLER_GROUP_NAME)

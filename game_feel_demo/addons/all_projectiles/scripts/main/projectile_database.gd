class_name AllProjectilesGlobalDatabase
extends Node


var projectile_2d_dictionary: Dictionary[StringName, Projectile2D]
var projectile_blueprints_2d_dictionary: Dictionary[StringName, ProjectileBlueprint2D]

var attack_2d_dictionary: Dictionary[StringName, Attack2D]
var attack_blueprint_2d_dictionary: Dictionary[StringName, AttackBlueprint2D]

var modifiers_dictionary: Dictionary[StringName, TimedModifier]




func get_modifier(id: StringName, return_copy: bool = true) -> TimedModifier:
	var modifier: TimedModifier = modifiers_dictionary[id]

	if (return_copy): return modifier.clone()
	else: return modifier


func set_modifier(modifier: TimedModifier, id: StringName = modifier.name) -> void:
	modifiers_dictionary[id] = modifier


func get_projectile_2d_modifier(id: StringName, return_copy: bool = true) -> Projectile2DModifier:
	var modifier: Projectile2DModifier = modifiers_dictionary[id]

	if (return_copy): return modifier.clone()
	else: return modifier


func get_attack_2d_modifier(id: StringName, return_copy: bool = true) -> Attack2DModifier:
	var modifier: Attack2DModifier = modifiers_dictionary[id]

	if (return_copy): return modifier.clone()
	else: return modifier




func register_and_get_projectile_2d(blueprint: ProjectileBlueprint2D, return_copy: bool = true) -> Projectile2D:
	projectile_blueprints_2d_dictionary.get_or_add(blueprint.name, blueprint)
	var proj: Projectile2D = projectile_2d_dictionary.get_or_add(blueprint.name, 
		ProjectileFactory.create_projectile(blueprint))
	
	if (return_copy): return proj.clone()
	else: return proj


func get_projectile_2d(id: StringName, return_copy: bool = true) -> Projectile2D:
	var proj: Projectile2D = projectile_2d_dictionary[id]

	if (return_copy): return proj.clone()
	else: return proj


func set_projectile_2d(id: StringName, projectile: Projectile2D) -> void:
	projectile_2d_dictionary[id] = projectile


func get_projectile_blueprint_2d(id: StringName) -> ProjectileBlueprint2D:
	return projectile_blueprints_2d_dictionary[id]


func set_projectile_blueprint_2d(id: StringName, projectile: ProjectileBlueprint2D) -> void:
	projectile_blueprints_2d_dictionary[id] = projectile




func register_and_get_attack_2d(blueprint: AttackBlueprint2D, return_copy: bool = true) -> Attack2D:
	attack_blueprint_2d_dictionary.get_or_add(blueprint.name, blueprint)
	var attack: Attack2D = attack_2d_dictionary.get_or_add(blueprint.name,
		Attack2D.new(blueprint))
	
	if (return_copy): return attack.clone()
	else: return attack


func get_attack_2d(id: StringName, return_copy: bool = true) -> Attack2D:
	var attack: Attack2D = attack_2d_dictionary[id]

	if (return_copy): return attack.clone()
	else: return attack


func set_attack_2d(id: StringName, attack: Attack2D) -> void:
	attack_2d_dictionary[id] = attack


func get_attack_blueprint_2d(id: StringName) -> AttackBlueprint2D:
	return attack_blueprint_2d_dictionary[id]


func set_attack_blueprint_2d(id: StringName, attack: AttackBlueprint2D) -> void:
	attack_blueprint_2d_dictionary[id] = attack

@icon("res://addons/all_projectiles/icons/projectile_manager_2d.svg")

class_name ProjectileManager2D
extends ProjectileCaller2D


var attacks: Array[Attack2D]

@export_group("Database")
## If true, the manager will automatically add all its unregistered attacks to the global database
@export var auto_add_attacks_to_database: bool = true
## If true, the manager will get new attack copies when requesting from the database (Instead of the references themselves)
@export var get_attack_copies_from_database: bool = true
@export_group("")
@export var attack_resources: Array[AttackBlueprint2D]




func request_execution(attack_index: int, proj_index: int, _position: Vector2, destination: Vector2, target: Node2D = null,
	move_method: Callable = Callable(), start_method: Callable = Callable(), collision_method: Callable = Callable(),
	expired_method: Callable = Callable()) -> bool:
	if !(validate_request(proj_index) && validate_attack(attack_index)):
		return false

	var attack: Attack2D = attacks[attack_index].clone()
	# 克隆后必须连接到处理器，否则信号不会正确发射
	attack.link_to_processor(projectile_processor)
	if (attack.is_active):
		attack.requested_interaction = true
		return false

	attack.assing(projectiles[proj_index], self)
	projectiles[proj_index].attack = attack
	attack.pi.reassing_simple(_position, destination, target, move_method, start_method, collision_method, expired_method)
	projectile_processor.add_attack(attack)
	return true


func request_new_attack_creation(attack_index: int, proj_index: int, _position: Vector2, destination: Vector2, target: Node2D = null, 
	move_method: Callable = Callable(), start_method: Callable = Callable(), collision_method: Callable = Callable(),
	expired_method: Callable = Callable()) -> bool:
	
	if !(validate_request(proj_index) && validate_attack(attack_index)):
		return false
	
	var attack: Attack2D = attacks[attack_index].clone()
	attack.link_to_processor(projectile_processor)
	attack.assing(projectiles[proj_index], self)
	# projectiles[proj_index].attack = attack
	attack.pi.reassing_simple(_position, destination, target, move_method, start_method, collision_method, expired_method)
	projectile_processor.add_attack(attack)
	return true




func append_attacks_from_database(names: Array, include_blueprints: bool = false) -> void:
	for i: int in names.size():
		var key: StringName = str(names[i])
		add_attack_from_database(key, include_blueprints)


func add_attack_from_database(id: StringName, include_blueprints: bool = false) -> bool:
	if !(verify_attack_from_database(id)):
		return false

	attacks.append(APDatabase.get_attack_2d(id, get_attack_copies_from_database))
	if (include_blueprints):
		attack_resources.append(APDatabase.get_attack_blueprint_2d(id))
	return true


func reassing_attacks_from_database(names: Array, include_blueprints: bool = false) -> void:
	attacks.clear()
	attacks.resize(names.size())

	if (include_blueprints):
		attack_resources.clear()
		attack_resources.resize(names.size())
	
	for i: int in names.size():
		var key: StringName = str(names[i])
		set_attack_from_database(i, key, include_blueprints)


func set_attack_from_database(index: int, id: StringName, include_blueprints: bool = false) -> bool:
	if !(verify_attack_from_database(id)):
		return false
	
	if !(index < attacks.size()):
		attacks.resize(index + 1)
	
	attacks[index] = APDatabase.get_attack_2d(id, get_attack_copies_from_database)
	if (include_blueprints):
		if !(index < attack_resources.size()):
			attack_resources.resize(index + 1)
		attack_resources[index] = APDatabase.get_attack_blueprint_2d(id)
	return true


func verify_attack_from_database(id: StringName) -> bool:
	if !(APDatabase.attack_2d_dictionary.has(id)):
		printerr("Attack '%s' does not exist in the database." % id)
		return false
	return true




func add_attack_modifier(index: int, modifier: Attack2DModifier) -> bool:
	if !(validate_proj_processor()):
		return false

	if !(validate_attack(index)):
		return false
	
	return attacks[index].add_modifier(modifier)


func remove_attack_modifier(index: int, id: StringName) -> bool:
	if !(validate_attack(index)):
		return false

	return attacks[index].remove_modifier(id)


func remove_modifier_stacks_from_attack(index: int, id: StringName, stacks: int = -1) -> bool:
	if !(validate_attack(index)):
		return false
	
	if !(attacks[index].attack_modifiers.has(id)):
		return false

	if (stacks < 0):
		stacks = attacks[index].attack_modifiers[id].copies.size()
	else:
		stacks = clampi(stacks, 0, attacks[index].attack_modifiers[id].copies.size())

	for i: int in stacks:
		var element: TimedModifier = attacks[index].attack_modifiers[id].copies.pop_back()
		element.exit()
	return true




func get_attack(index: int) -> Attack2D:
	if !(validate_attack(index)):
		return Attack2D.new()
	
	return attacks[index]


func set_attack(index: int, attack: Attack2D, auto_assign_blueprint: bool = true) -> void:
	if !(index < attacks.size()):
		attacks.resize(index + 1)

	if (auto_assign_blueprint):
		if (validate_attack_resource(index)):
			attack._init(attack_resources[index], self)

	if (auto_add_attacks_to_database && attack.resource != null):
		APDatabase.set_attack_2d(attack.resource.name, attack)
		attacks[index] = APDatabase.get_attack_2d(attack.resource.name)
	else:
		attacks[index] = attack


func get_attack_blueprint(index: int) -> AttackBlueprint2D:
	if !(validate_attack_resource(index)):
		return AttackBlueprint2D.new()

	return attack_resources[index]




func validate_attack(index: int) -> bool:

	if (attacks.is_empty()):
		printerr("Projectile_Manager doesn't have any built Attacks")
		push_error("Projectile_Manager doesn't have any built Attacks")
		return false

	if (index > attacks.size() - 1 || index < 0):
		printerr("Projectile_Manager 'Attack2D' call is invalid (Out of bounds get index '%d')" % index)
		push_error("Projectile_Manager 'Attack2D' call is invalid (Out of bounds get index '%d')" % index)
		return false

	if (attacks[index] == null):
		printerr("Projectile_Manager doesn't have an assigned Attack2D at index %d or is invalid" % index)
		push_error("Projectile_Manager doesn't have an assigned Attack2D at index %d or is invalid" % index)
		return false
	
	# 强制重新连接信号，确保场景切换后 processor 变化时能正确连接
	if projectile_processor != null:
		attacks[index].link_to_processor(projectile_processor)

	return true


func validate_attack_resource(index: int) -> bool:

	if (attack_resources.is_empty()):
		printerr("Projectile_Manager doesn't have any assigned Attack_Resorces")
		push_error("Projectile_Manager doesn't have any assigned Attack_Resorces")
		return false

	if (index > attack_resources.size() - 1 || index < 0):
		printerr("Projectile_Manager 'Resource' call is invalid (Out of bounds get index '%d')" % index)
		push_error("Projectile_Manager 'Resource' call is invalid (Out of bounds get index '%d')" % index)
		return false

	if (attack_resources[index] == null):
		printerr("Projectile_Manager doesn't have an assigned Attack_Resorce at index %d or is invalid" % index)
		push_error("Projectile_Manager doesn't have an assigned Attack_Resorce at index %d or is invalid" % index)
		return false
	
	return true




func _enter_tree() -> void:
	super()
	attacks.resize(attack_resources.size())

	for i: int in attack_resources.size():
		if (attack_resources[i] == null):
			continue

		if (auto_add_attacks_to_database):
			attacks[i] = APDatabase.register_and_get_attack_2d(attack_resources[i], get_attack_copies_from_database)
		else:
			attacks[i] = Attack2D.new(attack_resources[i], self)


func _exit_tree() -> void:
	super()
	for attack: Attack2D in attacks:
		if (attack.is_active):
			attack.disable()

	attacks.clear()




# func _notification(what: int) -> void:
# 	match what:
# 		NOTIFICATION_PAUSED:
# 			print("Node paused")
# 			on_paused_time = Time.get_ticks_msec()
# 		NOTIFICATION_UNPAUSED:
# 			print("Node unpaused")
# 			total_paused_time += Time.get_ticks_msec() - on_paused_time
# 			print(total_paused_time / 1000.0)

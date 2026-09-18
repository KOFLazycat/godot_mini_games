## Adds, draws and processes all requested projectiles.

@icon("res://addons/all_projectiles/icons/projectile_processor_2d.svg")

class_name ProjectileProcessor2D
extends Node2D


signal projectile_array_expanded
signal projectile_inactive_queue_expanded
signal projectile_inactive_queue_contracted

signal attack_array_expanded
signal attack_inactive_queue_expanded
signal attack_inactive_queue_contracted

signal modifier_array_expanded
signal modifier_inactive_queue_expanded
signal modifier_inactive_queue_contracted


var projectiles: Array[Projectile2D]
var inactive_projectiles_queue: Array[int]

var attacks: Array[Attack2D]
var inactive_attacks_queue: Array[int]

var modifiers: Array[TimedModifier]
var inactive_modifiers_queue: Array[int]

var packed_info: PackedInfo

static var world_RID: RID 
static var visible_collisions: bool



func _ready() -> void:
	# It is extremely possible that ProjCall will end up being responsible for assigning 
	# worlds and Scenes on projectile creation and not just by static variables on the ProjPross
	# That's because I may end up allowing the creation of more than one ProjPross on the SceneTree
	world_RID = get_world_2d().space 
	packed_info = PackedInfo.new()

	InstancedProjectile2D.current_scene = get_tree().get_first_node_in_group("projectiles_layer")
	if InstancedProjectile2D.current_scene == null:
		InstancedProjectile2D.current_scene = get_tree().current_scene
	Projectile2D.current_space = get_world_2d().direct_space_state

	visible_collisions = get_tree().debug_collisions_hint



func add_modifier(modifier: TimedModifier) -> void:
	if inactive_modifiers_queue.size() > 0:
		var id: int = inactive_modifiers_queue.pop_front()
		modifier_inactive_queue_contracted.emit()
		modifiers[id] = modifier
	else:
		modifiers.append(modifier)
		modifier_array_expanded.emit()
	modifier.enter()



func add_attack(attack: Attack2D) -> void:
	if inactive_attacks_queue.size() > 0:
		var id: int = inactive_attacks_queue.pop_front()
		attack_inactive_queue_contracted.emit()
		attacks[id] = attack
	else:
		attacks.append(attack)
		attack_array_expanded.emit()
	attack.start()



func add_projectiles_resource(projectile: Projectile2D, _position: Vector2, _destination: Vector2, _target: Node2D = null,
	 _move_method: Callable = Callable(), _start_method: Callable = Callable(), _collision_method: Callable = Callable(),
	 _expired_method: Callable = Callable()) -> void:
	var iterations: int = projectile.instances

	for i: int in iterations:
		packed_info.reassing_all(_position, _destination - _position, _destination, _target, i, world_RID,
		_move_method, _start_method, _collision_method, _expired_method)

		_add_projectile(projectile, packed_info)



func _add_projectile(projectile: Projectile2D, _packed_info: PackedInfo) -> void:
	if inactive_projectiles_queue.size() > 0:
		var id: int = inactive_projectiles_queue.pop_front()
		projectile_inactive_queue_contracted.emit() 

		if projectile.resource.proj_type == projectiles[id].resource.proj_type:
			projectiles[id].copy(projectile, _packed_info)
		else:
			# All projectiles are RefCounted
			# Could I use Objects and just do this??? What would I gain???
				# projectiles[id].free()
			projectiles[id] = null
			projectiles[id] = projectile.clone(_packed_info)
			projectiles[id].link_to_processor(self)

	else:
		projectiles.resize(projectiles.size() + 1)
		projectiles[-1] = projectile.clone(_packed_info)
		projectiles[-1].link_to_processor(self)
		projectile_array_expanded.emit()

	


func _process(delta: float) -> void:
	
	for i: int in modifiers.size():

		if modifiers[i] == null:
			continue
		
		if !modifiers[i].update_lifetime(delta):
			modifiers[i] = null
			inactive_modifiers_queue.push_back(i)
			modifier_inactive_queue_expanded.emit()


	for i: int in attacks.size():

		if attacks[i] == null:
			continue
		
		if !attacks[i].update(delta):
			attacks[i] = null
			inactive_attacks_queue.push_back(i)
			attack_inactive_queue_expanded.emit()


	for i: int in projectiles.size():

		if !projectiles[i].is_active:
			continue
		
		if !projectiles[i].update_lifetime(delta):
			projectiles[i].disable()

			inactive_projectiles_queue.push_back(i)
			projectile_inactive_queue_expanded.emit()
	
	queue_redraw()



func _physics_process(delta: float) -> void:
	
	for i: int in projectiles.size():

		if !projectiles[i].is_active:
			continue
		
		projectiles[i].move(delta)



func _draw() -> void:
	for i: int in projectiles.size():

		if !projectiles[i].is_active:
			continue

		if !(projectiles[i] is AreaProjectile2D):
			continue

		projectiles[i].draw_on_canvas(self) 




func _enter_tree() -> void:
	if (get_tree().get_first_node_in_group(Projectile2D.PROJ_PROCESSOR_GROUP_NAME) != null):
		queue_free()

	add_to_group(Projectile2D.PROJ_PROCESSOR_GROUP_NAME)


func _exit_tree() -> void:
	remove_from_group(Projectile2D.PROJ_PROCESSOR_GROUP_NAME)
	for proj: Projectile2D in projectiles:
		if (proj.is_active):
			proj.disable()

	projectiles.clear()

class_name ProjectileFactory
extends RefCounted


static func create_projectile(resource: ProjectileBlueprint2D, packed_info: PackedInfo = null) -> Projectile2D:
	
	if resource.proj_type == Projectile2D.ProjectileType.AREA:
		return AreaProjectile2D.new(resource, packed_info)
	# elif resource.proj_type == Projectile2D.ProjectileType.PHYSIC:
	# 	return PhysicProjectile2D.new(resource, packed_info)
	elif resource.proj_type == Projectile2D.ProjectileType.INSTANTIATED:
		return InstancedProjectile2D.new(resource, packed_info)
	else:
		return AreaProjectile2D.new(resource, packed_info)

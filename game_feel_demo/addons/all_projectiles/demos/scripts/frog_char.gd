class_name FrogCharacter
extends CharacterTest


enum Spells{
	MAGIC_BOLT,
	HEAVY_MAGIC_BOLT,
	SOUL_SEEKER,
	HEAVY_SOUL_SEEKER,
	THE_PURSUER,
	MAGIC_BURST,
	EVEN_GLARE,
	FIREBALL,
	GREAT_FIREBALL,
	DRAGONS_BREATH,
	ERUPTION,
	BURNING_SKIES,
	CELESTIAL_MISSILE,
	MEGA_LASER
}


func _ready() -> void:
	projectile_manager.reassing_projectiles_from_database(Spells.keys())
	projectile_manager.reassing_attacks_from_database(Spells.keys())

	for attack: Attack2D in projectile_manager.attacks:
		attack.individual_properties.set("TARGET", self)

	super()


func _process(delta: float) -> void:
	super(delta)

	if (Input.is_key_pressed(KEY_N)):
		projectile_manager.add_projectile_modifier(selected_projectile_id, APDatabase.get_projectile_2d_modifier("PROJECTILE_BUFF"))
	
	if (Input.is_key_pressed(KEY_M)):
		projectile_manager.add_attack_modifier(selected_projectile_id, APDatabase.get_attack_2d_modifier("ATTACK_BUFF"))

@tool
extends EditorPlugin

const ALL_PROJECTILES_DATABASE_NAME: StringName = "APDatabase"


func _enter_tree() -> void:
	add_autoload_singleton(ALL_PROJECTILES_DATABASE_NAME, "res://addons/all_projectiles/scripts/main/projectile_database.gd")


func _exit_tree() -> void:
	remove_autoload_singleton(ALL_PROJECTILES_DATABASE_NAME)

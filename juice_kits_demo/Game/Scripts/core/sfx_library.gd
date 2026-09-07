# Maps bank names to SfxBanks. Baked into assets/sfx_library.tres ahead of time.
@tool
class_name SfxLibrary
extends Resource


@export var banks: Dictionary = {}


func get_bank(key: StringName) -> SfxBank:
	var bank = banks.get(key)
	return bank if bank is SfxBank else null


func has_bank(key: StringName) -> bool:
	return get_bank(key) != null


func bank_names() -> Array:
	var names := banks.keys()
	names.sort()
	return names


func add_bank(key: StringName, bank: SfxBank) -> void:
	banks[key] = bank

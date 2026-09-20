## Description
## Requirements: [Does this component depend on other components? Or does it need the parent Entity to be a specific type of node?]

class_name ASCComponent
extends Component


#region Parameters
@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_process(isEnabled) # PERFORMANCE: Set once instead of every frame
## 当前实体所携带的 AbilitySystemComponent
@export var asc: AbilitySystemComponent:
	get:
		if asc == null:
			asc = entity.findFirstChildOfType(AbilitySystemComponent)
		return asc
#endregion


#region State
#endregion


#region Signals
#endregion


#region Dependencies
# WARNING: "Memoization" (caching the reference) may cause bugs if a component is removed from the entity later.

## Returns a list of required component types that this component depends on.
func getRequiredComponents() -> Array[Script]:
	return []

#endregion


func _ready() -> void:
	# PLACEHOLDER: Add any code needed to configure and prepare the component.
	# Apply setters because Godot doesn't on _ready()
	if asc == null:
		printError("AbilitySystemComponent 缺失，组件无法正常工作")
		isEnabled = false
	self.set_process(isEnabled)


func _process(_delta: float) -> void: # NOTE: If you need to process movement or collisions, use `_physics_process()`
	if not isEnabled: return
	pass # PLACEHOLDER: Perform any per-frame updates.

## Description
## Requirements: [Does this component depend on other components? Or does it need the parent Entity to be a specific type of node?]

class_name MonsterHSMComponent
extends Component


#region Parameters
@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_process(isEnabled) # PERFORMANCE: Set once instead of every frame
#endregion


#region State
#endregion


#region Signals
#endregion


#region Dependencies
# WARNING: "Memoization" (caching the reference) may cause bugs if a component is removed from the entity later.
@onready var limboHsm: LimboHSM = $LimboHSM

## Returns a list of required component types that this component depends on.
func getRequiredComponents() -> Array[Script]:
	return []

#endregion


func _ready() -> void:
	# PLACEHOLDER: Add any code needed to configure and prepare the component.
	# Apply setters because Godot doesn't on _ready()
	self.set_process(isEnabled)
	limboHsm.initialize(entity)
	limboHsm.set_active(true)

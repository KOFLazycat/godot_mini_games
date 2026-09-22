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
@onready var hsm: LimboHSM = $LimboHSM
@onready var idleState: LimboState = $LimboHSM/IdleState
@onready var hurtState: LimboState = $LimboHSM/HurtState
@onready var dieState: LimboState = $LimboHSM/DieState

@onready var ascComponent: ASCComponent:
	get:
		if ascComponent == null:
			ascComponent = entity.getComponent(ASCComponent)
		return ascComponent

## Returns a list of required component types that this component depends on.
func getRequiredComponents() -> Array[Script]:
	return [ASCComponent]

#endregion


func _ready() -> void:
	# PLACEHOLDER: Add any code needed to configure and prepare the component.
	# Apply setters because Godot doesn't on _ready()
	if ascComponent == null:
		printError("ASCComponent 组件缺失")
		return
	_connectSignals()
	self.set_process(isEnabled)
	_initStateMachine()


func _exit_tree() -> void:
	_disconnectSignals()


func _initStateMachine() -> void:
	hsm.add_transition(idleState, hurtState, "hurt")
	hsm.add_transition(hurtState, idleState, hurtState.EVENT_FINISHED)
	hsm.add_transition(hsm.ANYSTATE, dieState, "die")
	hsm.initialize(entity)
	hsm.set_active(true)


func _connectSignals() -> void:
	Tools.connectSignal(ascComponent.asc.attribute_changed, onASC_attribute_changed)


func _disconnectSignals() -> void:
	Tools.disconnectSignal(ascComponent.asc.attribute_changed, onASC_attribute_changed)


#region Signal Handler

func onASC_attribute_changed(attributeName: String, oldValue: float, newValue: float, effectSpec: GameplayEffectSpec) -> void:
	if attributeName == "health":
		if newValue < oldValue:
			hsm.dispatch("hurt", effectSpec)

#endregion

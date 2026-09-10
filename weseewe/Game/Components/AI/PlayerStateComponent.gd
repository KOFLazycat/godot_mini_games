## Description
## Requirements: [Does this component depend on other components? Or does it need the parent Entity to be a specific type of node?]

class_name PlayerStateComponent
extends Component


#region Parameters
## 是否启用
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
@onready var stateChart: StateChart = $StateChart
@onready var idle: AtomicState = $StateChart/Root/Idle
@onready var jump: AtomicState = $StateChart/Root/Jump
@onready var die: AtomicState = $StateChart/Root/Die

@onready var platformerJumpComponent: PlatformerJumpComponent:
	get:
		if platformerJumpComponent == null:
			platformerJumpComponent = entity.getComponent(PlatformerJumpComponent)
		return platformerJumpComponent
@onready var spinComponent: SpinComponent:
	get:
		if spinComponent == null:
			spinComponent = entity.getComponent(SpinComponent)
		return spinComponent

#endregion


func _ready() -> void:
	# PLACEHOLDER: Add any code needed to configure and prepare the component.
	# Apply setters because Godot doesn't on _ready()
	self.set_process(isEnabled)
	_connectionSignals()


func _exit_tree() -> void:
	_disconnectionSignals()


func _connectionSignals() -> void:
	Tools.connectSignal(idle.state_entered, onIdle_state_entered)
	Tools.connectSignal(jump.state_entered, onJump_state_entered)
	Tools.connectSignal(die.state_entered, onDie_state_entered)
	if platformerJumpComponent:
		Tools.connectSignal(platformerJumpComponent.didJump, onPlatformerJumpComponent_didJump)
		Tools.connectSignal(platformerJumpComponent.didLand, onPlatformerJumpComponent_didLand)


func _disconnectionSignals() -> void:
	Tools.disconnectSignal(idle.state_entered, onIdle_state_entered)
	Tools.disconnectSignal(jump.state_entered, onJump_state_entered)
	Tools.disconnectSignal(die.state_entered, onDie_state_entered)
	if platformerJumpComponent:
		Tools.disconnectSignal(platformerJumpComponent.didJump, onPlatformerJumpComponent_didJump)
		Tools.disconnectSignal(platformerJumpComponent.didLand, onPlatformerJumpComponent_didLand)


func onIdle_state_entered() -> void:
	if not isEnabled: return
	spinComponent.isEnabled = false
	spinComponent.nodeToRotate.rotation = 0


func onJump_state_entered() -> void:
	if not isEnabled: return
	spinComponent.isEnabled = true
	match platformerJumpComponent.currentNumberOfJumps:
		1:
			spinComponent.rotationPerFrame = 10
		2:
			spinComponent.rotationPerFrame = 15
		_:
			spinComponent.rotationPerFrame = 10


func onDie_state_entered() -> void:
	if not isEnabled: return
	spinComponent.isEnabled = false
	spinComponent.nodeToRotate.rotation = 0


func onPlatformerJumpComponent_didJump(_jumpNumber: int, _jumpType: PlatformerJumpComponent.JumpType) -> void:
	if not isEnabled: return
	stateChart.send_event("to_jump")


func onPlatformerJumpComponent_didLand(_totalJumps: int) -> void:
	if not isEnabled: return
	stateChart.send_event("to_idle")

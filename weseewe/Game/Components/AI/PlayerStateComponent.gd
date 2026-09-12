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

@export var firstJumpResource: SoundResource
@export var secondJumpResource: SoundResource
@export var dieJumpResource: SoundResource

#endregion


#region State
var playerGPUParticles: GPUParticles2D:
	get:
		if playerGPUParticles == null:
			playerGPUParticles = entity.findFirstChildOfType(GPUParticles2D)
		return playerGPUParticles
var playerVisibleOnScreenNotifier: VisibleOnScreenNotifier2D:
	get:
		if playerVisibleOnScreenNotifier == null:
			playerVisibleOnScreenNotifier = entity.findFirstChildOfType(VisibleOnScreenNotifier2D)
		return playerVisibleOnScreenNotifier

var currentState: PlayerState = PlayerState.IDLE

enum PlayerState {
	IDLE,
	JUMP,
	DIE,
}
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
	if playerVisibleOnScreenNotifier:
		Tools.connectSignal(playerVisibleOnScreenNotifier.screen_exited, onPlayerVisibleOnScreenNotifier_screen_exited)


func _disconnectionSignals() -> void:
	Tools.disconnectSignal(idle.state_entered, onIdle_state_entered)
	Tools.disconnectSignal(jump.state_entered, onJump_state_entered)
	Tools.disconnectSignal(die.state_entered, onDie_state_entered)
	if platformerJumpComponent:
		Tools.disconnectSignal(platformerJumpComponent.didJump, onPlatformerJumpComponent_didJump)
		Tools.disconnectSignal(platformerJumpComponent.didLand, onPlatformerJumpComponent_didLand)
	if playerVisibleOnScreenNotifier:
		Tools.disconnectSignal(playerVisibleOnScreenNotifier.screen_exited, onPlayerVisibleOnScreenNotifier_screen_exited)


func onIdle_state_entered() -> void:
	if not isEnabled: return
	currentState = PlayerState.IDLE
	playerGPUParticles.emitting = false
	spinComponent.isEnabled = false
	spinComponent.nodeToRotate.rotation = 0


func onJump_state_entered() -> void:
	if not isEnabled: return
	currentState = PlayerState.JUMP
	spinComponent.isEnabled = true
	match platformerJumpComponent.currentNumberOfJumps:
		1:
			spinComponent.rotationPerFrame = 10
			if firstJumpResource != null:
				firstJumpResource.play_managed()
		2:
			playerGPUParticles.emitting = true
			spinComponent.rotationPerFrame = 15
			if secondJumpResource != null:
				secondJumpResource.play_managed()
		_:
			spinComponent.rotationPerFrame = 10
			if firstJumpResource != null:
				firstJumpResource.play_managed()


func onDie_state_entered() -> void:
	if not isEnabled: return
	currentState = PlayerState.DIE
	playerGPUParticles.emitting = false
	spinComponent.isEnabled = false
	spinComponent.nodeToRotate.rotation = 0
	if dieJumpResource != null:
		dieJumpResource.play_managed()
	await get_tree().create_timer(0.5).timeout
	GlobalEvent.playerDied.emit()
	GlobalEvent.gameEnded.emit(false)
	entity.requestDeletion()


func onPlatformerJumpComponent_didJump(_jumpNumber: int, _jumpType: PlatformerJumpComponent.JumpType) -> void:
	if not isEnabled: return
	if currentState == PlayerState.DIE:
		return
	stateChart.send_event("to_jump")


func onPlatformerJumpComponent_didLand(_totalJumps: int) -> void:
	if not isEnabled: return
	if currentState == PlayerState.DIE:
		return
	stateChart.send_event("to_idle")


func onPlayerVisibleOnScreenNotifier_screen_exited() -> void:
	if not isEnabled: return
	stateChart.send_event("to_die")

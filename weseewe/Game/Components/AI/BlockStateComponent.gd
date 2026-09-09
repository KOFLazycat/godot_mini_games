## Description
## Requirements: [Does this component depend on other components? Or does it need the parent Entity to be a specific type of node?]

class_name BlockStateComponent
extends Component


#region Parameters
## 是否启用
@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_process(isEnabled) # PERFORMANCE: Set once instead of every frame
## 是否关闭碰撞，false 不关闭，true 关闭碰撞
@export var shouldDisableCollision: bool = false:
	set(v):
		shouldDisableCollision = v
		var collisionShape: CollisionShape2D = entity.findFirstChildOfType(CollisionShape2D) as CollisionShape2D
		if collisionShape != null:
			collisionShape.disabled = shouldDisableCollision
#-------------------- 移动速度变量 --------------------
## 慢速移动速度（像素/秒）
## 用于游戏空闲状态时方块的缓慢移动
@export var slowSpeed: float = 50.0
## 快速移动速度（像素/秒）
## 用于游戏进行时方块的快速移动
@export var fastSpeed: float = 172.0
## BlockTopFront 节点的颜色
@export var blockColor: Color:
	set(v):
		blockColor = v
		entity.sprite.modulate = blockColor
@export var visibleOnScreenNotifier: VisibleOnScreenNotifier2D
#endregion


#region State
# 方块的高度（像素）
# 用于碰撞检测和边界计算
var height: float = 128.0
# 方块的宽度（像素）
var width: float = 102.0
#endregion


#region Signals
#endregion


#region Dependencies
@onready var stateChart: StateChart = $StateChart
@onready var stop: AtomicState = $StateChart/Root/Stop
@onready var slow: AtomicState = $StateChart/Root/Slow
@onready var fast: AtomicState = $StateChart/Root/Fast
@onready var slowMove: AtomicState = $StateChart/Root/SlowMove
@onready var shake: AtomicState = $StateChart/Root/Shake
@onready var linearMotionComponent: LinearMotionComponent:
	get:
		if linearMotionComponent == null:
			linearMotionComponent = entity.getComponent(LinearMotionComponent)
		return linearMotionComponent

#endregion


func _ready() -> void:
	# PLACEHOLDER: Add any code needed to configure and prepare the component.
	# Apply setters because Godot doesn't on _ready()
	self.set_process(isEnabled)
	blockColor = blockColor
	if visibleOnScreenNotifier == null:
		Debug.printError("VisibleOnScreenNotifier2D 没有正确配置", self)
		return
	_connectionSignals()


func _exit_tree() -> void:
	_disconnectionSignals()


func _connectionSignals() -> void:
	Tools.connectSignal(stop.state_entered, onStop_state_entered)
	Tools.connectSignal(slow.state_entered, onSlow_state_entered)
	Tools.connectSignal(fast.state_entered, onFast_state_entered)
	Tools.connectSignal(slowMove.state_entered, onSlowMove_state_entered)
	Tools.connectSignal(shake.state_entered, onShake_state_entered)
	if visibleOnScreenNotifier:
		Tools.connectSignal(visibleOnScreenNotifier.screen_exited, onVisibleOnScreenNotifier_screen_exited)


func _disconnectionSignals() -> void:
	Tools.disconnectSignal(stop.state_entered, onStop_state_entered)
	Tools.disconnectSignal(slow.state_entered, onSlow_state_entered)
	Tools.disconnectSignal(fast.state_entered, onFast_state_entered)
	Tools.disconnectSignal(slowMove.state_entered, onSlowMove_state_entered)
	Tools.disconnectSignal(shake.state_entered, onShake_state_entered)
	if visibleOnScreenNotifier:
		Tools.disconnectSignal(visibleOnScreenNotifier.screen_exited, onVisibleOnScreenNotifier_screen_exited)


func onStop_state_entered() -> void:
	linearMotionComponent.isMoving = false


func onSlow_state_entered() -> void:
	linearMotionComponent.isMoving = true
	linearMotionComponent.speed = slowSpeed


func onFast_state_entered() -> void:
	linearMotionComponent.isMoving = true
	linearMotionComponent.speed = fastSpeed


func onSlowMove_state_entered() -> void:
	linearMotionComponent.isMoving = true
	linearMotionComponent.speed = slowSpeed


func onShake_state_entered() -> void:
	pass


func onVisibleOnScreenNotifier_screen_exited() -> void:
	pass

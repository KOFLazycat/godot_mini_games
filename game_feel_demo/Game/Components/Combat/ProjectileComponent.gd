## ProjectileComponent
## 投射物组件 - 赋予实体发射投射物的能力
##
## 使用方法：
## 1. 在实体上添加此组件
## 2. 在实体下添加 StartMarker (Marker2D) 作为发射起点
## 3. 在实体下添加 TargetMarker (Marker2D) 作为目标标记
## 4. 设置 attackIndex 和 projectileIndex
## 5. 调用 requestProjectile() 发射投射物

class_name ProjectileComponent
extends Component


#region Parameters
@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_process(isEnabled)

## 在 GlobalArbitraryArmory.ProjectileManager2D.attack_resources 中的 AttackBlueprint2D 资源索引
@export var attackIndex: int = 0

## 在 GlobalArbitraryArmory.ProjectileManager2D.projectile_resources 中的 ProjectileBlueprint2D 资源索引
@export var projectileIndex: int = 0

#endregion


#region State
## 当前目标节点
var targetNode: Node2D:
	set(v):
		targetNode = v
		if targetNode != null:
			targetMarker.global_position = targetNode.global_position
## 上一次的目标节点（用于记录历史）
var lastTargetNode: Node2D
#endregion


#region Signals
## 投射物发射请求信号
signal didRequestProjectile(success: bool)
#endregion


#region Dependencies

@onready var startMarker: Marker2D = $StartMarker
@onready var targetMarker: Marker2D = $TargetMarker
@onready var inputComponent: InputComponent:
	get:
		if inputComponent == null:
			inputComponent = entity.getComponent(InputComponent)
		return inputComponent

func getRequiredComponents() -> Array[Script]:
	return []
#endregion


func _ready() -> void:
	Tools.connectSignal(inputComponent.didUpdateInputActionsList,	self.onInputComponent_didUpdateInputActionsList)
	self.set_process(isEnabled)
	printDebug("ProjectileComponent 初始化完成 - attackIndex: %d, projectileIndex: %d" % [attackIndex, projectileIndex])


# ============================================================================
# 投射物发射请求
# ============================================================================

## 请求发射投射物
##
## 使用流程：
## 1. 设置 attackIndex 和 projectileIndex
## 2. 设置 targetNode 或传入 customTarget
## 3. 调用 requestProjectile() 发射
##
## @param customTarget - 可选的自定义目标节点，优先级高于 targetNode
## @return - 发射成功返回 true
func requestProjectile(customTarget: Node2D = null) -> bool:
	# -------------------------------------------------------------------------
	# Step 1: 参数验证
	# -------------------------------------------------------------------------
	if not isEnabled:
		printWarning("组件已禁用，跳过发射")
		didRequestProjectile.emit(false)
		return false

	# -------------------------------------------------------------------------
	# Step 2: 验证攻击和投射物索引有效性
	# -------------------------------------------------------------------------
	var projManager: ProjectileManager2D = GlobalArbitraryArmory.projectileManager
	if projManager == null:
		printError("无法获取 ProjectileManager2D")
		didRequestProjectile.emit(false)
		return false

	if attackIndex < 0 or attackIndex >= projManager.attacks.size():
		printError("无效的 attackIndex: %d (有效范围: 0-%d)" % [attackIndex, projManager.attacks.size() - 1])
		didRequestProjectile.emit(false)
		return false

	if projectileIndex < 0 or projectileIndex >= projManager.projectiles.size():
		printError("无效的 projectileIndex: %d (有效范围: 0-%d)" % [projectileIndex, projManager.projectiles.size() - 1])
		didRequestProjectile.emit(false)
		return false

	# -------------------------------------------------------------------------
	# Step 3: 处理目标节点
	# -------------------------------------------------------------------------
	# 如果传入了自定义目标，将其赋值给 targetNode
	if customTarget != null:
		printDebug("使用自定义目标替换当前目标")
		targetNode = customTarget

	# 验证目标是否有效
	if targetNode == null:
		printWarning("targetNode 和 targetMarker 都为空，使用默认位置")

	# -------------------------------------------------------------------------
	# Step 4: 获取发射位置和目标位置
	# -------------------------------------------------------------------------
	var startPosition: Vector2 = startMarker.global_position
	var targetPosition: Vector2 = targetMarker.global_position
	
	# -------------------------------------------------------------------------
	# Step 5: 获取设置回调策略
	# -------------------------------------------------------------------------

	printDebug("开始发射 - attackIndex: %d, projectileIndex: %d" % [attackIndex, projectileIndex])
	printDebug("startPosition: %s, targetPosition: %s" % [startPosition, targetPosition])

	# -------------------------------------------------------------------------
	# Step 6: 调用 GlobalArbitraryArmory 发射投射物
	# -------------------------------------------------------------------------
	var result: bool = GlobalArbitraryArmory.requestExecutionByProjectileSpellStrategy(
		attackIndex,
		projectileIndex,
		startPosition,
		targetPosition,
		targetNode,  # 传入 targetNode 作为目标
	)

	if result:
		printDebug("投射物发射成功")
		# 发射成功后记录目标到历史，并重置当前目标
		lastTargetNode = targetNode
		targetNode = null
		didRequestProjectile.emit(true)
	else:
		printError("投射物发射失败")
		didRequestProjectile.emit(false)

	return result


#region Process Input

func onInputComponent_didUpdateInputActionsList(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(GlobalInput.Actions.fire):
		requestProjectile()

#endregion

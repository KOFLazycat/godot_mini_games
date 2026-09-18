##=================================================================================================
## HitBoxComponent - 攻击碰撞盒组件
##
## 本组件是攻击碰撞检测系统的一部分
## 功能：
## 1. 管理内部的 Area2D 碰撞盒（hitbox）
## 2. 检测与 HurtBoxComponent 的碰撞
## 3. 管理当前接触的 HurtBox 列表
## 4. 提供碰撞事件回调接口
##
## 使用方式：
## - 将此组件添加到攻击实体（如子弹、剑攻击范围）
## - 组件会自动创建 Area2D 子节点作为 hitbox
## - 通过 contacts 数组访问当前接触的 HurtBox
## - 监听 didEnterHurtBox/didExitHurtBox 信号获取碰撞事件
##
## 设计思路（参考 DamageComponent）：
## - HitBoxComponent 是"主动"检测方
## - HurtBoxComponent 是"被动"接收方
## - 通过 Area2D 的 area_entered/area_exited 信号检测碰撞
##=================================================================================================

# meta-default: true

class_name HitBoxComponent
extends Component


#=================================================================================================
## 参数区域 (Parameters)
#=================================================================================================
#region Parameters

## 是否启用碰撞检测
## 设置为 false 时会禁用 Area2D 的 monitoring 和 monitorable
@export var isEnabled: bool = true:
	set(newValue):
		isEnabled = newValue
		if hitbox:
			hitbox.monitoring = newValue
			hitbox.monitorable = newValue
		printDebug(str("isEnabled 设置为: ", newValue))

#endregion


#=================================================================================================
## 状态区域 (State)
#=================================================================================================
#region State

## 内部的 Area2D 碰撞盒节点
var hitbox: Area2D

## 当前接触的 HurtBoxComponent 列表
var contacts: Array[HurtBoxComponent] = []

## 攻击发起者
## 如果为 null，则默认为父实体
var initiatorEntity: Entity = null

#endregion


#=================================================================================================
## 信号区域 (Signals)
#=================================================================================================
#region Signals

## 当进入碰撞时触发
signal didEnterHurtBox(hurtBox: HurtBoxComponent)

## 当退出碰撞时触发
signal didExitHurtBox(hurtBox: HurtBoxComponent)

#endregion


#=================================================================================================
## 依赖区域 (Dependencies)
#=================================================================================================
#region Dependencies

## 碰撞形状节点，方便控制检测范围
@onready var collisionShape: CollisionShape2D = $CollisionShape2D

func getRequiredComponents() -> Array[Script]:
	return []

#endregion


#=================================================================================================
## 生命周期方法
#=================================================================================================

## 初始化方法
## 创建 Area2D 并连接碰撞信号
func _ready() -> void:
	# 创建 Area2D 作为 hitbox
	if not hitbox:
		hitbox = self.get_node(^".") as Area2D

	if self.initiatorEntity == null:
		self.initiatorEntity = self.entity

	self.set_physics_process(isEnabled)

	# 应用 setter（因为 Godot 初始化时不会自动调用）
	if hitbox:
		hitbox.monitoring = isEnabled
		hitbox.monitorable = isEnabled
		Tools.connectSignal(hitbox.area_entered, onHitBoxComponent_area_entered)
		Tools.connectSignal(hitbox.area_exited, onHitBoxComponent_area_exited)
	printDebug("HitBoxComponent 初始化完成")


## 组件销毁时断开所有信号连接，防止内存泄漏
func _exit_tree() -> void:
	if hitbox:
		Tools.disconnectSignal(hitbox.area_entered, onHitBoxComponent_area_entered)
		Tools.disconnectSignal(hitbox.area_exited, onHitBoxComponent_area_exited)
	printDebug("HitBoxComponent 已销毁，信号已断开")

#=================================================================================================
## 碰撞处理回调
#=================================================================================================

## Area2D 进入碰撞回调
## @param area - 进入的碰撞区域
func onHitBoxComponent_area_entered(area: Area2D) -> void:
	if not isEnabled or area == self.entity or area.owner == self.entity:
		return

	# 尝试获取 HurtBoxComponent
	var hurtBox: HurtBoxComponent = _getHurtBoxComponent(area)
	if hurtBox == null:
		return

	# 避免重复添加
	if contacts.has(hurtBox):
		return

	# 添加到接触列表
	contacts.append(hurtBox)

	# 发射信号
	didEnterHurtBox.emit(hurtBox)


## Area2D 退出碰撞回调
## @param area - 退出的碰撞区域
func onHitBoxComponent_area_exited(area: Area2D) -> void:
	# 获取 HurtBoxComponent
	var hurtBox: HurtBoxComponent = _getHurtBoxComponent(area)
	if hurtBox == null:
		return

	# 从接触列表移除
	if contacts.has(hurtBox):
		contacts.erase(hurtBox)
		# 发射信号
		didExitHurtBox.emit(hurtBox)


#=================================================================================================
## 工具方法
#=================================================================================================

## 从 Area2D 获取 HurtBoxComponent
func _getHurtBoxComponent(area: Area2D) -> HurtBoxComponent:
	if area == null:
		return null
	
	var hurtBoxComponent: HurtBoxComponent = area.get_node(^".") as HurtBoxComponent # HACK: Find better way to cast self?

	if not hurtBoxComponent:
		## NOTE: This warning may help to set collision masks properly.
		printWarning(str("Cannot cast area as HurtBoxComponent: ", area, " — Check collision masks."))
		return null
	
	# Is it our own entity?
	if self.entity and hurtBoxComponent.entity == self.entity:
		printDebug(str("HurtBoxComponent belongs to this HitBoxComponent's Entity: ", hurtBoxComponent.entity.logName))
		return null

	return hurtBoxComponent

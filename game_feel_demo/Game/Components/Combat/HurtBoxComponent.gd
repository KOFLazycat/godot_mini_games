##=================================================================================================
## HurtBoxComponent - 受伤盒组件
##
## 本组件是攻击碰撞检测系统的一部分
## 功能：
## 1. 管理内部的 Area2D 受伤盒（hurtbox）
## 2. 检测与 HitBoxComponent 的碰撞
## 3. 管理当前接触的 HitBox 列表
## 4. 提供碰撞事件回调接口
##
## 使用方式：
## - 将此组件添加到需要接收伤害的实体（如角色、怪物）
## - 组件会自动创建 Area2D 子节点作为 hurtbox
## - 通过 colliders 数组访问当前接触的 HitBox
## - 监听 didEnterHitBox/didExitHitBox 信号获取碰撞事件
##
## 设计思路（参考 DamageReceivingComponent）：
## - HurtBoxComponent 是"被动"接收方
## - HitBoxComponent 是"主动"检测方
## - 通过 Area2D 的 area_entered/area_exited 信号检测碰撞
##=================================================================================================
@icon("res://addons/at-icons/node2d/out_of_bounds.svg")
# meta-default: true

class_name HurtBoxComponent
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
		if hurtbox:
			hurtbox.monitoring = newValue
			hurtbox.monitorable = newValue
		printDebug(str("isEnabled 设置为: ", newValue))

#endregion


#=================================================================================================
## 状态区域 (State)
#=================================================================================================
#region State

## 内部的 Area2D 受伤盒节点
var hurtbox: Area2D

## 当前接触的 HitBoxComponent 列表
var colliders: Array[HitBoxComponent] = []

## 最后接触的 HitBoxComponent
var lastCollider: HitBoxComponent = null

#endregion


#=================================================================================================
## 信号区域 (Signals)
#=================================================================================================
#region Signals

## 当进入碰撞时触发
signal didEnterHitBox(hitBox: HitBoxComponent)

## 当退出碰撞时触发
signal didExitHitBox(hitBox: HitBoxComponent)

## 当被投射物击中，回调时触发
signal didHitWithProjectile(proj: Projectile2D)

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
	# 创建 Area2D 作为 hurtbox
	if not hurtbox:
		hurtbox = self.get_node(^".") as Area2D

	self.set_physics_process(isEnabled)

	# 应用 setter（因为 Godot 初始化时不会自动调用）
	if hurtbox:
		hurtbox.monitoring = isEnabled
		hurtbox.monitorable = isEnabled
		Tools.connectSignal(hurtbox.area_entered, onHurtBoxComponent_area_entered)
		Tools.connectSignal(hurtbox.area_exited, onHurtBoxComponent_area_exited)
	printDebug("HurtBoxComponent 初始化完成")


## 组件销毁时断开所有信号连接，防止内存泄漏
func _exit_tree() -> void:
	if hurtbox:
		Tools.disconnectSignal(hurtbox.area_entered, onHurtBoxComponent_area_entered)
		Tools.disconnectSignal(hurtbox.area_exited, onHurtBoxComponent_area_exited)
	printDebug("HurtBoxComponent 已销毁，信号已断开")


#=================================================================================================
## 碰撞处理回调
#=================================================================================================

## Area2D 进入碰撞回调
## @param area - 进入的碰撞区域
func onHurtBoxComponent_area_entered(area: Area2D) -> void:
	if not isEnabled or area == self.entity or area.owner == self.entity:
		return

	# 尝试获取 HitBoxComponent
	var hitBox: HitBoxComponent = _getHitBoxComponent(area)
	if hitBox == null:
		return

	# 避免重复添加
	if colliders.has(hitBox):
		return

	# 添加到碰撞列表
	colliders.append(hitBox)

	# 更新最后接触
	lastCollider = hitBox

	# 发射信号
	didEnterHitBox.emit(hitBox)


## Area2D 退出碰撞回调
## @param area - 退出的碰撞区域
func onHurtBoxComponent_area_exited(area: Area2D) -> void:
	# 获取 HitBoxComponent
	var hitBox: HitBoxComponent = _getHitBoxComponent(area)
	if hitBox == null:
		return

	if colliders.has(hitBox):
		# 从碰撞列表移除
		colliders.erase(hitBox)
		# 如果是最后接触，清除
		if lastCollider == hitBox:
			lastCollider = null
		# 发射信号
		didExitHitBox.emit(hitBox)


#=================================================================================================
## 工具方法
#=================================================================================================

## 从 Area2D 获取 HitBoxComponent
func _getHitBoxComponent(area: Area2D) -> HitBoxComponent:
	var hitBoxComponent: HitBoxComponent = area.get_node(^".") as HitBoxComponent # HACK: Find better way to cast self?
	
	if not hitBoxComponent:
		## NOTE: This warning may help to set collision masks properly.
		printWarning(str("Cannot cast area as HitBoxComponent: ", area, " — Check collision masks."))
		return null

	# Is it our own entity?
	if self.entity and hitBoxComponent.entity == self.entity:
		printDebug(str("HitBoxComponent belongs to this HitBoxComponent's Entity: ", hitBoxComponent.entity.logName))
		return null

	return hitBoxComponent


#=================================================================================================
## 投射物碰撞回调
#=================================================================================================

## all_projectile 插件碰撞后的回调函数
func onHitWithProjectile(proj: Projectile2D) -> void:
	var gability: GameplayAbility = proj.individual_properties.get(ProjectileCallbackStrategy.INDIVIDUAL_PROPERTIES_KEY_GABILITY, null)
	var geffects: Array[GameplayEffect] = proj.individual_properties.get(ProjectileCallbackStrategy.INDIVIDUAL_PROPERTIES_KEY_GEFFECTS, [])
	var targetData: GameplayAbilityTargetData = proj.individual_properties.get(ProjectileCallbackStrategy.INDIVIDUAL_PROPERTIES_KEY_TARGETDATA, null)
	
	if gability == null or geffects.is_empty() or targetData == null:
		printError("onHitWithProjectile 回调失败，gability: %s, geffects: %s, targetData: %s" % [gability, geffects, targetData])
	else:
		for ge: GameplayEffect in geffects:
			if ge:
				gability.apply_effect_to_targets(ge, targetData)

	printDebug("Hit By Projectile: %s" % [proj])
	didHitWithProjectile.emit(proj)

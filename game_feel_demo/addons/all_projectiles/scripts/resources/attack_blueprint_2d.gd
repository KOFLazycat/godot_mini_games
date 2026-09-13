## 攻击蓝图资源 (AttackBlueprint2D)
##
## 概述：
## 这是一个 Godot Resource 类型的资源文件，用于在编辑器中配置攻击（Attack）的各种属性。
## 攻击是将投射物（Projectile）发射出去的行为，这个蓝图定义了攻击的timing、位置、充能等相关属性。
##
## 代码架构：
## 1. 继承关系：extends Resource（Godot资源系统）
## 2. 核心逻辑：
##    - 使用 @export 导出的属性，供编辑器配置
##    - _init() 构造函数设置默认值
##    - _validate_property() 验证属性，根据条件隐藏/显示编辑器中的属性
## 3. 属性分类（通过 @export_category 和 @export_group 组织）：
##    - Main Attributes：主要属性（名称、各阶段持续时间）
##    - Spawn Properties：生成属性（位置、偏移）
##    - Charge：充能属性
##    - Timed Projectiles：定时投射物属性
##    - Custom Properties：自定义属性

@tool
@icon("res://addons/all_projectiles/icons/attack_resource_2d.svg")

class_name AttackBlueprint2D
extends Resource


@export_category("主属性")
## [主属性] 唯一标识符
## 用于在全球数据库中区分不同的攻击
@export var name: StringName

## [主属性] 准备阶段时长
## 攻击发作前的准备/预警时间（秒）
## 在这段时间内，攻击者可能做预警动作（如蓄力、前摇动画）
@export var attack_anticipate_time: float

## [主属性] 攻击阶段时长
## 实际执行攻击的持续时间（秒）
## 这段时间内，投射物会被生成并发射出去
@export var attack_duration_time: float:
	set(value):
		# 确保攻击时长至少为 0.001 秒，防止除零错误
		if (value < 0.001):
			attack_duration_time = 0.001
		else:
			attack_duration_time = value

## [主属性] 恢复阶段时长
## 攻击结束后的恢复时间（秒）
## 在这段时间内，攻击者可能做后摇动作，或等待下一个攻击周期
@export var attack_recovery_time: float


@export_category("生成属性")
@export_group("位置")
## [位置] 攻击偏移
## 生成投射物时的额外位置偏移量
## 在基础生成位置基础上添加的偏移向量
@export var attack_offset: Vector2

## [位置] 覆盖位置
## 如果为 true，攻击将忽略给定的生成位置
## 使用 ProjectileManager2D 节点的全局位置作为生成位置
@export var override_position: bool

## [位置] 覆盖方向
## 如果为 true，攻击将持续更新投射物方向
## 即使攻击执行请求不成功也会更新方向
@export var override_direction: bool
@export_group("")


@export_group("充能")
## [充能] 充能时长
## 充能阶段需要的时间（秒）
## 玩家按住按钮进行蓄力，蓄力时间影响攻击效果
@export var attack_charge_time: float

## [充能] 充能类型
## 充能累积的跟踪方式
## - MANDATORY：必须充满才能发射
## - OPTIONAL：可以选择不充满就发射
## - CANCEL：可以选择取消蓄力
@export var charge_type: Attack2D.AttackChargeType = Attack2D.AttackChargeType.MANDATORY

## [充能] 充能触发条件
## 充能完成的触发条件
## - ON_READY：准备好时触发
## - ON_INPUT：按下输入时触发
## - ON_RELEA：松开输入时触发
@export var charge_trigger: Attack2D.AttackChargeTrigger = Attack2D.AttackChargeTrigger.ON_READY
@export_group("")


@export_group("定时投射物")
## [定时] 生成类型
## 有多个投射物实例时的生成方式
## - ALL_AT_ONCE：所有投射物实例同时生成
## - ONE_BY_ONE：投射物实例依次生成，有延迟
@export var spawn_type: Attack2D.InstancesSpawnType = Attack2D.InstancesSpawnType.ALL_AT_ONCE:
	set(value):
		spawn_type = value
		notify_property_list_changed()

## [定时] 执行类型（ONE_BY_ONE 专属性）
## ONE_BY_ONE 类型攻击的继续条件
## - MANDATORY：必须完成所有投射物发射
## - OPTIONAL：可以选择提前结束
@export var execution_type: Attack2D.ExecutionType = Attack2D.ExecutionType.MANDATORY

## [定时] 中断继续类型（ONE_BY_ONE 专属性）
## 攻击被中断后恢复时的行为
## - REFRESH_SHOTS_AND_START_FROM_ZERO：刷新所有投射物，从头开始
## - CONTINUE_IF_POSSIBLE：如果可能的话继续
## - ABORT：直接中止
@export var continuation_type: Attack2D.OnInterruptedExecutionContinuation = Attack2D.OnInterruptedExecutionContinuation.REFRESH_SHOTS_AND_START_FROM_ZERO

## [定时] 覆盖攻击时长
## 如果为 true，用投射物的 spawn_interval 值覆盖 attack_duration_time 属性
## 这允许根据投射物配置自动计算攻击时长
@export var override_attack_duration: bool = true
@export_group("")


@export_category("自定义属性")
## [自定义] 全局属性字典
## 所有由此蓝图创建的攻击共享此字典
## 修改任何一个攻击的值会影响所有其他攻击
@export var global_properties: Dictionary[StringName, Variant]

## [自定义] 个体属性字典
## 每个攻击独立的属性字典
## 修改只影响目标攻击
@export var individual_properties: Dictionary[StringName, Variant]




## ============================================================
## 构造函数和验证方法
## ============================================================


func _init() -> void:
	"""
	构造函数
	初始化所有属性的默认值
	"""
	# 主属性默认值
	attack_anticipate_time = 0
	attack_duration_time = 0.1  # 默认 0.1 秒的攻击时长
	attack_recovery_time = 0

	# 生成属性默认值
	attack_offset = Vector2.ZERO
	override_position = false
	override_direction = false

	# 充能默认值
	attack_charge_time = 0
	charge_type = Attack2D.AttackChargeType.MANDATORY
	charge_trigger = Attack2D.AttackChargeTrigger.ON_READY

	# 定时投射物默认值
	spawn_type = Attack2D.InstancesSpawnType.ALL_AT_ONCE
	execution_type = Attack2D.ExecutionType.MANDATORY
	override_attack_duration = true

	# 自定义属性默认值
	global_properties = {}
	individual_properties = {}


func _validate_property(property: Dictionary) -> void:
	"""
	属性验证器
	根据当前配置条件，隐藏不适用的编辑器属性
	使编辑器界面更清晰，只显示相关属性
	"""
	# 如果是 ALL_AT_ONCE（同时生成）模式，隐藏与 ONE_BY_ONE 相关的属性
	if property.name in ["execution_type", "continuation_type", "override_attack_duration"] && (spawn_type == Attack2D.InstancesSpawnType.ALL_AT_ONCE):
		property.usage = PROPERTY_USAGE_NO_EDITOR

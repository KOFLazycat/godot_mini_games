## GameplayEffect - 游戏效果定义资源
##
## 功能说明：
## 核心数据资源，定义游戏中的 Buff、Debuff 或即时效果
## 游戏设计师创建此资源的实例来构建游戏的技能和效果系统
##
## 使用场景：
## - 定义火球术伤害效果
## - 定义中毒持续伤害效果 (DoT)
## - 定义增益效果 (Buff)
## - 定义装备属性加成
##
## 数据流：
## GameplayEffect (静态定义) → GameplayEffectSpec (运行时) → ActiveGameplayEffect (活跃实例)
##
## @meta_addon: GodotGAS Version 1 (See plugin version for exact version)
## @meta_author: YulRun (https://YulRun.Dev)
## @meta_license: MIT

@icon("res://addons/GodotGAS/icons/godot_gas_asc.svg")
class_name GameplayEffect extends Resource

## ============================================================================
## 枚举定义
## ============================================================================

## 持续策略 - 定义效果的生命周期行为
enum DurationPolicy {
	INSTANT,    ## 即时效果：立即应用数值并消失，不能授予标签（如火球术伤害）
	DURATION,    ## 持续效果：应用数值/标签 X 秒，然后撤销（如 5 秒中毒）
	INFINITE,    ## 无限效果：永久应用数值/标签，直到显式移除（如装备的戒指）
	TURN_BASED   ## 回合制效果：持续 X 回合，由外部回合管理器处理
}

## 堆叠策略 - 定义效果的堆叠行为
enum StackingPolicy {
	FREE,            ## 自由堆叠：可以无限叠加多个相同效果
	REFRESH_DURATION ## 刷新持续时间：再次应用时刷新现有效果的计时器，而非添加新实例
}

@export_category("Effect Rules")
## ============================================================================
## 效果规则
## ============================================================================

## 堆叠策略
## 定义当效果已应用于目标时，此效果的行为
## FREE = 多个唯一堆叠，REFRESH_DURATION 刷新现有效果的持续时间
## 注意：此属性不决定效果是否会堆叠，只决定如何堆叠
@export var stacking_policy: StackingPolicy = StackingPolicy.FREE

## 持续策略
## 效果在目标上持续的时间类型
@export var policy: DurationPolicy = DurationPolicy.INSTANT

## 持续时间（秒）
## 效果的持续时间，仅在 policy 为 DURATION 时使用
@export_range(0.0, 9999.0, 0.1, "or_greater") var duration: float = 0.0:
	set(value):
		duration = maxf(0.0, value)

## 周期（秒）
## 周期性修饰器的间隔时间
## 注意：周期性修饰器是永久性的，效果结束时不会撤销
## 注意：对于回合制效果，设置为 1.0 表示这是 DoT（持续伤害），而非 Buff
@export_range(0.0, 999.0, 0.1, "or_greater") var period: float = 0.0

@export_category("Turn Based Settings")
## ============================================================================
## 回合制设置
## ============================================================================

## 持续回合数
## 效果持续的回合数，仅在 policy 为 TURN_BASED 时使用
@export_range(1, 999) var duration_turns: int = 1

## 回合开始时触发
## 如果为 true，周期性效果（period > 0）在回合推进时触发其数值和 Cue
@export var tick_on_turn_start: bool = true

@export_category("Application Requirements")
## ============================================================================
## 应用条件
## ============================================================================

## 应用必需标签
## 目标必须拥有所有这些标签，效果才能应用
## 例如：需要 'Status.Burning' 状态才能应用 'Explode'（爆炸）效果
@export var application_required_tags: Array[StringName] = []

## 应用忽略标签
## 目标不能拥有任何这些标签。如果拥有，效果将被阻止
## 例如：目标有 'Status.Immune.Poison'，则阻止毒系效果
@export var application_ignore_tags: Array[StringName] = []

@export_category("Cue Management")
## ============================================================================
## Cue 管理
## ============================================================================

## 应用 Cue 标签
## 效果首次应用于目标时精确播放一次的 Cue
@export var application_cue_tags: Array[StringName] = []

## 周期性 Cue 标签
## 每次周期性触发时播放的 Cue
@export var periodic_cue_tags: Array[StringName] = []

@export_category("Attribute Modifiers")
## ============================================================================
## 属性修饰器
## ============================================================================

## 执行计算
## 自定义数学脚本，执行复杂逻辑（如 伤害 = 攻击者攻击力 - 目标防御力）
@export var executions: Array[GameplayExecutionCalculation] = []

## 修饰器列表
## 效果对目标的 AttributeSet 应用的简单数学修改
@export var modifiers: Array[GameplayEffectModifier] = []

@export_category("State Management")
## ============================================================================
## 状态管理
## ============================================================================

## 移除效果标签
## 如果此效果成功应用，将立即清除目标上任何授予这些标签的现有效果
## 例如：'治疗' 药水会在此处列出 'Status.Poison'
@export var remove_effects_with_tags: Array[StringName] = []

## 授予标签
## 只要此效果处于活动状态，就授予目标 ASC 的标签
## 不用于事件，而是用于状态（如 'Status.Stunned'）
## 注意：即时效果不会授予标签
@export var granted_tags: Array[StringName] = []

@export_category("Event Management")
## ============================================================================
## 事件管理
## ============================================================================

## 事件标签
## 在应用（或周期性触发）时作为游戏事件直接广播到目标 ASC 的标签
## 非常适合唤醒反应性被动技能（如 'Event.Damage.Taken'）
@export var event_tags: Array[StringName] = []

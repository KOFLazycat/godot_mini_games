## GameplayEffectSpec - 游戏效果规格（运行时）
##
## 功能说明：
## 将静态的 GameplayEffect 定义与应用的特定上下文（发起者、目标、等级）结合的运行时负载
##
## 数据流：
## GameplayEffect (静态定义) → GameplayEffectSpec (运行时包装) → 应用到 ASC
##
## 使用场景：
## - 技能释放时创建效果规格
## - 效果执行时传递上下文信息
## - 允许 ExecCalcs 修改效果参数
##
## 特点：
## - 是 RefCounted，无需手动释放
## - 可以在应用前修改 duration、period、magnitudes
## - 存储计算后的数值变化 (calculated_deltas)
##
## @meta_addon: GodotGAS Version 1 (See plugin version for exact version)
## @meta_author: YulRun (https://YulRun.Dev)
## @meta_license: MIT

@icon("res://addons/GodotGAS/icons/godot_gas_asc.svg")
class_name GameplayEffectSpec extends RefCounted

## ============================================================================
## 核心属性
## ============================================================================

## 效果定义
## 静态的数据定义（已有的资源）
var effect_def: GameplayEffect

## 上下文
## 运行时负载，包含发起者、施加者和目标数据
var context: GameplayEffectContext

## 等级
## 技能/效果的等级，用于后续缩放数学修饰器
var level: float = 1.0

## 应用时间
## 效果应用的确切时间（用于持续时间计算）
var application_time: float = 0.0

## 动态标签
## 由 ExecCalcs 或 Abilities 在运行时动态注入的标签
## 用于：在计算过程中注入 'Critical'、'Dodge' 等标签
var dynamic_tags: Array[StringName] = []

## 计算后的数值变化
## ASC 应用修饰器后填充的字典，存储精确的最终夹紧变化
## 格式：{ "Health": -50.0, "Mana": -10.0 }
var calculated_deltas: Dictionary = {}

# ============================================================================
## 可变状态（真实数据源）
# ============================================================================

## 运行时持续时间
## 效果的运行时持续时间，在应用前由 ExecCalcs 变异
var duration: float = 0.0

## 运行时回合持续时间
## 效果的回合制持续时间，在应用前由 ExecCalcs 变异
var remaining_turns: int = 0

## 运行时周期
## 效果的运行时周期，在应用前由 ExecCalcs 变异
var period: float = 0.0

## 变异的修饰器数值
## 字典跟踪每个修饰器的运行时数值
## 键：属性名（String），值：修饰值（float）
var mutated_magnitudes: Dictionary = {}
# ============================================================================


#region Initialization
## ============================================================================
## 初始化
## ============================================================================

## 构造函数
##
## 初始化活跃效果实例并快照可变状态
##
## @param in_effect - GameplayEffect 静态定义
## @param in_context - GameplayEffectContext 运行时上下文
## @param in_level - 技能/效果等级
func _init(in_effect: GameplayEffect, in_context: GameplayEffectContext, in_level: float = 1.0) -> void:
	## 设置基础属性
	effect_def = in_effect
	context = in_context
	level = in_level

	## 记录应用时间（毫秒转秒）
	application_time = Time.get_ticks_msec() / 1000.0

	## 将基础资源数据快照到可变变量
	duration = in_effect.duration
	period = in_effect.period
	remaining_turns = in_effect.duration_turns

	## 预计算并快照基础修饰器数值，以便 ExecCalcs 可以变异它们
	for mod in in_effect.modifiers:
		if mod and mod.attribute_name != "":
			mutated_magnitudes[mod.attribute_name] = mod.calculate_magnitude(level)
#endregion


#region Context Helpers
## ============================================================================
## 上下文辅助方法
## ============================================================================

## 获取目标节点
##
## 快速从附加的上下文获取唯一目标节点
## @return - 目标节点数组
func get_target_nodes() -> Array[Node]:
	if context and context.target_data:
		return context.target_data.get_target_nodes()

	return []

## 检查是否有标签
##
## 便捷方法：检查规格是否原生或动态拥有某个标签
## @param tag - 要检查的标签
## @return - 如果有标签返回 true
func has_tag(tag: StringName) -> bool:
	## 假设基础效果有一个标识符标签数组如 'asset_tags' 或 'granted_tags'
	if effect_def.granted_tags.has(tag):
		return true
	return dynamic_tags.has(tag)

## 注入标签
##
## 便捷方法：将标签注入我们的动态标签数组
## 用于：在执行计算期间应用 'Critical'、'Dodge' 等标签
## @param tag - 要注入的标签
func inject_tag(tag: StringName) -> void:
	if not dynamic_tags.has(tag):
		dynamic_tags.append(tag)
#endregion

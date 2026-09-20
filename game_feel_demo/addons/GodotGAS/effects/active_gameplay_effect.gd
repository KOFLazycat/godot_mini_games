## ActiveGameplayEffect - 活跃游戏效果实例
##
## 功能说明：
## 跟踪当前应用于 ASC 的 GameplayEffectSpec 的运行时实例
## 管理活跃效果的状态、持续时间和周期性触发
## 同时记录应用的修饰器，以便效果结束时可以安全地撤销
##
## 数据流：
## GameplayEffectSpec (运行时) → ActiveGameplayEffect (活跃实例) → 存储在 ASC._active_effects
##
## 使用场景：
## - 跟踪持续效果（Buff/Debuff）
## - 管理效果持续时间
## - 处理周期性触发（DoT/HoT）
## - 效果结束时撤销数值变化
##
## 特点：
## - 是 RefCounted，无需手动释放
## - 记录 applied_deltas 用于精确撤销
## - 跟踪剩余时间用于效果过期
##
## @meta_addon: GodotGAS Version 1 (See plugin version for exact version)
## @meta_author: YulRun (https://YulRun.Dev)
## @meta_license: MIT

@icon("res://addons/GodotGAS/icons/godot_gas_asc.svg")
class_name ActiveGameplayEffect extends RefCounted

## ============================================================================
## 核心属性
## ============================================================================

## 效果规格
## 正在应用的效果的活跃包装版本
## 安全地保存 Context、目标数据、等级和基础定义
var spec: GameplayEffectSpec

## 应用后的数值变化
## 跟踪此效果应用的确切数学变化的字典
## 用于效果过期或清除时完美地撤销数学计算
## 格式：{ "attribute_name": 变化量 }
## 示例：{ "Health": -50.0, "AttackPower": 10.0 }
var applied_deltas: Dictionary = {}

## 剩余时间
## 效果的剩余持续时间
var time_remaining: float = 0.0

## 下次触发时间
## 跟踪到下一次周期性触发剩余时间的内部时钟
var time_until_next_tick: float = 0.0


#region Initialization
## ============================================================================
## 初始化
## ============================================================================

## 构造函数
##
## @param in_spec - GameplayEffectSpec 运行时规格
func _init(in_spec: GameplayEffectSpec) -> void:
	spec = in_spec

	## 获取效果定义
	var effect = spec.effect_def

	## 如果是持续效果，初始化剩余时间
	if effect.policy == GameplayEffect.DurationPolicy.DURATION:
		time_remaining = spec.duration

	## 如果有周期性，初始化触发计时器
	if spec.period > 0.0:
		time_until_next_tick = spec.period
#endregion


#region QoL Helpers
## ============================================================================
## 便捷辅助方法
## ============================================================================

## 获取效果定义
##
## 快速访问基础资源定义
## @return - GameplayEffect 静态定义
func get_effect_def() -> GameplayEffect:
	return spec.effect_def if spec else null


## 获取发起者
##
## 快速访问施放此效果的实体
## @return - 发起者节点
func get_instigator() -> Node:
	if spec and spec.context and spec.context.instigator:
		return spec.context.instigator

	return null


## 获取目标节点
##
## 快速获取发射时捕获的唯一目标
## @return - 目标节点数组
func get_target_nodes() -> Array[Node]:
	if spec and spec.context and spec.context.target_data:
		return spec.context.target_data.get_target_nodes()

	return []
#endregion

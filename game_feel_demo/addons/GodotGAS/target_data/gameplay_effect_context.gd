## GameplayEffectContext - 游戏效果上下文
##
## 功能说明：
## 存储效果/技能的来源信息的数据容器
## 将发起者、施加者和目标数据包装成一个对象，安全地传递到执行流程中
##
## 数据流：
## 技能/效果创建 → GameplayEffectContext → GameplayEffectSpec → 应用到目标
##
## 使用场景：
## - 造成伤害时记录伤害来源
## - 追踪治疗效果的施法者
## - AOE技能需要知道所有命中的目标
## - 反击技能需要知道是谁攻击了自己
##
## @meta_addon: GodotGAS Version 1 (See plugin version for exact version)
## @meta_author: YulRun (https://YulRun.Dev)
## @meta_license: MIT

@icon("res://addons/GodotGAS/icons/godot_gas_asc.svg")
class_name GameplayEffectContext extends RefCounted

## ============================================================================
## 核心属性
## ============================================================================

## 发起者
## 激活技能或造成效果的主要实体（如玩家角色、AI敌人）
## 通常是具有 AbilitySystemComponent 的角色节点
var instigator: Node

## 施加者
## 实际造成效果的物理实体（如火球投射物、武器陷阱等）
## 如果没有次要施加者，默认等于 instigator
## 例如：玩家发射火球，instigator = 玩家，causer = 火球投射物
var causer: Node

## 目标数据
## 包含技能命中的所有目标信息
## 包括：目标节点列表、命中位置、碰撞信息等
var target_data: GameplayAbilityTargetData


#region Initialization
## ============================================================================
## 初始化
## ============================================================================

## 构造函数
##
## @param _instigator - 发起者（必填）
## @param _causer - 施加者（可选，默认等于 instigator）
func _init(_instigator: Node, _causer: Node = null) -> void:
	instigator = _instigator

	## 如果没有指定施加者，使用发起者作为施加者
	causer = _causer if _causer else _instigator

	## 初始化空的目标数据（后续需要手动填充）
	target_data = GameplayAbilityTargetData.new()
#endregion


#region Payload Helpers
## ============================================================================
## 辅助方法
## ============================================================================

## 检查是否有有效目标
##
## 用途：快速检查是否成功捕获到任何目标
## @return - 如果有目标返回 true，否则返回 false
func has_targets() -> bool:
	return target_data != null and not target_data.get_target_nodes().is_empty()


## 获取目标节点列表
##
## 用途：快速获取所有唯一的目标节点
## @return - 目标节点数组
func get_target_nodes() -> Array[Node]:
	return target_data.get_target_nodes() if target_data else []
#endregion

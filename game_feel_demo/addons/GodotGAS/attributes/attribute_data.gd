## AttributeData - 单个属性数据容器
##
## 功能说明：
## 用于存储单个游戏属性的基础值和当前值
## - base_value: 永久性的基础值（不受Buff/Debuff影响）
## - current_value: 临时的当前值（受Buff/Debuff影响）
##
## 使用场景：
## - 定义角色的生命值、魔法值、攻击力等属性
## - 属性发生变化时，自动同步 base_value 和 current_value
##
## @meta_addon: GodotGAS Version 1 (See plugin version for exact version)
## @meta_author: YulRun (https://YulRun.Dev)
## @meta_license: MIT

@tool
@icon("res://addons/GodotGAS/icons/godot_gas_asc.svg")
class_name AttributeData extends Resource

## ============================================================================
## 属性说明
## ============================================================================

## 基础值（永久性）
## 永久性的基础属性值，不受临时Buff/Debuff影响
## 例如：角色裸装的最大生命值
@export var base_value: float = 0.0 : set = _set_base_value

## 当前值（临时性）
## 临时的当前属性值，受Buff/Debuff影响
## 例如：角色穿上装备后的实际生命值
@export var current_value: float = 0.0


#region Initialization
## ============================================================================
## 初始化
## ============================================================================

## 构造函数
## @param initial_value - 属性的初始值
func _init(initial_value: float = 0.0) -> void:
	## 初始化时，基础值和当前值相同
	base_value = initial_value
	current_value = initial_value
#endregion


#region Setters & Math
## ============================================================================
## 设置器和数学方法
## ============================================================================

## 基础值设置器
## 当 base_value 发生变化时调用（如升级时）
## 目前逻辑：直接同步 current_value 到新的 base_value
## 未来计划：在这里添加重新应用 GameplayEffects 的逻辑
##
## @param new_value - 新的基础值
func _set_base_value(new_value: float) -> void:
	base_value = new_value

	## 当基础值变化时（如升级），同步当前值
	## 未来会在这里添加重新应用效果的功能
	current_value = new_value
#endregion

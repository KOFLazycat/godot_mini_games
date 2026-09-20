## AttributeSet - 属性集基类
##
## 功能说明：
## 属性集的基类，用于定义和管理一组相关的属性
## 不要直接实例化此类，应该继承它来定义特定的属性集
##
## 使用场景：
## - 创建生命值属性集 (HealthAttributeSet)
## - 创建战斗属性集 (CombatAttributeSet)
## - 创建资源属性集 (ResourceAttributeSet)
##
## 示例：
## class_name HealthAttributeSet
## extends AttributeSet
##
## var health: AttributeData
## var max_health: AttributeData
##
## func _init():
##     health = AttributeData.new(100)
##     max_health = AttributeData.new(100)
##
## @meta_addon: GodotGAS Version 1 (See plugin version for exact version)
## @meta_author: YulRun (https://YclRun.Dev)
## @meta_license: MIT

@tool @abstract
@icon("res://addons/GodotGAS/icons/godot_gas_asc.svg")
class_name AttributeSet extends Resource


#region Core Virtuals
## ============================================================================
## 核心虚函数
## ============================================================================

## 属性值修改前回调
##
## 调用时机：在 ASC 修改属性的 current_value 之前调用
## 用途：允许 AttributeSet 拦截并修改传入的值（如 Clamp 限制范围）
##
## 使用示例：
## - 限制生命值在 0 到 max_health 之间
## - 护盾吸收伤害逻辑
## - 特殊状态下的属性限制
##
## @param attribute_name - 属性名称
## @param proposed_value - 提议的新值
## @return - 允许修改后的值
func pre_attribute_change(attribute_name: String, proposed_value: float) -> float:
	## 默认实现：不做任何修改，直接返回提议的值
	return proposed_value


## 属性值修改后回调
##
## 调用时机：在 ASC 修改属性的 current_value 之后调用
## 用途：响应属性变化后的逻辑（如最大生命值降低时调整当前生命值）
##
## 使用示例：
## - 当 max_health 降低到 current_health 以下时，减少 current_health
## - 属性变化时的特效播放
## - 记录属性变化日志
##
## @param asc - 拥有此 AttributeSet 的 AbilitySystemComponent 节点
## @param attribute_name - 属性名称
## @param old_value - 旧值
## @param new_value - 新值
func post_attribute_change(asc: Node, attribute_name: String, old_value: float, new_value: float) -> void:
	## 默认实现：不做任何操作
	pass
#endregion

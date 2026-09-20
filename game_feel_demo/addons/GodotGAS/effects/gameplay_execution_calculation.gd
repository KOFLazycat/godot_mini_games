## GameplayExecutionCalculation - 执行计算基类
##
## 功能说明：
## GodotGAS 框架中自定义数学计算的基类
## 重写 execute() 函数执行复杂的战斗数学计算
##
## 使用场景：
## - 自定义伤害公式：伤害 = 攻击力 - 防御力
## - 暴击计算：基于敏捷属性的暴击率
## - 护盾计算：伤害护盾吸收逻辑
## - 复杂的多段伤害
##
## 实现示例：
## class_name DamageExecution
## extends GameplayExecutionCalculation
##
## func execute(spec, target_asc):
##     var attacker = spec.context.instigator
##     var attacker_asc = attacker.get_node("AbilitySystemComponent")
##     var attack_power = attacker_asc.get_attribute("Attack").current_value
##     var defense = target_asc.get_attribute("Defense").current_value
##     var damage = attack_power - defense * 0.5
##     return {"Health": -max(1.0, damage)}
##
## @meta_addon: GodotGAS Version 1 (See plugin version for exact version)
## @meta_author: YulRun (https://YulRun.Dev)
## @meta_license: MIT

@abstract
@icon("res://addons/GodotGAS/icons/godot_gas_asc.svg")
class_name GameplayExecutionCalculation extends Resource


#region Execution
## ============================================================================
## 执行方法
## ============================================================================

## 执行计算
##
## 接收活跃的效果规格和目标的 ASC
## 返回要应用到目标属性的精确数值变化的字典
##
## 返回格式：{ "attribute_name": flat_delta_amount }
## 示例：{ "Health": -50.0, "Mana": -10.0 }
##
## @param spec - 活跃的 GameplayEffectSpec，包含效果定义、上下文、等级等信息
## @param target_asc - 目标实体的 AbilitySystemComponent
## @return - 属性名到数值变化的字典
func execute(spec: GameplayEffectSpec, target_asc: AbilitySystemComponent) -> Dictionary:
	push_error("GodotGAS: execute() 在基类 GameplayExecutionCalculation 上调用。你必须在具体的子类脚本中重写此方法。")
	return {}
#endregion

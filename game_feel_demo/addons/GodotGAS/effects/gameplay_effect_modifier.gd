## GameplayEffectModifier - 效果修饰器
##
## 功能说明：
## 定义游戏效果如何修改属性的数学规则
## 支持固定值和基于等级的曲线缩放
##
## 使用场景：
## - 固定伤害：-50 生命值
## - 百分比加成：攻击力 +50%
## - 等级缩放：根据角色等级调整属性
##
## 数学运算示例：
## - ADD: 基础值 + 修饰值
## - MULTIPLY: 基础值 * 修饰值
## - DIVIDE: 基础值 / 修饰值
## - OVERRIDE: 完全替换为修饰值
##
## @meta_addon: GodotGAS Version 1 (See plugin version for exact version)
## @meta_author: YulRun (https://YulRun.Dev)
## @meta_license: MIT

@icon("res://addons/GodotGAS/icons/godot_gas_asc.svg")
class_name GameplayEffectModifier extends Resource

## ============================================================================
## 枚举定义
## ============================================================================

## 操作类型 - 定义应用于属性的数学运算
enum Operation {
	ADD,       ## 加法：添加修饰值（使用负值进行伤害/减少）
	MULTIPLY,  ## 乘法：乘以当前值（如 1.5 表示 +50%）
	DIVIDE,    ## 除法：除以当前值
	OVERRIDE   ## 覆盖：完全用修饰值替换当前值
}

## ============================================================================
## 导出参数
## ============================================================================

## 属性名称
## AttributeSet 中属性的确切变量名（如 "health" 或 "mana"）
@export var attribute_name: String = ""

## 操作类型
## 数学运算的应用方式
@export var operation: Operation = Operation.ADD

@export_category("Magnitude Calculation")
## ============================================================================
## 数值计算
## ============================================================================

## 修饰值
## 如果没有提供曲线，则使用固定数值
## 如果提供了曲线，此值作为曲线输出的乘数
@export var magnitude: float = 0.0

## 缩放曲线（可选）
## Godot Curve 资源
## X 轴是角色等级，Y 轴是修饰器的基础值
@export var scaling_curve: Curve


#region Math Evaluation
## ============================================================================
## 数学计算方法
## ============================================================================

## 计算修饰器的最终数值
##
## 根据角色等级计算修饰器的最终数值
## 如果有曲线：对曲线采样并乘以基础值
## 如果无曲线：返回固定值
##
## @param level - 角色等级
## @return - 最终计算出的修饰值
func calculate_magnitude(level: float = 1.0) -> float:
	if scaling_curve:
		## Godot 曲线默认在 X=0.0 到 X=1.0 之间评估
		## 但如果曲线域设置正确，我们可以采样超过 1.0
		## 我们对曲线采样，然后乘以基础值
		var curve_value = scaling_curve.sample(level)
		return curve_value * magnitude

	## 如果没有曲线，返回固定的静态数值
	return magnitude
#endregion

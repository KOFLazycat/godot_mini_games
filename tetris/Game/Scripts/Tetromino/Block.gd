## 单个方块单元格类
## 当俄罗斯方块锁定到场地后，每个单元格会转换为Block对象存储
class_name Block
extends RefCounted

## 方块的颜色
var color: Color

## 构造函数
## @param c 方块的显示颜色
func _init(c: Color) -> void:
	self.color = c

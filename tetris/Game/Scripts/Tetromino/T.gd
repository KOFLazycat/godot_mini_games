## T型方块
## 颜色：紫色(PURPLE)
## 形状：3x3矩阵
class_name T 
extends Tetromino

## 方块颜色
const COLOR: Color = Color.PURPLE

## 0度状态 - T字形
const STATE_0: Array[Array] = 	[[0, 1, 0],
								[1, 1, 1],
								[0, 0, 0]]

## 90度状态（顺时针旋转一次）
const STATE_R: Array[Array] = 	[[0, 1, 0],
								[0, 1, 1],
								[0, 1, 0]]

## 180度状态
const STATE_2: Array[Array] = 	[[0, 0, 0],
								[1, 1, 1],
								[0, 1, 0]]

## 270度状态
const STATE_L: Array[Array] = 	[[0, 1, 0],
								[1, 1, 0],
								[0, 1, 0]]

## 构造函数，初始化方块的4个旋转状态
func _init() -> void:
	state_array = [STATE_0, STATE_R, STATE_2, STATE_L]

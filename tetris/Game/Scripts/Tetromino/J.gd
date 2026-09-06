## J型方块
## 颜色：蓝色(BLUE)
## 形状：3x3矩阵
class_name J 
extends Tetromino

## 方块颜色
const COLOR: Color = Color.BLUE

## 0度状态 - 类似于字母J的形状
const STATE_0: Array[Array] = 	[[1, 0, 0],
								[1, 1, 1],
								[0, 0, 0]]

## 90度状态（顺时针旋转一次）
const STATE_R: Array[Array] = 	[[0, 1, 1],
								[0, 1, 0],
								[0, 1, 0]]

## 180度状态
const STATE_2: Array[Array] = 	[[0, 0, 0],
								[1, 1, 1],
								[0, 0, 1]]

## 270度状态
const STATE_L: Array[Array] = 	[[0, 1, 0],
								[0, 1, 0],
								[1, 1, 0]]

## 构造函数，初始化方块的4个旋转状态
func _init() -> void:
	state_array = [STATE_0, STATE_R, STATE_2, STATE_L]

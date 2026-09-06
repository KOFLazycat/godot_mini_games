## I型方块（长条）
## 颜色：青色(CYAN)
## 形状：4x4矩阵
class_name I extends Tetromino

## 方块颜色
const COLOR: Color = Color.CYAN

## 0度状态（水平）
const STATE_0: Array[Array] = 	[[0, 0, 0, 0],
								[1, 1, 1, 1],
								[0, 0, 0, 0],
								[0, 0, 0, 0]]

## 90度状态（顺时针旋转一次）
const STATE_R: Array[Array] = 	[[0, 0, 1, 0],
								[0, 0, 1, 0],
								[0, 0, 1, 0],
								[0, 0, 1, 0]]

## 180度状态（水平，但位置不同）
const STATE_2: Array[Array] = 	[[0, 0, 0, 0],
								[0, 0, 0, 0],
								[1, 1, 1, 1],
								[0, 0, 0, 0]]

## 270度状态（垂直）
const STATE_L: Array[Array] = 	[[0, 1, 0, 0],
								[0, 1, 0, 0],
								[0, 1, 0, 0],
								[0, 1, 0, 0]]

## 构造函数，初始化方块的4个旋转状态
func _init() -> void:
	state_array = [STATE_0, STATE_R, STATE_2, STATE_L]

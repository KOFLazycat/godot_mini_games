## O型方块（正方形）
## 颜色：黄色(YELLOW)
## 形状：4x3矩阵（注意：O型方块旋转后形状不变）
class_name O extends Tetromino

## 方块颜色
const COLOR: Color = Color.YELLOW

## 0度状态 - 2x2正方形，位于矩阵右侧
const STATE_0: Array[Array] = 	[[0, 1, 1, 0],
								[0, 1, 1, 0],
								[0, 0, 0, 0]]

## 90度状态 - 与0度相同（O型方块旋转对称）
const STATE_R: Array[Array] = 	[[0, 1, 1, 0],
								[0, 1, 1, 0],
								[0, 0, 0, 0]]

## 180度状态 - 与0度相同
const STATE_2: Array[Array] = 	[[0, 1, 1, 0],
								[0, 1, 1, 0],
								[0, 0, 0, 0]]

## 270度状态 - 与0度相同
const STATE_L: Array[Array] = 	[[0, 1, 1, 0],
								[0, 1, 1, 0],
								[0, 0, 0, 0]]

## 构造函数，初始化方块的4个旋转状态
func _init() -> void:
	state_array = [STATE_0, STATE_R, STATE_2, STATE_L]

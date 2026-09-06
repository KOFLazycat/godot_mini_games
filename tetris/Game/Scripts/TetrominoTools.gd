## 全局工具类
## 提供游戏级别的静态方法和常量
class_name TetrominoTools
extends Object

## 游戏结束类型枚举
enum GameOverType {
	OVERLAPPED, ## 方块重叠 - 当新生成的方块与场地中已有方块重叠时触发
	OVERFLOW, ## 方块溢出 - 当方块锁定位置超出场地容量时触发
}

## 绘制俄罗斯方块到画布
## @param canvas_item 画布项（Node2D或Control），用于绘制方块
## @param tetromino 俄罗斯方块对象
## @param coordinates 绘制位置的坐标（以格子为单位）
## @param color 可选参数，自定义颜色（如果不指定则使用方块默认颜色）
static func draw_tetromino(canvas_item: CanvasItem, tetromino: Tetromino,
	coordinates: Vector2i = Vector2i.ZERO, color: Color = Color.TRANSPARENT) -> void:

	# 如果未指定颜色，使用方块的默认颜色
	if color == Color.TRANSPARENT:
		color = tetromino.COLOR

	# 获取方块的形状矩阵
	var blocks: Array = tetromino.get_blocks()

	# 遍历方块的每个单元格
	for row in blocks.size():
		for col: int in blocks[row].size():
			# 只绘制值为1的单元格（即方块占据的位置）
			if (blocks[row][col]):
				# 计算绘制位置
				# 注意：Godot的2D坐标系y轴向下为正，但游戏中通常y轴向上为正
				# 这里使用 -row 来反转y轴方向，使方块向上堆叠
				var l_t_point: Vector2 = Vector2(col + coordinates.x, -row + 1 + coordinates.y) \
					* Vector2(PlayField.CELL_WIDTH, -PlayField.CELL_WIDTH)
				var size: Vector2 = Vector2(PlayField.CELL_WIDTH, PlayField.CELL_WIDTH)
				# 创建矩形并收缩1像素作为边框间距
				var rect: Rect2 = Rect2(l_t_point, size).grow(-1)
				canvas_item.draw_rect(rect, color)

## 游戏场地（PlayField）
## 继承自Node2D，负责绘制和管理游戏场地
## 场地是一个二维网格，存储已锁定的方块信息
@tool
class_name PlayField extends Node2D

## 信号：当消除行时发出，参数为消除的行数
signal cleared(lines: int)

## 单元格宽度（像素）
const CELL_WIDTH = 25
## 单元格边框线宽
const CELL_line_WIDTH = 2

## 天花板高度
## 场地中颜色较深的有效游戏区域行数（1~20行）
const CEILING = 20
## 缓冲区高度
## 场上方用于临时存放方块的区域（3行），超出此区域则游戏结束
const BUFFER_ZONE_HEIGHT = 3

## 场地水平容量（列数）
const H_CAPACITY = 10
## 场地垂直容量（行数）
## 等于天花板高度 + 缓冲区高度
const V_CAPACITY = CEILING + BUFFER_ZONE_HEIGHT


## 二维数组，存储场地中的方块（Block）信息
## 索引方式：_playfield[y][x]，y为行（从下往上），x为列（从左往右）
## 存储内容：null表示空，Block对象表示已锁定的方块
var _playfield: Array[Array] = []

## 构造函数，初始化空场地
func _init() -> void:
	_playfield.clear()
	# 创建V_CAPACITY行，每行H_CAPACITY列的二维数组
	for row in V_CAPACITY:

		var row_array: Array[Block] = []
		for col in H_CAPACITY:
			row_array.append(null)

		_playfield.append(row_array)


## 绘制方法，每帧调用
func _draw() -> void:
	_draw_grid()
	_draw_blocks()


## 绘制网格线
func _draw_grid() -> void:
	# 计算网格线的起点和终点
	var l_to_r: Vector2 = H_CAPACITY * Vector2.RIGHT * CELL_WIDTH
	var b_to_t: Vector2 = CEILING * Vector2.UP * CELL_WIDTH

	# 存储线条点对
	var line_points:PackedVector2Array = PackedVector2Array()

	# 绘制垂直线（列分隔线）
	for i in H_CAPACITY + 1:
		var bottom_point: Vector2 = i * Vector2.RIGHT * CELL_WIDTH
		var top_point: Vector2 = bottom_point + b_to_t
		line_points.append(bottom_point)
		line_points.append(top_point)

	# 绘制水平线（行分隔线）
	for i in CEILING + 1:
		var left_point: Vector2 = i * Vector2.UP * CELL_WIDTH
		var right_point: Vector2 = left_point + l_to_r
		line_points.append(left_point)
		line_points.append(right_point)

	# 设置颜色（半透明白色）
	var c: Color = Color.WHITE
	c.a = 0.6

	# 绘制游戏区域网格
	draw_multiline(line_points, c, CELL_line_WIDTH)

	# 缓冲区网格线
	var line_points_2:PackedVector2Array = PackedVector2Array()
	for i in H_CAPACITY + 1:
		var bottom_point: Vector2 = i * Vector2.RIGHT * CELL_WIDTH + b_to_t
		var top_point: Vector2 = bottom_point + BUFFER_ZONE_HEIGHT * Vector2.UP * CELL_WIDTH
		line_points_2.append(bottom_point)
		line_points_2.append(top_point)

	for i in BUFFER_ZONE_HEIGHT:
		var left_point: Vector2 = (i + CEILING + 1) * Vector2.UP * CELL_WIDTH
		var right_point: Vector2 = left_point + l_to_r
		line_points_2.append(left_point)
		line_points_2.append(right_point)

	# 设置缓冲区颜色（更淡的白色）
	var color: Color = Color.WHITE
	color.a = 0.2

	draw_multiline(line_points_2, color, CELL_line_WIDTH)


## 绘制场地中已锁定的方块
func _draw_blocks() -> void:
	for row in _playfield.size():
		for col in _playfield[row].size():
			var block: Block = _playfield[row][col]
			if block == null:
				continue
			# 计算绘制位置并收缩1像素作为边框
			var rect: Rect2 = Rect2(col * CELL_WIDTH, (row + 1) * -CELL_WIDTH, CELL_WIDTH, CELL_WIDTH).grow(-1)
			draw_rect(rect, block.color)


## 将活动方块添加到场地中
## 在方块锁定时调用，将方块的每个单元格转换为Block对象存入_playfield
## @param tetromino 俄罗斯方块对象
## @param coordinates 方块的位置坐标
func add_blocks(tetromino: Tetromino, coordinates: Vector2i) -> void:
	var blocks: Array = tetromino.getBlocks()
	for row: int in blocks.size():
		for col: int in blocks[row].size():
			# 只处理方块占据的位置（值为1）
			if (blocks[row][col]):
				# 将方块坐标转换为场地坐标
				# coordinates是方块的参考点（左上角），需要根据row和col计算实际位置
				_playfield[coordinates.y - row][coordinates.x + col] = Block.new(tetromino.COLOR)

	# 消行处理
	clear(tetromino, coordinates)
	queue_redraw()


## 检查方块是否与场地中已有方块重叠或越界
## @param tetromino 俄罗斯方块对象
## @param coordinates 待检查的位置坐标
## @return true表示重叠/越界，false表示位置合法
func is_overlap(tetromino: Tetromino, coordinates: Vector2i) -> bool:
	var blocks: Array = tetromino.getBlocks()
	for row: int in blocks.size():
		for col: int in blocks[row].size():
			if (blocks[row][col]):
				# 计算方块每个单元格在场地中的坐标
				var i: int = coordinates.x + col
				var j: int = coordinates.y - row

				# 创建场地边界矩形
				var rect: Rect2i = Rect2i(0, 0, H_CAPACITY, V_CAPACITY)

				# 检查是否在场地范围内
				if rect.has_point(Vector2i(i, j)):
					# 检查该位置是否已有方块
					if _playfield[j][i] != null:
						return true
				else:
					# 越界
					return true
	return false


## 获取方块在场地中下落到底部的锁定位置（幽灵位置）
## 用于计算硬下降的目标位置
## @param tetromino 俄罗斯方块对象
## @param start_coordinates 起始位置
## @return 方块最终可以锁定的位置
func get_lock_position(tetromino: Tetromino, start_coordinates: Vector2i) -> Vector2i:
	# 从起始位置开始向下探测，直到遇到阻碍
	# I型方块从第23行到第1行需要移动22次，加1次原地判定共23次循环
	for i in V_CAPACITY + 1:
		if is_overlap(tetromino, start_coordinates + i * Coordinates.down):
			if i == 0:
				break

			# 返回上一次合法的位置
			return start_coordinates + (i - 1) * Coordinates.down
	return start_coordinates


## 消行处理
## 检查方块所在的行是否可以消除，并处理消除逻辑
## @param tetromino 俄罗斯方块对象
## @param coordinates 方块的位置坐标
func clear(tetromino: Tetromino, coordinates: Vector2i) -> void:
	var blocks: Array = tetromino.getBlocks()
	var cleared_lines: int = 0

	# 检查方块占据的每一行
	for row in blocks.size():
		# 如果这一行有方块存在
		if blocks[row].any(func(ele: int) -> bool: return ele != 0):
			# 检查场地中对应行是否已满（所有格子都有方块）
			if _playfield[coordinates.y - row].all(func(b: Block) -> bool: return b != null):
				line_clear(coordinates.y - row)
				cleared_lines += 1

	# 如果消除了行，发出信号
	if cleared_lines != 0:
		cleared.emit(cleared_lines)


## 消除指定行
## 将该行从数组中移除，并在底部添加新行
## @param row 要消除的行号（从0开始）
func line_clear(row: int) -> void:
	# 移除该行
	var null_row: Array = _playfield.pop_at(row)
	# 将该行清空（填充null）
	null_row.fill(null)
	# 将清空后的行添加到数组末尾（底部）
	_playfield.push_back(null_row)

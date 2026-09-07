## 游戏场地（PlayField）
## 继承自Node2D，负责绘制和管理游戏场地
## 场地是一个二维网格，存储已锁定的方块信息
@tool
class_name PlayField extends Node2D

## 信号：当消除行时发出，参数为消除的行数
signal cleared(lines: int)

## 单元格宽度（像素）
const CELL_WIDTH: int = 25
## 单元格边框线宽
const CELL_LINE_WIDTH: int = 2

## 天花板高度
## 场地中颜色较深的有效游戏区域行数（1~20行）
const CEILING: int = 20
## 缓冲区高度
## 场上方用于临时存放方块的区域（3行），超出此区域则游戏结束
const BUFFER_ZONE_HEIGHT: int = 3

## 场地水平容量（列数）
const H_CAPACITY: int = 10
## 场地垂直容量（行数）
## 等于天花板高度 + 缓冲区高度
const V_CAPACITY: int = CEILING + BUFFER_ZONE_HEIGHT

## 场地边界矩形（缓存）
var _bounds: Rect2i


## 二维数组，存储场地中的方块（Block）信息
## 索引方式：_playfield[y][x]，y为行（从下往上），x为列（从左往右）
## 存储内容：null表示空，Block对象表示已锁定的方块
var _playfield: Array[Array] = []

## 构造函数，初始化空场地
func _init() -> void:
	_playfield.clear()
	_bounds = Rect2i(0, 0, H_CAPACITY, V_CAPACITY)

	for row in V_CAPACITY:
		var row_array: Array[Block] = []
		row_array.resize(H_CAPACITY)
		row_array.fill(null)
		_playfield.append(row_array)


## 绘制方法，每帧调用
func _draw() -> void:
	_drawGrid()
	_drawBlocks()


## 绘制网格线
func _drawGrid() -> void:
	#var l_to_r: Vector2 = H_CAPACITY * Vector2.RIGHT * CELL_WIDTH
	var b_to_t: Vector2 = CEILING * Vector2.UP * CELL_WIDTH

	# 绘制游戏区域网格（0.6透明度）
	var game_points: PackedVector2Array = _generateGridPoints(H_CAPACITY + 1, CEILING + 1, Vector2.ZERO)
	draw_multiline(game_points, Color(1, 1, 1, 0.6), CELL_LINE_WIDTH)

	# 绘制缓冲区网格（0.2透明度）
	var buffer_points: PackedVector2Array = _generateGridPoints(H_CAPACITY + 1, BUFFER_ZONE_HEIGHT, b_to_t)
	draw_multiline(buffer_points, Color(1, 1, 1, 0.2), CELL_LINE_WIDTH)


## 生成网格线点
## @param cols 列数+1
## @param rows 行数+1
## @param offset 偏移量
## @return 网格线点数组
func _generateGridPoints(cols: int, rows: int, offset: Vector2) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var l_to_r: Vector2 = H_CAPACITY * Vector2.RIGHT * CELL_WIDTH

	# 垂直线
	for i in cols:
		var bottom: Vector2 = i * Vector2.RIGHT * CELL_WIDTH + offset
		var top: Vector2 = bottom + rows * Vector2.UP * CELL_WIDTH
		points.append(bottom)
		points.append(top)

	# 水平线
	for i in rows:
		var left: Vector2 = i * Vector2.UP * CELL_WIDTH + offset
		var right: Vector2 = left + l_to_r
		points.append(left)
		points.append(right)

	return points


## 绘制场地中已锁定的方块
func _drawBlocks() -> void:
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
func addBlocks(tetromino: Tetromino, coordinates: Vector2i) -> void:
	var tetrominoBlocks: Array = tetromino.getBlocks()

	for row: int in tetrominoBlocks.size():
		for col: int in tetrominoBlocks[row].size():
			if tetrominoBlocks[row][col]:
				_playfield[coordinates.y - row][coordinates.x + col] = Block.new(tetromino.COLOR)

	clearLines(tetromino, coordinates)
	queue_redraw()


## 检查方块是否与场地中已有方块重叠或越界
## @param tetromino 俄罗斯方块对象
## @param coordinates 待检查的位置坐标
## @return true表示重叠/越界，false表示位置合法
func isOverlap(tetromino: Tetromino, coordinates: Vector2i) -> bool:
	var tetrominoBlocks: Array = tetromino.getBlocks()

	for row: int in tetrominoBlocks.size():
		for col: int in tetrominoBlocks[row].size():
			if tetrominoBlocks[row][col]:
				var fieldX: int = coordinates.x + col
				var fieldY: int = coordinates.y - row

				if not _bounds.has_point(Vector2i(fieldX, fieldY)):
					return true

				if _playfield[fieldY][fieldX] != null:
					return true

	return false


## 获取方块在场地中下落到底部的锁定位置（幽灵位置）
## 用于计算硬下降的目标位置
## @param tetromino 俄罗斯方块对象
## @param startCoordinates 起始位置
## @return 方块最终可以锁定的位置
func getLockPosition(tetromino: Tetromino, startCoordinates: Vector2i) -> Vector2i:
	var dropDistance: int = 0

	while dropDistance <= V_CAPACITY:
		var testPos: Vector2i = startCoordinates + dropDistance * Coordinates.down

		if isOverlap(tetromino, testPos):
			if dropDistance == 0:
				break
			return startCoordinates + (dropDistance - 1) * Coordinates.down

		dropDistance += 1

	return startCoordinates


## 消行处理
## 检查方块所在的行是否可以消除，并处理消除逻辑
## @param tetromino 俄罗斯方块对象
## @param coordinates 方块的位置坐标
func clearLines(tetromino: Tetromino, coordinates: Vector2i) -> void:
	var tetrominoBlocks: Array = tetromino.getBlocks()
	var clearedLineCount: int = 0

	for row in tetrominoBlocks.size():
		if tetrominoBlocks[row].any(func(ele: int) -> bool: return ele != 0):
			var fieldRow: int = coordinates.y - row
			if _playfield[fieldRow].all(func(b: Block) -> bool: return b != null):
				clearLine(fieldRow)
				clearedLineCount += 1

	if clearedLineCount != 0:
		cleared.emit(clearedLineCount)


## 消除指定行
## 将该行从数组中移除，并在底部添加新行
## @param row 要消除的行号（从0开始）
func clearLine(row: int) -> void:
	var removedRow: Array = _playfield.pop_at(row)
	removedRow.fill(null)
	_playfield.push_back(removedRow)

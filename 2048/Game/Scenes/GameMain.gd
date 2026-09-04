class_name GameMain
extends Control

#=====================================================================
# 常量定义
#=====================================================================
const SIZE: int = 4                      # 棋盘大小 (4x4)
const TILE_SIZE: int = 100                # 方块像素尺寸
const TILE_GAP: int = 10                  # 方块间隙
const BOARD_PAD: int = 10                 # 棋盘内边距
const ANIM_DURATION: float = 0.10          # 滑动动画时长 (秒)
const POP_DURATION: float = 0.15           # 合并/生成弹出动画时长 (秒)

#=====================================================================
# 导出变量
#=====================================================================
@export_group("Debug")
@export var debugMode: bool = false       # 是否开启调试日志

#=====================================================================
# UI 节点引用
#=====================================================================
@onready var backButton: Button = %BackButton
@onready var scoreLabel: Label = %ScoreLabel
@onready var restartButton: Button = %RestartButton
@onready var messageLabel: Label = %MessageLabel


#=====================================================================
# Tile 类 - 表示单个方块
#
# 【核心数据结构】
# 2048 游戏中的每个方块用 Tile 类表示，包含以下属性：
# - value: 方块数值，初始为 2 或 4，每次合并翻倍 (2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048...)
# - row/col: 当前在 4x4 棋盘上的网格坐标 (0-3)
# - prevRow/prevCol: 移动前的位置，用于动画插值实现平滑移动效果
# - justMerged: 标记该方块是否为刚刚合并产生的（用于触发弹出动画）
# - justSpawned: 标记该方块是否为刚刚生成的（用于触发弹出动画）
# - toRemove: 标记该方块是否已被合并消费（动画后移除）
#
# 【设计意图】
# 使用独立类而非 Node 的原因：
# 1. 轻量级：不需要 Godot 节点的开销
# 2. 快速：数组操作比场景树操作快得多
# 3. 灵活：便于实现复杂的移动和合并逻辑
#=====================================================================
class Tile:
	var value: int
	var row: int
	var col: int
	var prevRow: int
	var prevCol: int
	var justMerged: bool = false
	var justSpawned: bool = false
	var toRemove: bool = false


#=====================================================================
# 游戏状态变量
#=====================================================================
var tiles: Array[Tile] = []                # 存储所有活跃方块的数组
var score: int = 0                         # 当前累计得分
var gameOver: bool = false                  # 游戏是否已结束（无法移动）
var won: bool = false                      # 是否已达到 2048
var winShown: bool = false                  # 是否已显示过胜利提示（避免重复显示）
var animTime: float = 0.0                   # 动画已播放时间
var animating: bool = false                 # 是否正在播放动画（动画期间禁止输入）
var boardOrigin: Vector2 = Vector2.ZERO     # 棋盘在屏幕上的起始坐标（用于绘制）
var boardSize: float = 0.0                  # 棋盘总尺寸（用于绘制）


#=====================================================================
# Godot 生命周期函数
#=====================================================================

func _ready() -> void:
	randomize()
	Tools.connectSignal(backButton.pressed, onBackButton_pressed)
	Tools.connectSignal(restartButton.pressed, onRestartButton_pressed)
	if debugMode:
		Debug.printDebug("GameMain: _ready - 初始化游戏")
	_start()


func _process(delta: float) -> void:
	if animating:
		animTime += delta
		# 动画总时长 = 滑动阶段 + 弹出阶段
		# 当动画时间超过总时长时，结束动画并清理状态
		if animTime >= ANIM_DURATION + POP_DURATION:
			_endAnimation()
		queue_redraw()


func _draw() -> void:
	# Godot 的 Control 节点使用 _draw() 进行自定义渲染
	# 每次 queue_redraw() 都会调用此函数
	_computeBoardLayout()
	_drawBoard()


#=====================================================================
# 输入处理
#
# 【输入映射】
# - 方向键/WASD: 控制方块移动方向
# - R: 重新开始游戏
# - ESC: 返回欢迎页
#
# 【输入过滤】
# - 只响应 pressed 事件，忽略 echo（按住重复）
# - 使用 physical_keycode 以支持不同键盘布局
#=====================================================================

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		Key.KEY_LEFT, Key.KEY_A: _move("left")
		Key.KEY_RIGHT, Key.KEY_D: _move("right")
		Key.KEY_UP, Key.KEY_W: _move("up")
		Key.KEY_DOWN, Key.KEY_S: _move("down")
		Key.KEY_R: _start()
		Key.KEY_ESCAPE: onBackButton_pressed()


#=====================================================================
# 游戏初始化与重置
#=====================================================================

#=====================================================================
# _start: 开始/重置游戏
#
# 【游戏初始化流程】
# 1. 清空所有方块
# 2. 重置分数和游戏状态
# 3. 生成两个初始方块（2048 游戏的标配）
# 4. 触发动画显示
#
# 【初始方块规则】
# 每次游戏开始时生成两个方块，这是 2048 游戏的经典规则
# 方块值为 2（90%概率）或 4（10%概率）
#=====================================================================
func _start() -> void:
	if debugMode:
		Debug.printDebug("GameMain: _start - 开始新游戏")

	tiles.clear()
	score = 0
	gameOver = false
	won = false
	winShown = false
	messageLabel.text = ""

	# 初始生成两个方块
	_spawnTile()
	_spawnTile()

	animTime = 0.0
	animating = true
	_render()

	if debugMode:
		Debug.printDebug("GameMain: _start - 初始方块数: %d" % tiles.size())


#=====================================================================
# _endAnimation: 动画结束清理
#
# 【动画结束后的清理工作】
# 1. 关闭动画状态标志
# 2. 移除所有标记为 toRemove 的方块（被合并消费的方块）
# 3. 清除所有方块的 justMerged 和 justSpawned 标记
# 4. 触发重绘以显示最终状态
#
# 【为什么需要分两步移除方块？】
# 因为动画需要知道哪些方块应该消失（toRemove=true）
# 直接在合并时移除会导致动画无法正确显示消失效果
#=====================================================================
func _endAnimation() -> void:
	animating = false
	var i := 0
	while i < tiles.size():
		if tiles[i].toRemove:
			tiles.remove_at(i)
		else:
			tiles[i].justMerged = false
			tiles[i].justSpawned = false
			i += 1
	queue_redraw()

	if debugMode:
		Debug.printDebug("GameMain: _endAnimation - 动画结束, 方块数: %d" % tiles.size())


#=====================================================================
# 核心游戏逻辑 - 方块生成与查找
#=====================================================================

#=====================================================================
# _spawnTile: 在随机空位生成新方块
#
# 【生成算法】
# 1. 扫描整个棋盘，找出所有空位置
# 2. 从空位置中随机选择一个
# 3. 创建新方块，值为 2（90%概率）或 4（10%概率）
# 4. 将方块添加到 tiles 数组
#
# 【返回值】
# - true: 成功生成新方块
# - false: 棋盘已满，无法生成
#
# 【调用时机】
# - 游戏开始时生成两个
# - 每次有效移动后生成一个
#=====================================================================
func _spawnTile() -> bool:
	# 1. 收集所有空位置
	var empty: Array[Vector2i] = []
	for y: int in SIZE:
		for x: int in SIZE:
			if _getTileAt(x, y) == null:
				empty.append(Vector2i(x, y))

	# 2. 如果没有空位, 生成失败
	if empty.is_empty():
		if debugMode:
			Debug.printDebug("GameMain: _spawnTile - 棋盘已满, 无法生成")
		return false

	# 3. 随机选择空位
	var pos: Vector2i = empty[randi() % empty.size()]

	# 4. 创建新方块 (90% 概率为 2, 10% 概率为 4)
	var t: Tile = Tile.new()
	t.value = 4 if randf() < 0.1 else 2
	t.row = pos.y
	t.col = pos.x
	t.prevRow = pos.y
	t.prevCol = pos.x
	t.justSpawned = true

	tiles.append(t)

	if debugMode:
		Debug.printDebug("GameMain: _spawnTile - 生成方块 value=%d at (%d,%d)" % [t.value, t.col, t.row])

	return true


#=====================================================================
# _getTileAt: 获取指定位置的方块
#
# 【功能】
# 根据网格坐标 (x, y) 查找是否存在方块
#
# 【参数】
# - x: 列索引 (0-3)
# - y: 行索引 (0-3)
#
# 【返回值】
# - 如果该位置存在未标记移除的方块，返回 Tile 对象
# - 否则返回 null
#
# 【设计要点】
# 1. 忽略标记为 toRemove 的方块（这些方块只是等待动画结束）
# 2. 使用线性搜索，因为 tiles 数组通常很小（最多 16 个方块）
#=====================================================================
func _getTileAt(x: int, y: int) -> Tile:
	for t: Tile in tiles:
		if not t.toRemove and t.row == y and t.col == x:
			return t
	return null


#=====================================================================
# 核心游戏逻辑 - 移动算法
#
# 【2048 移动算法核心原理】
#
# 2048 的移动本质上是"贪心算法" + "合并操作"：
#
# 1. 【降维处理】
#    2D 棋盘被转换为 1D 线条处理
#    向左移动：每行从左到右构成一条线
#    向右移动：每行从右到左构成一条线
#    向上移动：每列从上到下构成一条线
#    向下移动：每列从下到上构成一条线
#
# 2. 【贪心滑动】
#    所有方块向移动方向的起点靠拢
#    例如向左移动：[2, _, 2, 4] → [2, 2, 4, _]
#    方块会尽可能滑到尽头
#
# 3. 【合并规则】
#    - 相同数值的相邻方块可以合并
#    - 合并后数值翻倍
#    - 每对相同值只能合并一次
#    - 合并后该位置不再参与本次移动
#    例如：[2, 2, 2, 2] 向左 → [4, 4, _, _]
#    而不是：[8, _, _, _] （不会重复合并）
#
# 4. 【关键实现】
#    使用 target 指针跟踪下一个可用的位置索引
#    每次合并或滑动后，target 前进一步
#=====================================================================

#=====================================================================
# _move: 处理方块移动的核心逻辑
#
# 【移动流程】
# 1. 检查游戏状态（游戏结束或动画中禁止移动）
# 2. 清理上一轮遗留的已合并方块
# 3. 记录所有方块的当前位置作为动画起点
# 4. 按方向将棋盘拆分为 4 条线
# 5. 对每条线执行滑动+合并算法
# 6. 如果有方块移动，生成新方块并触发动画
#
# 【参数】
# - dir: 移动方向 ("left", "right", "up", "down")
#
# 【返回值】无（直接修改 tiles 数组和 score）
#
# 【关键算法】
# - moved 标志：只有当至少有一个方块移动时才生成新方块
# - target 指针：指向下一个可用位置
# - k 指针：遍历当前线的方块
#=====================================================================
func _move(dir: String) -> void:
	# 1. 检查游戏状态
	if gameOver or animating:
		if debugMode:
			Debug.printDebug("GameMain: _move - 跳过, gameOver=%s, animating=%s" % [gameOver, animating])
		return

	if debugMode:
		Debug.printDebug("GameMain: _move - 方向: %s" % dir)

	# 2. 清理已标记移除的方块
	var i := 0
	while i < tiles.size():
		if tiles[i].toRemove:
			tiles.remove_at(i)
		else:
			i += 1

	# 3. 记录移动前的位置（用于动画插值）
	for t: Tile in tiles:
		t.prevRow = t.row
		t.prevCol = t.col
		t.justMerged = false
		t.justSpawned = false

	# 4. 按方向构建线条数据
	var moved := false
	var lines := _buildLines(dir)

	# 5. 处理每条线
	for lineIdx: int in lines.size():
		var lineTiles: Array[Tile] = lines[lineIdx]
		var target := 0       # 目标位置索引，从 0 开始
		var k := 0            # 当前遍历位置

		while k < lineTiles.size():
			# 检查是否可以合并（当前方块与下一个方块值相同）
			if k + 1 < lineTiles.size() and lineTiles[k].value == lineTiles[k + 1].value:
				# -------------------- 合并操作 --------------------
				# 两个相同值的方块合并成一个
				var newValue: int = lineTiles[k].value * 2
				var targetPos: Vector2i = _lineToPos(lineIdx, target, dir)

				# 将原两个方块移到目标位置，标记为待移除
				lineTiles[k].row = targetPos.y
				lineTiles[k].col = targetPos.x
				lineTiles[k].toRemove = true

				lineTiles[k + 1].row = targetPos.y
				lineTiles[k + 1].col = targetPos.x
				lineTiles[k + 1].toRemove = true

				# 创建合并后的新方块（数值翻倍）
				var mergedTile := Tile.new()
				mergedTile.value = newValue
				mergedTile.row = targetPos.y
				mergedTile.col = targetPos.x
				mergedTile.prevRow = targetPos.y
				mergedTile.prevCol = targetPos.x
				mergedTile.justMerged = true
				tiles.append(mergedTile)

				# 更新得分（合并后的数值）
				score += newValue
				if newValue == 2048:
					won = true

				if debugMode:
					Debug.printDebug("GameMain: _move - 合并: %d + %d = %d at (%d,%d)" % [lineTiles[k].value, lineTiles[k+1].value, newValue, targetPos.x, targetPos.y])

				target += 1        # 目标位置前进一步
				k += 2              # 跳过已合并的两个方块
				moved = true

			else:
				# -------------------- 仅滑动操作 --------------------
				# 方块向目标位置滑动
				var targetPos: Vector2i = _lineToPos(lineIdx, target, dir)

				# 检查位置是否有变化
				if lineTiles[k].row != targetPos.y or lineTiles[k].col != targetPos.x:
					moved = true

				lineTiles[k].row = targetPos.y
				lineTiles[k].col = targetPos.x
				target += 1
				k += 1

	# 6. 如果有方块移动, 生成新方块并触发动画
	if moved:
		_spawnTile()
		animTime = 0.0
		animating = true
		_updateState()
		_render()

		if debugMode:
			Debug.printDebug("GameMain: _move - 移动完成, 方块数: %d, 得分: %d" % [tiles.size(), score])


#=====================================================================
# _buildLines: 按方向构建"扁平化"的行/列数据
#
# 【核心思路】
# 将 2D 棋盘"旋转"成 1D 数组处理移动逻辑
#
# 【实现原理】
# 根据移动方向，将 4x4 棋盘拆分成 4 条"线"
# 每条线包含该方向上的所有方块，按移动起点顺序排列
#
# 【示例 - 向左移动时】
#   原棋盘:          构建的线:
#   [2][4][2][ ]      line 0: [2, 4, 2]
#   [ ][4][ ][ ]      line 1: [4]
#   [2][2][4][8]     line 2: [2, 2, 4, 8]
#   [ ][ ][ ][ ]      line 3: []
#
# 【坐标映射】
# - left:  从左到右遍历，x = pos, y = lineIdx
# - right: 从右到左遍历，x = SIZE-1-pos, y = lineIdx
# - up:    从上到下遍历，x = lineIdx, y = pos
# - down:  从下到上遍历，x = lineIdx, y = SIZE-1-pos
#
# 【返回值】
# Array[Array[Tile]] - 4 条线，每条线是包含该方向方块的数组
#=====================================================================
func _buildLines(dir: String) -> Array:
	var lines: Array[Array] = []

	for lineIdx: int in SIZE:
		var lineTiles: Array[Tile] = []

		for pos: int in SIZE:
			var x: int
			var y: int

			match dir:
				"left":
					# 从左到右遍历行
					x = pos
					y = lineIdx
				"right":
					# 从右到左遍历行（反向）
					x = SIZE - 1 - pos
					y = lineIdx
				"up":
					# 从上到下遍历列
					x = lineIdx
					y = pos
				"down":
					# 从下到上遍历列（反向）
					x = lineIdx
					y = SIZE - 1 - pos

			var t := _getTileAt(x, y)
			if t != null:
				lineTiles.append(t)

		lines.append(lineTiles)

	return lines


#=====================================================================
# _lineToPos: 将线内索引转换为棋盘坐标
#
# 【功能】
# 与 _buildLines 配合使用，把处理后的 1D 位置映射回 2D 棋盘坐标
#
# 【参数】
# - lineIdx: 线索引 (0-3)，对应行或列
# - pos: 线内位置 (0-3)，从移动起点开始计数
# - dir: 移动方向
#
# 【返回值】
# Vector2i (x, y) - 对应的棋盘网格坐标
#
# 【示例】
# 向左移动时，lineIdx=2, pos=1 表示第 3 行的第 2 个位置
# 映射回棋盘坐标 (1, 2)
#=====================================================================
func _lineToPos(lineIdx: int, pos: int, dir: String) -> Vector2i:
	match dir:
		"left": return Vector2i(pos, lineIdx)
		"right": return Vector2i(SIZE - 1 - pos, lineIdx)
		"up": return Vector2i(lineIdx, pos)
		"down": return Vector2i(lineIdx, SIZE - 1 - pos)
	return Vector2i.ZERO


#=====================================================================
# 游戏状态检查
#=====================================================================

#=====================================================================
# _updateState: 更新游戏状态
#
# 【检查内容】
# 1. 是否还有可用的移动（有空位或可合并）
# 2. 是否达到 2048（获胜条件）
#
# 【游戏结束条件】
# - 棋盘完全填满
# - 且没有任何相邻的相同数值方块可以合并
#=====================================================================
func _updateState() -> void:
	if not _hasMoves():
		gameOver = true
		messageLabel.text = "游戏结束! 按 R 重新开始"
		if debugMode:
			Debug.printDebug("GameMain: _updateState - 游戏结束!")
	elif won and not winShown:
		winShown = true
		messageLabel.text = "达到 2048! 按 R 重新开始, 或继续挑战"
		if debugMode:
			Debug.printDebug("GameMain: _updateState - 达到 2048!")


#=====================================================================
# _hasMoves: 检查是否还有可用的移动
#
# 【检查逻辑】
# 1. 首先检查是否存在空位置
#    - 如果有空位，玩家一定可以继续移动
# 2. 如果棋盘满了，检查是否存在可合并的相邻方块
#    - 右侧相邻且值相同
#    - 下方相邻且值相同
#
# 【返回值】
# - true: 还可以继续移动
# - false: 游戏结束（无法移动）
#
# 【优化】
# 一旦找到任何一个可用移动就立即返回，避免不必要的遍历
#=====================================================================
func _hasMoves() -> bool:
	# 条件 1: 存在空格
	for y: int in SIZE:
		for x: int in SIZE:
			if _getTileAt(x, y) == null:
				return true

	# 条件 2: 存在可合并的相邻方块
	for y: int in SIZE:
		for x: int in SIZE:
			var t := _getTileAt(x, y)
			if t == null:
				continue

			# 检查右侧相邻
			if x < SIZE - 1:
				var tR := _getTileAt(x + 1, y)
				if tR != null and tR.value == t.value:
					return true

			# 检查下方相邻
			if y < SIZE - 1:
				var tD := _getTileAt(x, y + 1)
				if tD != null and tD.value == t.value:
					return true

	return false


#=====================================================================
# UI 事件处理
#=====================================================================

func onBackButton_pressed() -> void:
	if debugMode:
		Debug.printDebug("GameMain: onBackButton_pressed - 返回欢迎页")
	get_tree().change_scene_to_file("res://Game/Scenes/Welcome.tscn")


func onRestartButton_pressed() -> void:
	if debugMode:
		Debug.printDebug("GameMain: onRestartButton_pressed - 重新开始")
	_start()


func _render() -> void:
	scoreLabel.text = "得分: %d" % score
	queue_redraw()


#=====================================================================
# 渲染相关函数
#=====================================================================

#=====================================================================
# _computeBoardLayout: 计算棋盘在屏幕上的布局
#
# 【功能】
# 根据视口大小计算棋盘的起始位置，实现居中显示
#
# 【布局计算】
# 1. 计算棋盘总尺寸 = 4*方块 + 3*间隙 + 2*内边距
# 2. 水平居中：board_x = (视口宽度 - 棋盘宽度) / 2
# 3. 垂直居中：在固定范围内居中
#=====================================================================
func _computeBoardLayout() -> void:
	var viewportSize: Vector2 = get_viewport_rect().size

	boardSize = SIZE * TILE_SIZE + (SIZE - 1) * TILE_GAP + BOARD_PAD * 2

	var topY := 100.0
	var bottomY := viewportSize.y - 80.0
	var availHeight := maxf(boardSize, bottomY - topY)

	var boardY := topY + (availHeight - boardSize) / 2.0
	var boardX := (viewportSize.x - boardSize) / 2.0

	boardOrigin = Vector2(boardX, boardY)


#=====================================================================
# _drawBoard: 绘制棋盘和所有方块
#
# 【绘制顺序】
# 1. 绘制棋盘背景（深棕色）
# 2. 绘制空格子背景（稍浅的棕色）
# 3. 根据动画状态绘制每个方块
#
# 【动画阶段】
# - 滑动阶段 (0 ~ ANIM_DURATION): 方块从旧位置滑向新位置
# - 弹出阶段 (ANIM_DURATION ~ ANIM_DURATION+POP_DURATION): 合并/生成方块弹出效果
#
# 【位置插值】
# 使用 lerp 函数在 prevRow/prevCol 和 row/col 之间进行线性插值
# 配合 ease-out 缓动函数实现平滑动画效果
#=====================================================================
func _drawBoard() -> void:
	# 绘制棋盘背景
	draw_rect(Rect2(boardOrigin, Vector2(boardSize, boardSize)),
		Color(0.46, 0.42, 0.39), true)

	# 绘制空格子
	for y: int in SIZE:
		for x: int in SIZE:
			var cellPos := boardOrigin + Vector2(
				BOARD_PAD + x * (TILE_SIZE + TILE_GAP),
				BOARD_PAD + y * (TILE_SIZE + TILE_GAP)
			)
			draw_rect(Rect2(cellPos, Vector2(TILE_SIZE, TILE_SIZE)),
				Color(0.35, 0.32, 0.30), true)

	# 计算动画进度
	var slideT := clampf(animTime / ANIM_DURATION, 0.0, 1.0) if animating else 1.0
	var inSlide := animating and animTime < ANIM_DURATION
	var inPop := animating and animTime >= ANIM_DURATION
	var popT := clampf((animTime - ANIM_DURATION) / POP_DURATION, 0.0, 1.0) if inPop else 1.0

	# ease-out 缓动：滑动末段减速，更加自然
	var slideEased := 1.0 - (1.0 - slideT) * (1.0 - slideT)

	# 绘制方块
	for t: Tile in tiles:
		# 滑动阶段: 隐藏新生成和合并方块（它们在弹出阶段才显示）
		if inSlide and (t.justSpawned or t.justMerged):
			continue
		# 弹出阶段: 隐藏被合并消费的方块（只显示合并结果）
		if inPop and t.toRemove:
			continue

		# 位置插值：从旧位置 lerp 到新位置
		var displayCol := lerpf(t.prevCol, t.col, slideEased)
		var displayRow := lerpf(t.prevRow, t.row, slideEased)

		# 缩放计算：弹出动画
		var tileScale := 1.0
		if inPop:
			if t.justMerged:
				tileScale = _mergeScale(popT)
			elif t.justSpawned:
				tileScale = _spawnScale(popT)

		_drawTile(displayCol, displayRow, t.value, tileScale)


#=====================================================================
# _drawTile: 绘制单个方块
#
# 【参数】
# - colF/rowF: 方块位置（支持浮点数，用于动画插值）
# - value: 方块数值
# - scaleFactor: 缩放因子（用于弹出动画）
#=====================================================================
func _drawTile(colF: float, rowF: float, value: int, scaleFactor: float) -> void:
	var cellPos := boardOrigin + Vector2(
		BOARD_PAD + colF * (TILE_SIZE + TILE_GAP),
		BOARD_PAD + rowF * (TILE_SIZE + TILE_GAP)
	)

	var tileSize := TILE_SIZE * scaleFactor
	var offset := (TILE_SIZE - tileSize) / 2.0

	var tileRect := Rect2(cellPos + Vector2(offset, offset), Vector2(tileSize, tileSize))
	draw_rect(tileRect, _tileColor(value), true)

	_drawTileText(tileRect.position, tileSize, value)


#=====================================================================
# _drawTileText: 绘制方块上的数字
#
# 【功能】
# 根据数值动态调整字体大小和颜色，确保文字清晰可读
#=====================================================================
func _drawTileText(cellPos: Vector2, tileSize: float, val: int) -> void:
	var text := str(val)
	var font := get_theme_default_font()
	var fs := _fontSize(val)
	var tc := _fontTextColor(val)

	var ts: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var ascent: float = font.get_ascent(fs)
	var topLeft := Vector2(
		cellPos.x + (tileSize - ts.x) / 2.0,
		cellPos.y + (tileSize - ts.y) / 2.0
	)

	draw_string(font, topLeft + Vector2(0, ascent), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, tc)


#=====================================================================
# 动画效果函数
#=====================================================================

#=====================================================================
# _mergeScale: 合并弹跳效果
#
# 【效果】
# 使用正弦函数实现弹跳效果：1.0 → 1.2 → 1.0
# 当 t 从 0 变到 1 时，sin(t * PI) 从 0 → 1 → 0
# 配合缩放因子 0.2，实现放大后恢复的效果
#=====================================================================
func _mergeScale(t: float) -> float:
	return 1.0 + 0.2 * sin(t * PI)


#=====================================================================
# _spawnScale: 生成放大效果
#
# 【效果】
# 使用 ease-out 曲线：0 → 1.0
# 公式: 1 - (1 - t)²
# 特点：开始快，结束慢，产生平滑放大的视觉效果
#=====================================================================
func _spawnScale(t: float) -> float:
	return 1.0 - (1.0 - t) * (1.0 - t)


#=====================================================================
# 样式配置函数
#=====================================================================

#=====================================================================
# _tileColor: 获取数值对应的方块颜色
#
# 【配色方案 - 经典 2048 风格】
# - 2, 4: 米色系（浅色背景）
# - 8-64: 橙黄色系（暖色调）
# - 128+: 金色系（高价值）
# - 其他: 深灰色（超大数值）
#=====================================================================
func _tileColor(val: int) -> Color:
	match val:
		2: return Color("#eee4da")
		4: return Color("#ede0c8")
		8: return Color("#f2b179")
		16: return Color("#f59563")
		32: return Color("#f67c5f")
		64: return Color("#f65e3b")
		128: return Color("#edcf72")
		256: return Color("#edcc61")
		512: return Color("#edc850")
		1024: return Color("#edc53f")
		2048: return Color("#edc22e")
		_: return Color("#3c3a32")


#=====================================================================
# _fontTextColor: 获取文字颜色
#
# 【规则】
# - 小数值(2, 4): 浅色背景配深色文字
# - 大数值: 深色背景配浅色文字
#=====================================================================
func _fontTextColor(val: int) -> Color:
	if val <= 4:
		return Color("#776e65")
	return Color("#f9f6f2")


#=====================================================================
# _fontSize: 根据数值调整字体大小
#
# 【规则】
# 数值越大，字体越小，防止文字溢出方块
#=====================================================================
func _fontSize(val: int) -> int:
	if val < 100:
		return 50
	if val < 1000:
		return 42
	if val < 10000:
		return 34
	return 28

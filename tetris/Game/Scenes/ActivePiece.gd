## 活动方块（ActivePiece）
## 继承自 Node2D，负责管理当前玩家控制的俄罗斯方块
## 处理方块的移动、旋转、掉落、锁定等核心游戏逻辑
class_name ActivePiece
extends Node2D

## 锁定延迟：当方块落地后，延迟一段时间再锁定，让玩家有时间移动或旋转
const LOCK_DELAY: float = 0.5

## 移动节流：方块水平移动的最小间隔时间，防止移动过快
const MOVE_THROTTLE: float = 0.1

## 进入延迟：新方块生成后，延迟一段时间才能开始下落和移动，但可以旋转
const ENTRY_DELAY: float = 0.1

## 重力下落间隔：方块自动下落的时间间隔（秒）
const GRAVITY: float = 1.0

## I型方块初始Y坐标（因为I型方块较长，需要更高）
const I_INITIAL_Y: int = 23

## 普通方块初始Y坐标
const NORMAL_INITIAL_Y: int = 22

## 方块初始X坐标（居中）
const INITIAL_X: int = 3


## 信号：当方块坐标发生变化时发出
signal coordinatesChanged

## 信号：当游戏结束时发出
## @param type 游戏结束类型（溢出或重叠）
signal gameOvered(type: TetrominoTools.GameOverType)


## 调试模式：启用后输出详细日志
@export var debugMode: bool = false

## 引用：游戏场地
@export var _playfield: PlayField

## 引用：下一个方块队列
@export var nextQueue: NextQueue

## 引用：暂存区
@export var holdPiece: HoldPiece


## 下落计时器：控制方块自动下落
@onready var fallTimer: Timer = $FallTimer

## 移动计时器：控制水平移动节流
@onready var moveTimer: Timer = $MoveTimer

## 锁定延迟计时器：控制落地后的锁定延迟
@onready var lockDelayTimer: Timer = $LockDelayTimer


## 当前控制的方块
var tetromino: Tetromino

## 方块在场地中的坐标（相对于场地左上角）
## set 会触发坐标更新和碰撞检测
var coordinates: Vector2i:
	set = setCoordinates

## 是否正在落地（方块下方被阻挡）
var isLanding: bool = false:
	set = setIsLanding

## 是否可以移动（用于移动节流）
var canMove: bool = false:
	set(value):
		canMove = value
		if value:
			moveTimer.stop()
		else:
			moveTimer.start()

## 是否可以使用暂存功能
var canHold: bool = true:
	set(value):
		canHold = value
		holdPiece.setGhost(!canHold)


## 场景就绪时初始化
func _ready() -> void:
	if debugMode:
		Debug.printDebug("ActivePiece: _ready() 开始初始化")

	initTimer()
	nextTetromino()

	if debugMode:
		Debug.printDebug("ActivePiece: _ready() 初始化完成")


## 处理未处理的输入事件
## @param event 输入事件
func _unhandled_input(event: InputEvent) -> void:
	# 水平移动
	var moveAxis: float = Input.get_axis("moveLeft", "moveRight")
	if moveAxis != 0:
		var orientation: Vector2i = Vector2i(sign(moveAxis), 0)
		move(orientation)

	# 向左旋转
	if event.is_action_pressed("turnLeft"):
		rotatePiece(-1)

	# 向右旋转
	if event.is_action_pressed("turnRight"):
		rotatePiece(1)

	# 软下落（按住时加速下落）
	if event.is_action_pressed("moveForward"):
		softDrop(true)

	if event.is_action_released("moveForward"):
		softDrop(false)

	# 硬下落（直接落到底部）
	if event.is_action_pressed("jump"):
		hardDrop()

	# 暂存方块
	if event.is_action_pressed("hold"):
		hold()


## 移动方块
## @param orientation 移动方向（Vector2i）
func move(orientation: Vector2i) -> void:
	if not canMove:
		return

	if debugMode:
		Debug.printDebug("ActivePiece: 尝试移动，方向=%s，坐标=%s" % [orientation, coordinates])

	# 检查移动后是否重叠
	if not _playfield.isOverlap(tetromino, coordinates + orientation):
		coordinates += orientation
		canMove = false
		queue_redraw()

		if debugMode:
			Debug.printDebug("ActivePiece: 移动成功，新坐标=%s" % coordinates)
	else:
		if debugMode:
			Debug.printDebug("ActivePiece: 移动失败，与场地重叠")


## 软下落（加速下落）
## @param isEnabled 是否启用软下落
func softDrop(isEnabled: bool) -> void:
	if isEnabled:
		fallTimer.timeout.emit()
		fallTimer.start(GRAVITY / 5)
		if debugMode:
			Debug.printDebug("ActivePiece: 软下落启用")
	else:
		fallTimer.start(GRAVITY)
		if debugMode:
			Debug.printDebug("ActivePiece: 软下落禁用")


## 硬下落（直接落到底部）
func hardDrop() -> void:
	var oldCoordinates: Vector2i = coordinates
	coordinates = _playfield.getLockPosition(tetromino, coordinates)

	if debugMode:
		Debug.printDebug("ActivePiece: 硬下落，从 %s 到 %s" % [oldCoordinates, coordinates])


## 自动下落（由计时器触发）
func fall() -> void:
	if not _playfield.isOverlap(tetromino, coordinates + Coordinates.down):
		coordinates += Coordinates.down
		queue_redraw()
	else:
		if debugMode:
			Debug.printDebug("ActivePiece: 方块触底，无法继续下落")


## 锁定方块到场地
func lock() -> void:
	if debugMode:
		Debug.printDebug("ActivePiece: 锁定方块，坐标=%s" % coordinates)

	# 检查是否溢出（踢墙有时会超出容器范围）
	if coordinates.y >= PlayField.V_CAPACITY:
		if debugMode:
			Debug.printDebug("ActivePiece: 游戏结束 - 方块溢出")
		gameOvered.emit(Global.GameOverType.OVERFLOW)
		return

	fallTimer.stop()
	isLanding = false
	_playfield.addBlocks(tetromino, coordinates)
	nextTetromino()


## 生成下一个方块
func nextTetromino() -> void:
	if debugMode:
		Debug.printDebug("ActivePiece: 生成新方块")

	tetromino = nextQueue.provide()

	# 根据方块类型设置初始坐标
	if tetromino is I:
		coordinates = Vector2i(INITIAL_X, I_INITIAL_Y)
	else:
		coordinates = Vector2i(INITIAL_X, NORMAL_INITIAL_Y)

	if debugMode:
		Debug.printDebug("ActivePiece: 新方块类型=%s，初始坐标=%s" % [tetromino.get_class(), coordinates])

	# 检查生成位置是否重叠（游戏结束检测）
	if _playfield.isOverlap(tetromino, coordinates):
		if debugMode:
			Debug.printDebug("ActivePiece: 游戏结束 - 方块重叠")
		gameOvered.emit(Global.GameOverType.OVERLAPPED)
		return

	# 延迟后开始下落
	await get_tree().create_timer(ENTRY_DELAY).timeout
	fallTimer.start()
	canMove = true
	canHold = true


## 暂存当前方块
func hold() -> void:
	if not canHold:
		if debugMode:
			Debug.printDebug("ActivePiece: 暂存功能不可用")
		return

	if debugMode:
		Debug.printDebug("ActivePiece: 暂存方块，当前方块类型=%s" % tetromino.get_class())

	canHold = false

	# 与暂存区交换方块
	tetromino = holdPiece.hold(tetromino)

	if tetromino == null:
		# 暂存区为空，生成新方块
		nextTetromino()
	else:
		# 交换成功，重置新方块位置
		if tetromino is I:
			coordinates = Vector2i(INITIAL_X, I_INITIAL_Y)
		else:
			coordinates = Vector2i(INITIAL_X, NORMAL_INITIAL_Y)

		if debugMode:
			Debug.printDebug("ActivePiece: 交换后方块类型=%s，新坐标=%s" % [tetromino.get_class(), coordinates])


## 绘制当前方块
func _draw() -> void:
	TetrominoTools.drawTetromino(self, tetromino, coordinates)


## 旋转方块
## 使用踢墙系统（Wall Kick）处理旋转后可能发生的重叠
## @param direction 旋转方向：-1向左旋转，1向右旋转
## @return 旋转是否成功
func rotatePiece(direction: int) -> bool:
	if debugMode:
		Debug.printDebug("ActivePiece: 尝试旋转，方向=%s，当前朝向=%s" % [direction, tetromino.orientation])

	# 获取踢墙测试点
	var testPoints: Array[Vector2i] = getTestPoints(direction)

	# 保存原始坐标，用于旋转失败时恢复
	var originalCoordinates: Vector2i = coordinates * 1

	# 更新方块朝向
	tetromino.orientation = (tetromino.orientation + direction + 4) % 4

	# 尝试每个测试点
	for point: Vector2i in testPoints:
		if not _playfield.isOverlap(tetromino, coordinates + point):
			coordinates += point
			if debugMode:
				Debug.printDebug("ActivePiece: 旋转成功，新坐标=%s" % coordinates)
			return true

	# 所有测试点都失败，恢复原状
	coordinates = originalCoordinates

	if debugMode:
		Debug.printDebug("ActivePiece: 旋转失败，所有踢墙测试点都重叠")

	return false


## 获取旋转系统的踢墙测试点
## @param direction 旋转方向
## @return 踢墙测试点数组
func getTestPoints(direction: int) -> Array[Vector2i]:
	var formatString: String = "%s_to_%s"
	var fromState: String = RotationSystem.getStateString(tetromino.orientation)
	var toState: String = RotationSystem.getStateString((tetromino.orientation + direction + 4) % 4)
	var key: String = formatString % [fromState, toState]
	return RotationSystem.getTestPoints(tetromino, key)


## 初始化所有计时器
func initTimer() -> void:
	# 下落计时器
	fallTimer.wait_time = GRAVITY
	fallTimer.autostart = true
	fallTimer.timeout.connect(fall)

	# 移动计时器
	moveTimer.wait_time = MOVE_THROTTLE
	moveTimer.timeout.connect(onMoveTimerTimeout)

	# 锁定延迟计时器
	lockDelayTimer.wait_time = LOCK_DELAY
	lockDelayTimer.one_shot = true
	lockDelayTimer.timeout.connect(lock)


## 设置落地状态
## 当方块下方被阻挡时触发锁定延迟计时器
## @param value 是否落地
func setIsLanding(value: bool) -> void:
	if isLanding != value:
		if value:
			lockDelayTimer.start()
			if debugMode:
				Debug.printDebug("ActivePiece: 开始锁定延迟计时")
		else:
			lockDelayTimer.stop()
			if debugMode:
				Debug.printDebug("ActivePiece: 取消锁定延迟计时")

		isLanding = value


## 设置坐标
## 每次坐标变化都会触发碰撞检测，更新落地状态
## @param value 新的坐标
func setCoordinates(value: Vector2i) -> void:
	coordinates = value
	coordinatesChanged.emit()
	queue_redraw()

	# 检测是否落地
	isLanding = _playfield.isOverlap(tetromino, coordinates + Coordinates.down)


## 移动计时器超时回调
func onMoveTimerTimeout() -> void:
	canMove = true

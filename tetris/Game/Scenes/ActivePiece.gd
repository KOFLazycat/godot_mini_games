class_name ActivePiece
extends Node2D

## 锁定延迟 单位：秒
const LOCK_DELAY: float = 0.5
## 移动节流 如：0.1s/次，表示每0.1秒内只能移动一次
const MOVE_THROTTLE: float = 0.1
## 进入延迟 当新砖块生成后延迟一段时间才能活动（移动和下落，但能旋转），
## 独立于下落，仅在新砖块中有效。 单位：秒
const ENTRY_DELAY: float = 0.1
## 多少秒下落一次
const GRAVITY: float = 1.0

## I型方块初始Y坐标
const I_INITIAL_Y: int = 23
## 普通方块初始Y坐标
const NORMAL_INITIAL_Y: int = 22
## 初始X坐标
const INITIAL_X: int = 3


signal coordinatesChanged
signal gameOvered(type: TetrominoTools.GameOverType)

@export var _playfield: PlayField
@export var nextQueue: NextQueue
@export var holdPiece: HoldPiece

@onready var fallTimer: Timer = $FallTimer
@onready var moveTimer: Timer = $MoveTimer
@onready var lockDelayTimer: Timer = $LockDelayTimer

var tetromino: Tetromino
var coordinates: Vector2i:
	set = setCoordinates

var isLanding: bool = false:
	set = setIsLanding

var canMove: bool = false:
	set(value):
		canMove = value
		if value:
			moveTimer.stop()
		else:
			moveTimer.start()

var canHold: bool = true:
	set(value):
		canHold = value
		holdPiece.setGhost(!canHold)


func _ready() -> void:
	initTimer()
	nextTetromino()


func _unhandled_input(event: InputEvent) -> void:
	var moveAxis: float = Input.get_axis("moveLeft", "moveRight")
	if moveAxis != 0:
		var orientation: Vector2i = Vector2i(sign(moveAxis), 0)
		move(orientation)

	if event.is_action_pressed("turnLeft"):
		rotatePiece(-1)

	if event.is_action_pressed("turnRight"):
		rotatePiece(1)

	if event.is_action_pressed("moveForward"):
		softDrop(true)

	if event.is_action_released("moveForward"):
		softDrop(false)

	if event.is_action_pressed("jump"):
		hardDrop()

	if event.is_action_pressed("hold"):
		hold()


func move(orientation: Vector2i) -> void:
	if not canMove:
		return

	if not _playfield.isOverlap(tetromino, coordinates + orientation):
		coordinates += orientation
		canMove = false
		queue_redraw()


func softDrop(isEnabled: bool) -> void:
	if isEnabled:
		fallTimer.timeout.emit()
		fallTimer.start(GRAVITY / 5)
	else:
		fallTimer.start(GRAVITY)


func hardDrop() -> void:
	coordinates = _playfield.getLockPosition(tetromino, coordinates)


func fall() -> void:
	if not _playfield.isOverlap(tetromino, coordinates + Coordinates.down):
		coordinates += Coordinates.down
		queue_redraw()


func lock() -> void:
	# 踢墙有时会超出容器范围
	if coordinates.y >= PlayField.V_CAPACITY:
		gameOvered.emit(Global.GameOverType.OVERFLOW)

	fallTimer.stop()
	isLanding = false
	_playfield.addBlocks(tetromino, coordinates)
	nextTetromino()


func nextTetromino() -> void:
	tetromino = nextQueue.provide()
	if tetromino is I:
		coordinates = Vector2i(INITIAL_X, I_INITIAL_Y)
	else:
		coordinates = Vector2i(INITIAL_X, NORMAL_INITIAL_Y)

	if _playfield.isOverlap(tetromino, coordinates):
		gameOvered.emit(Global.GameOverType.OVERLAPPED)

	await get_tree().create_timer(ENTRY_DELAY).timeout
	fallTimer.start()
	canMove = true
	canHold = true


func hold() -> void:
	if not canHold:
		return

	canHold = false

	tetromino = holdPiece.hold(tetromino)
	if tetromino == null:
		nextTetromino()
	else:
		if tetromino is I:
			coordinates = Vector2i(INITIAL_X, I_INITIAL_Y)
		else:
			coordinates = Vector2i(INITIAL_X, NORMAL_INITIAL_Y)


func _draw() -> void:
	TetrominoTools.drawTetromino(self, tetromino, coordinates)


## 旋转方块
## @param direction 旋转方向：-1向左，1向右
func rotatePiece(direction: int) -> bool:
	var testPoints: Array[Vector2i] = getTestPoints(direction)
	var originalCoordinates: Vector2i = coordinates * 1

	tetromino.orientation = (tetromino.orientation + direction + 4) % 4

	for point: Vector2i in testPoints:
		if not _playfield.isOverlap(tetromino, coordinates + point):
			coordinates += point
			return true

	coordinates = originalCoordinates

	return false


## 获取所有踢墙测试点
## @param direction 旋转方向
## @return 踢墙测试点数组
func getTestPoints(direction: int) -> Array[Vector2i]:
	var formatString: String = "%s_to_%s"
	var fromState: String = RotationSystem.getStateString(tetromino.orientation)
	var toState: String = RotationSystem.getStateString((tetromino.orientation + direction + 4) % 4)
	var key: String = formatString % [fromState, toState]
	return RotationSystem.getTestPoints(tetromino, key)


func initTimer() -> void:
	fallTimer.wait_time = GRAVITY
	fallTimer.autostart = true
	fallTimer.timeout.connect(fall)

	moveTimer.wait_time = MOVE_THROTTLE
	moveTimer.timeout.connect(onMoveTimerTimeout)

	lockDelayTimer.wait_time = LOCK_DELAY
	lockDelayTimer.one_shot = true
	lockDelayTimer.timeout.connect(lock)


func setIsLanding(value: bool) -> void:
	if isLanding != value:
		if value:
			lockDelayTimer.start()
		else:
			lockDelayTimer.stop()

		isLanding = value


func setCoordinates(value: Vector2i) -> void:
	coordinates = value
	coordinatesChanged.emit()
	queue_redraw()

	isLanding = _playfield.isOverlap(tetromino, coordinates + Coordinates.down)


func onMoveTimerTimeout() -> void:
	canMove = true

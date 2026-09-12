class_name BlockManager
extends Node2D

#region Parameters
@export var debugMode: bool = false
@export var blockScene: PackedScene = preload("res://Game/Entities/BlockEntity.tscn")
@export var preBlockNum: int = 6
@export var blockColors: Array[Color] = []
#endregion

#region State
# 方块的高度（像素）
# 用于碰撞检测和边界计算
var blockHeight: float = 128.0
# 方块的宽度（像素）
var blockWidth: float = 102.0
# 方块实例列表
var blockList: Array[Entity] = []
# 剩余颜色列表，从 remainingColors 中 pop 到 usedColors
var remainingColors: Array[Color] = []
# 已使用颜色列表，用于判断是否应该启用碰撞
var usedColors: Array[Color] = []
# 记录连续从 remainingColors 中选取的颜色数量
var consecutiveFromRemainingCount: int = 0
# 记录上一个 block 的颜色是否在 usedColors 中
var lastColorInUsedColors: bool = true
# 用于定时 pop 颜色的 Timer
var popColorTimer: Timer = null
# 游戏是否已开始（通过检查 Timer 是否存在来判断）
var isGameStarted: bool = false:
	get:
		return popColorTimer != null
#endregion


#region Signals
#endregion


#region Dependencies

#endregion


func _ready() -> void:
	_initializeBlocks()
	_connectionSignals()


func _exit_tree() -> void:
	_disconnectionSignals()


func _connectionSignals() -> void:
	Tools.connectSignal(GlobalEvent.gameStarted, onGlobalEvent_gameStarted)


func _disconnectionSignals() -> void:
	Tools.disconnectSignal(GlobalEvent.gameStarted, onGlobalEvent_gameStarted)
	# 清理 Timer
	if popColorTimer != null:
		Tools.disconnectSignal(popColorTimer.timeout, onPopColorTimer_timeout)
		popColorTimer.queue_free()
		popColorTimer = null


## 初始化方块，用于游戏开始前的主界面状态
func _initializeBlocks() -> void:
	# 初始化 remainingColors 为 blockColors 的副本
	remainingColors = blockColors.duplicate()
	# 洗牌
	remainingColors.shuffle()

	# 从 remainingColors pop 一个颜色到 usedColors
	if remainingColors.size() > 0:
		var firstColor: Color = remainingColors.pop_front()
		usedColors.append(firstColor)

	# 生成 preBlockNum 个 block
	for i: int in range(preBlockNum):
		var blockInstance: Entity = blockScene.instantiate()
		if blockInstance == null:
			Debug.printError("Block 场景实例化失败", self)
			continue

		blockInstance.position = Vector2(i * blockWidth, 0)
		add_child(blockInstance)

		var blockStateComponent: BlockStateComponent = blockInstance.getComponent(BlockStateComponent)
		if blockStateComponent != null:
			# 游戏开始前，只使用 usedColors[0] 作为颜色（此时只有一个颜色）
			if usedColors.size() > 0:
				blockStateComponent.blockColor = usedColors[0]
				# 游戏开始前，启用碰撞
				blockStateComponent.shouldDisableCollision = false
			Tools.connectSignal(blockStateComponent.visibleOnScreenNotifier.screen_exited, onVisibleOnScreenNotifier_screen_exited.bind(blockInstance))
		blockList.append(blockInstance)


## 游戏开始时的处理
func onGlobalEvent_gameStarted() -> void:
	# 重置连续计数
	consecutiveFromRemainingCount = 0
	lastColorInUsedColors = true
	# 创建定时器，每16秒从 remainingColors pop 一个颜色到 usedColors
	popColorTimer = Timer.new()
	popColorTimer.wait_time = 16.0
	popColorTimer.autostart = true
	Tools.connectSignal(popColorTimer.timeout, onPopColorTimer_timeout)
	add_child(popColorTimer)


## 定时 pop 颜色的回调
func onPopColorTimer_timeout() -> void:
	if remainingColors.size() > 0:
		var color: Color = remainingColors.pop_front()
		usedColors.append(color)
		# 更新已生成 block 的碰撞状态
		_updateBlocksCollisionState()
		if debugMode:
			Debug.printLog("Pop color to usedColors, remaining: %d, used: %d" % [remainingColors.size(), usedColors.size()], self)
	else:
		# remainingColors 全部 pop 出去，游戏胜利
		if debugMode:
			Debug.printLog("All colors used, game won!", self)
		GlobalEvent.gameEnded.emit(true)
		# 停止定时器
		if popColorTimer != null:
			popColorTimer.stop()


## 更新所有已生成 block 的碰撞状态
## 当新颜色添加到 usedColors 时，遍历 blockList，如果颜色在 usedColors 中则启用碰撞
func _updateBlocksCollisionState() -> void:
	for block: Entity in blockList:
		var blockStateComponent: BlockStateComponent = block.getComponent(BlockStateComponent)
		if blockStateComponent != null:
			var colorInUsed: bool = blockStateComponent.blockColor in usedColors
			blockStateComponent.shouldDisableCollision = not colorInUsed
			if debugMode:
				Debug.printLog("Block color: %s, inUsedColors: %s, shouldDisableCollision: %s" % [blockStateComponent.blockColor, colorInUsed, not colorInUsed], self)


func onVisibleOnScreenNotifier_screen_exited(blockInstance: Node2D) -> void:
	if blockList.is_empty():
		return

	var lastBlock: Entity = blockList.back()
	var lastX: float = 0.0
	if lastBlock != null:
		lastX = lastBlock.position.x

	blockInstance.position.x = lastX + blockWidth

	blockList.erase(blockInstance)
	blockList.append(blockInstance)

	var blockStateComponent: BlockStateComponent = blockInstance.getComponent(BlockStateComponent)
	if blockStateComponent != null and blockColors.size() > 0:
		var newColor: Color
		var colorInUsedColors: bool

		if isGameStarted:
			# 游戏开始后，60% 概率从 usedColors 选取，40% 概率从 remainingColors 选取
			# 最多连续两次从 remainingColors 选取，第三次必定从 usedColors 选取
			if consecutiveFromRemainingCount >= 2:
				# 已经连续2次从 remainingColors 选取，第三次必须从 usedColors 中选取
				newColor = usedColors.pick_random()
				colorInUsedColors = true
				consecutiveFromRemainingCount = 0
			else:
				# 60% 概率从 usedColors，40% 概率从 remainingColors
				var chooseFromUsed: bool = randf() < 0.6
				if chooseFromUsed:
					newColor = usedColors.pick_random()
					colorInUsedColors = true
					consecutiveFromRemainingCount = 0
				else:
					newColor = remainingColors.pick_random()
					colorInUsedColors = false
					consecutiveFromRemainingCount += 1

			lastColorInUsedColors = colorInUsedColors
			blockStateComponent.blockColor = newColor
			blockStateComponent.shouldDisableCollision = not colorInUsedColors

			if debugMode:
				Debug.printLog("Block color: %s, inUsedColors: %s, shouldDisableCollision: %s" % [newColor, colorInUsedColors, not colorInUsedColors], self)
		else:
			# 游戏开始前，使用 usedColors[0] 作为颜色
			if usedColors.size() > 0:
				newColor = usedColors[0]
				blockStateComponent.blockColor = newColor
				blockStateComponent.shouldDisableCollision = false

class_name BlockManager
extends Node2D

#region Parameters
@export var debugMode: bool = false
@export var blockScene: PackedScene = preload("res://Game/Entities/Block.tscn")
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
	#Tools.connectSignal(stop.state_entered, onStop_state_entered)
	pass


func _disconnectionSignals() -> void:
	pass


func _initializeBlocks() -> void:
	for i: int in range(preBlockNum):
		var blockInstance: Entity = blockScene.instantiate()
		if blockInstance == null:
			Debug.printError("Block 场景实例化失败", self)
			continue

		blockInstance.position = Vector2(i * blockWidth, 0.0)
		add_child(blockInstance)

		var blockStateComponent: BlockStateComponent = blockInstance.getComponent(BlockStateComponent)
		if blockStateComponent != null:
			if blockColors.size() > 0:
				var randomColor: Color = blockColors.pick_random()
				blockStateComponent.blockColor = randomColor
			Tools.connectSignal(blockStateComponent.visibleOnScreenNotifier.screen_exited, onVisibleOnScreenNotifier_screen_exited.bind(blockInstance))

		blockList.append(blockInstance)


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
		var randomColor: Color = blockColors.pick_random()
		blockStateComponent.blockColor = randomColor

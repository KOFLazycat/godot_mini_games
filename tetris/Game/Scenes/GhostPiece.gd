## 幽灵方块（GhostPiece）
## 继承自 Node2D，显示活动方块落地后的预期位置
## 帮助玩家预测方块的下落位置，以便提前规划策略
class_name GhostPiece
extends Node2D

## 幽灵方块透明度
const GHOST_ALPHA: float = 0.6


## 调试模式：启用后输出详细日志
@export var debugMode: bool = false

## 引用：游戏场地（用于计算锁定位置）
@export var _playfield: PlayField

## 引用：活动方块（需要显示幽灵位置的方块）
@export var _entity: ActivePiece


## 场景就绪时初始化
func _ready() -> void:
	if debugMode:
		Debug.printDebug("GhostPiece: _ready() 开始初始化")

	# 监听活动方块的坐标变化，实时更新幽灵位置
	_entity.coordinatesChanged.connect(func() -> void:
		if debugMode:
			Debug.printDebug("GhostPiece: 坐标变化，重新绘制，实体坐标=%s" % _entity.coordinates)
		queue_redraw()
	)

	if debugMode:
		Debug.printDebug("GhostPiece: _ready() 初始化完成")


## 绘制幽灵方块
## 每次绘制时计算方块落地后的位置，并绘制半透明版本
func _draw() -> void:
	# 如果没有方块，不绘制
	if _entity.tetromino == null:
		return

	# 计算方块落地后的锁定位置
	var lockPosition: Vector2i = _playfield.getLockPosition(_entity.tetromino, _entity.coordinates)

	if debugMode:
		Debug.printDebug("GhostPiece: 绘制幽灵方块，实体坐标=%s，锁定位置=%s" % [_entity.coordinates, lockPosition])

	# 如果锁定位置与当前位置相同（已经落地），不绘制
	if lockPosition == _entity.coordinates:
		if debugMode:
			Debug.printDebug("GhostPiece: 方块已落地，不绘制幽灵")
		return

	# 获取活动方块的颜色并设置为半透明
	var pieceColor: Color = _entity.tetromino.COLOR
	pieceColor.a = GHOST_ALPHA

	# 绘制半透明的幽灵方块
	TetrominoTools.drawTetromino(self, _entity.tetromino, lockPosition, pieceColor)

	if debugMode:
		Debug.printDebug("GhostPiece: 绘制完成")

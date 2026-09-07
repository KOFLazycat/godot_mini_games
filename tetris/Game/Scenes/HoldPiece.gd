## 暂存区（HoldPiece）
## 继承自 Node2D，暂存玩家当前控制的方块
## 玩家可以按C键将当前方块与暂存区中的方块交换
## 暂存区只能在使用后再次使用（一次交换后需落地才能再次使用）
class_name HoldPiece
extends Node2D

## 暂存区显示区域的宽度（格子数）
const WIDTH: int = 6

## 暂存区显示区域的高度（格子数）
const HEIGHT: int = 4

## 半透明显示时的透明度（当暂存区为空或已使用过暂存时）
const GHOST_ALPHA: float = 0.3


## 调试模式：启用后输出详细日志
@export var debugMode: bool = false

## 是否显示为半透明（当暂存区为空或已使用过暂存时）
var isGhost: bool = false

## 当前暂存的方块
var heldPiece: Tetromino


## 暂存方块
## 将当前方块存入暂存区，返回暂存区中原有的方块
## @param tetromino 当前控制的方块
## @return 暂存区中原有的方块（如果没有则返回null）
func hold(tetromino: Tetromino) -> Tetromino:
	if debugMode:
		Debug.printDebug("HoldPiece: 暂存方块，当前方块类型=%s" % tetromino.get_class())

	var temp: Tetromino = heldPiece
	heldPiece = tetromino

	# 重置方块朝向为初始状态（面向右）
	heldPiece.orientation = 0

	# 设置为半透明状态（表示已使用，需要落地后才能再次使用）
	isGhost = true
	queue_redraw()

	if debugMode:
		Debug.printDebug("HoldPiece: 暂存完成，原暂存方块=%s" % (temp.get_class() if temp else "null"))

	return temp


## 设置半透明显示状态
## @param enable 是否启用半透明
func setGhost(enable: bool) -> void:
	if debugMode:
		Debug.printDebug("HoldPiece: 设置半透明状态=%s" % enable)

	isGhost = enable
	queue_redraw()


## 绘制暂存区
func _draw() -> void:
	# 绘制暂存区边框
	draw_rect(Rect2(0, 0, \
		WIDTH * PlayField.CELL_WIDTH, HEIGHT * PlayField.CELL_WIDTH), Color.WHITE, false, 6)

	# 如果暂存区有方块，绘制方块
	if heldPiece != null:
		# 获取方块颜色
		var pieceColor: Color = heldPiece.COLOR

		# 如果处于半透明状态，设置透明度
		if isGhost:
			pieceColor.a = GHOST_ALPHA

		# 绘制方块在暂存区中央位置
		TetrominoTools.drawTetromino(self, heldPiece, Vector2i(1, -2), pieceColor)

		if debugMode:
			Debug.printDebug("HoldPiece: 绘制方块，类型=%s，半透明=%s" % [heldPiece.get_class(), isGhost])

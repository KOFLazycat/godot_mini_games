## 暂存区（HoldPiece）
## 暂存玩家当前控制的方块
## 玩家可以按C键将当前方块与暂存区中的方块交换
class_name HoldPiece 
extends Node2D

## 暂存区显示区域的宽度（格子数）
const WiDTH = 6
## 暂存区显示区域的高度（格子数）
const HIGHT = 4

## 是否显示为半透明（当暂存区为空或已使用过暂存时）
var is_ghost: bool = false

## 当前暂存的方块
var hold_piece: Tetromino


## 暂存方块
## 将当前方块存入暂存区，返回暂存区中原有的方块
## @param tetromino 当前控制的方块
## @return 暂存区中原有的方块（如果没有则返回null）
func hold(tetromino: Tetromino) -> Tetromino:
	var temp: Tetromino = hold_piece
	hold_piece = tetromino
	# 重置方块朝向为初始状态
	hold_piece.orientation = 0
	is_ghost = true
	queue_redraw()
	return temp


## 设置半透明显示状态
## @param enable 是否启用半透明
func ghost(enable: bool) -> void:
	is_ghost = enable
	queue_redraw()


## 绘制暂存区
func _draw() -> void:
	# 绘制暂存区边框
	draw_rect(Rect2(0, 0, \
		WiDTH * PlayField.CELL_WIDTH, HIGHT * PlayField.CELL_WIDTH), Color.WHITE, false, 6)

	# 如果暂存区有方块，绘制方块
	if hold_piece != null:
		# 获取方块颜色
		var color: Color = hold_piece.COLOR

		# 如果处于半透明状态，设置透明度
		if is_ghost:
			color.a = 0.3

		# 绘制方块在暂存区中央位置
		Global.draw_tetromino(self, hold_piece, Vector2i(1, -2), color)

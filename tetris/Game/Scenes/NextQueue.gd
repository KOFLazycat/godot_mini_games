## 下一个方块队列（NextQueue）
## 显示接下来将要出现的方块
## 玩家可以预先看到下一个方块以便规划策略
class_name NextQueue 
extends Node2D

## 随机生成器
var randomizer: Randomizer = Randomizer.new()

## 队列容量（显示的下一个方块数量）
const CAPACITY = 3

## 队列显示区域的宽度（格子数）
const WIDTH = 6
## 队列显示区域的高度（格子数）
const HIGHT = 10

## 下一个方块队列数组
var next_queue: Array[Tetromino] = []


## 初始化方法
## 预先生成CAPACITY个方块填充队列
func _init() -> void:
	for i in CAPACITY:
		next_queue.push_back(randomizer.provide())


## 绘制下一个方块队列
func _draw() -> void:
	# 绘制队列显示区域边框
	draw_rect(Rect2(0, - HIGHT * PlayField.CELL_WIDTH, \
		WIDTH * PlayField.CELL_WIDTH, HIGHT * PlayField.CELL_WIDTH), Color.WHITE, false, 6)

	# 绘制队列中的每个方块
	for i in next_queue.size():
		# 每个方块之间间隔3行
		TetrominoTools.draw_tetromino(self, next_queue[i], Vector2i(1, HIGHT - 2 - i * 3))


## 提供下一个方块
## 从队列中取出一个方块，并补充一个新的方块到队列末尾
## @return 下一个俄罗斯方块
func provice() -> Tetromino:
	# 取出队列最前面的方块
	var next_piece: Tetromino = next_queue.pop_front()

	# 添加一个新的随机方块到队列末尾
	next_queue.push_back(randomizer.provide())

	# 重绘显示
	queue_redraw()

	return next_piece

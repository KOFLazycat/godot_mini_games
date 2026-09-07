## 俄罗斯方块随机生成器
## 使用7包系统（7-bag system）：每7个方块为一组，包含所有7种方块各一个
## 这种方式保证每种方块在7次生成内必定出现，避免出现长时间没有某种方块的情况
class_name Randomizer
extends RefCounted

## 所有方块类类型的数组（7种标准方块）
var tetromino_class_array: Array[Variant] = [Z, L, O, S, I, J, T]
## 当前包中的方块数组
var tetromino_array: Array[Tetromino] = []
## 临时存储数组，用于补充方块
var temp: Array[Tetromino] = []

## 初始化方法
## 创建时生成两个打乱顺序的方块包
func _init() -> void:
	tetromino_array = _get_shuffle_array()
	temp = _get_shuffle_array()


## 提供一个随机方块
## 采用7包系统：从当前包中取出一个方块，然后用备用包中的一个方块补充
## @return 下一个俄罗斯方块对象
func provide() -> Tetromino:
	# 从当前包中取出最前面的方块
	var tetromino: Tetromino = tetromino_array.pop_front()
	# 从备用包中取出一个方块加入当前包
	tetromino_array.push_back(temp.pop_back())
	# 如果备用包为空，重新生成一包
	if temp.is_empty():
		temp = _get_shuffle_array()

	return tetromino


## 生成打乱顺序的方块数组
## @return 包含7种方块各一个的打乱数组
func _get_shuffle_array() -> Array[Tetromino]:
	var result: Array[Tetromino] = []

	# 创建每种方块类的实例
	for tetromino_class: GDScript in tetromino_class_array:
		result.push_back(tetromino_class.new())

	# 打乱数组顺序
	result.shuffle()
	return result

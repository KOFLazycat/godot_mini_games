class_name Randomizer
extends RefCounted

var tetrominoClassArray: Array[Variant] = [Z, L, O, S, I, J, T]
var tetrominoArray: Array[Tetromino] = []
var temp: Array[Tetromino] = []

func _init() -> void:
	tetrominoArray = getShuffleArray()
	temp = getShuffleArray()

func provide() -> Tetromino:
	var tetromino: Tetromino = tetrominoArray.pop_front()
	tetrominoArray.push_back(temp.pop_back())
	if temp.is_empty():
		temp = getShuffleArray()
	return tetromino

func getShuffleArray() -> Array[Tetromino]:
	var result: Array[Tetromino] = []
	for tetrominoClass: GDScript in tetrominoClassArray:
		result.push_back(tetrominoClass.new())
	result.shuffle()
	return result

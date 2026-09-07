class_name Tetromino
extends RefCounted

var color: Color
var stateArray: Array[Array] = []
var orientation: int = 0

func getBlocks() -> Array[Array]:
	return stateArray[orientation]

func getInitBlocks() -> Array[Array]:
	return stateArray[0]

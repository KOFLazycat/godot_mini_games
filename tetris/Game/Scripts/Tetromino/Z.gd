class_name Z
extends Tetromino

const COLOR: Color = Color.RED

const state0: Array[Array] = [
	[1, 1, 0],
	[0, 1, 1],
	[0, 0, 0]
]

const state90: Array[Array] = [
	[0, 0, 1],
	[0, 1, 1],
	[0, 1, 0]
]

const state180: Array[Array] = [
	[0, 0, 0],
	[1, 1, 0],
	[0, 1, 1]
]

const state270: Array[Array] = [
	[0, 1, 0],
	[1, 1, 0],
	[1, 0, 0]
]

func _init() -> void:
	color = COLOR
	stateArray = [state0, state90, state180, state270]

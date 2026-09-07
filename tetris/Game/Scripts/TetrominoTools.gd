class_name TetrominoTools
extends Object

enum GameOverType {
	OVERLAPPED,
	OVERFLOW
}

static func drawTetromino(canvasItem: CanvasItem, tetromino: Tetromino,
	coordinates: Vector2i = Vector2i.ZERO, color: Color = Color.TRANSPARENT) -> void:

	if color == Color.TRANSPARENT:
		color = tetromino.color

	var blocks: Array = tetromino.getBlocks()

	for row in blocks.size():
		for col: int in blocks[row].size():
			if blocks[row][col]:
				var point: Vector2 = Vector2(col + coordinates.x, -row + 1 + coordinates.y) \
					* Vector2(PlayField.CELL_WIDTH, -PlayField.CELL_WIDTH)
				var size: Vector2 = Vector2(PlayField.CELL_WIDTH, PlayField.CELL_WIDTH)
				var rect: Rect2 = Rect2(point, size).grow(-1)
				canvasItem.draw_rect(rect, color)

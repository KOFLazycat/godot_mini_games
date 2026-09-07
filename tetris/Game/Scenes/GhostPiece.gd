## 幽灵方块（GhostPiece）
## 显示活动方块落地后的预期位置
## 帮助玩家预测方块的下落位置
class_name GhostPiece 
extends Node2D

## 引用：游戏场地
@export var _playfield: PlayField
## 引用：活动方块（需要显示幽灵位置的方块）
@export var _entity: ActivePiece


## 场景就绪时初始化
func _ready() -> void:
	# 监听活动方块的坐标变化，实时更新幽灵位置
	_entity.coordinatesChanged.connect(func () -> void:queue_redraw())


## 绘制幽灵方块
func _draw() -> void:
	# 计算方块落地后的锁定位置
	var coordinate: Vector2i = _playfield.get_lock_position(_entity.tetromino, _entity.coordinates)

	# 如果锁定位置与当前位置相同（已经落地），不绘制
	if coordinate == _entity.coordinates:
		return

	# 获取活动方块的颜色并设置为半透明
	var color: Color = _entity.tetromino.COLOR
	color.a = 0.6

	# 绘制半透明的幽灵方块
	TetrominoTools.draw_tetromino(self, _entity.tetromino, coordinate, color)

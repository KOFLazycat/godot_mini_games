## 游戏竞技场（Arena）
## 俄罗斯方块游戏的主场景，管理游戏状态、分数和游戏结束逻辑
class_name Arena
extends Node2D

## 已消除的行数
var clearedLines: int = 0:
	set(value):
		clearedLines = value
		score.text = str(value)

@onready var playField: PlayField = $PlayField
@onready var score: Label = $CanvasLayer/HBoxContainer/Score

@onready var panel: Panel = $CanvasLayer/Panel
@onready var reasonLabel: Label = $CanvasLayer/Panel/VBoxContainer/Reason
@onready var activePiece: ActivePiece = $PlayField/ActivePiece


func _ready() -> void:
	score.text = "0"
	playField.cleared.connect(onPlayFieldCleared)
	activePiece.gameOvered.connect(onGameOvered)


## 当场地消除行时触发
## @param lines 消除的行数
func onPlayFieldCleared(lines: int) -> void:
	clearedLines += lines


## 当游戏结束时触发
## @param type 游戏结束类型
func onGameOvered(type: TetrominoTools.GameOverType) -> void:
	get_tree().paused = true
	reasonLabel.text = getGameOverReason(type)
	panel.show()


## 获取游戏结束原因文本
## @param type 游戏结束类型
## @return 游戏结束原因文本
func getGameOverReason(type: TetrominoTools.GameOverType) -> String:
	match type:
		TetrominoTools.GameOverType.OVERLAPPED:
			return "方块重叠"
		TetrominoTools.GameOverType.OVERFLOW:
			return "方块溢出"
		_:
			return ""


## 重新开始游戏
func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

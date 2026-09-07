class_name Arena
extends Node2D

var clearedLines: int:
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


func onPlayFieldCleared(lines: int) -> void:
	clearedLines += lines


func onGameOvered(type: TetrominoTools.GameOverType) -> void:
	get_tree().paused = true
	var reasonText: String
	match type:
		TetrominoTools.GameOverType.OVERLAPPED:
			reasonText = "方块重叠"
		TetrominoTools.GameOverType.OVERFLOW:
			reasonText = "方块溢出"

	reasonLabel.text = reasonText
	panel.show()


func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

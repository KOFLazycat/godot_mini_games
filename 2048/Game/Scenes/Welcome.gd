class_name Welcome
extends Control

@onready var titleLabel: Label = %TitleLabel
@onready var spacer1: Control = %Spacer1
@onready var startButton: Button = %StartButton
@onready var spacer2: Control = %Spacer2
@onready var hintLabel: Label = %HintLabel


func _ready() -> void:
	titleLabel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	startButton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	Tools.connectSignal(startButton.pressed, onStartButton_pressed)
	hintLabel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func onStartButton_pressed() -> void:
	get_tree().change_scene_to_file("res://Game/Scenes/GameMain.tscn")

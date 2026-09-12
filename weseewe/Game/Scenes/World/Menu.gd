class_name Menu
extends Control

@onready var startButton: TextureButton = $StartButton


func _ready() -> void:
	startButton.pivot_offset = startButton.size / 2
	_connectionSignals()


func _exit_tree() -> void:
	_disconnectionSignals()


func _connectionSignals() -> void:
	Tools.connectSignal(startButton.mouse_entered, onStartButton_mouse_entered)
	Tools.connectSignal(startButton.mouse_exited, onStartButton_mouse_exited)
	Tools.connectSignal(startButton.button_down, onStartButton_button_down)
	Tools.connectSignal(startButton.button_up, onStartButton_button_up)


func _disconnectionSignals() -> void:
	Tools.disconnectSignal(startButton.mouse_entered, onStartButton_mouse_entered)
	Tools.disconnectSignal(startButton.mouse_exited, onStartButton_mouse_exited)
	Tools.disconnectSignal(startButton.button_down, onStartButton_button_down)
	Tools.disconnectSignal(startButton.button_up, onStartButton_button_up)


func onStartButton_mouse_entered() -> void:
	startButton.scale = Vector2(1.05, 1.05)


func onStartButton_mouse_exited() -> void:
	startButton.scale = Vector2(1.0, 1.0)


func onStartButton_button_down() -> void:
	startButton.scale = Vector2(0.95, 0.95)


func onStartButton_button_up() -> void:
	startButton.scale = Vector2(1.0, 1.0)

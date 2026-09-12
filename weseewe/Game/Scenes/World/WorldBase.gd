class_name WorldBase
extends Node2D

@export var bgMusicResource: SoundResource
@onready var menu: Menu = $UILayer/Menu


func _ready() -> void:
	playMusic(0.5, 0.5)
	_connectionSignals()


func _exit_tree() -> void:
	_disconnectionSignals()


func _connectionSignals() -> void:
	Tools.connectSignal(menu.startButton.pressed, onStartButton_pressed)
	Tools.connectSignal(GlobalEvent.gameEnded, onGlobalEvent_gameEnded)


func _disconnectionSignals() -> void:
	Tools.disconnectSignal(menu.startButton.pressed, onStartButton_pressed)
	Tools.disconnectSignal(GlobalEvent.gameEnded, onGlobalEvent_gameEnded)


func playMusic(pitchMin: float = 1.0, pitchMax: float = 1.0) -> void:
	if bgMusicResource != null :
		bgMusicResource.stop()
		bgMusicResource.pitch_min = pitchMin
		bgMusicResource.pitch_max = pitchMax
		bgMusicResource.play_managed()


func onStartButton_pressed() -> void:
	playMusic()
	GlobalEvent.gameStarted.emit()
	menu.visible = false


func onGlobalEvent_gameEnded(isWin: bool) -> void:
	prints(isWin, "AAAAAAAAAAA")

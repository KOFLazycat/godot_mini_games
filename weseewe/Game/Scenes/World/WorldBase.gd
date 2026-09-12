class_name WorldBase
extends Node2D

@export var bgMusicResource: SoundResource


func _ready() -> void:
	if bgMusicResource != null :
		bgMusicResource.pitch_min = 0.5
		bgMusicResource.pitch_max = 0.5
		bgMusicResource.play_managed()

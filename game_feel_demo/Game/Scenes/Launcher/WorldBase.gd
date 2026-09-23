class_name WorldBase
extends Node2D

@export var lightningSoundResource: SoundResource

@onready var juiceePlayer: JuiceePlayer = $JuiceePlayer


var lightningTimeRemain: float = randf_range(8.0, 16.0)


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if lightningTimeRemain <= 0:
		juiceePlayer.play()
		if lightningSoundResource:
			lightningSoundResource.play_managed()
		lightningTimeRemain = randf_range(8.0, 16.0)
	lightningTimeRemain -= delta

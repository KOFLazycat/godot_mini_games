class_name CloudManager
extends Node2D

@export var cloudCound: int = 2
@export var minPositionY: float = 50.0
@export var maxPositionY: float = 250.0
@export var cloudEntityScene: PackedScene = preload("res://Game/Entities/CloudEntity.tscn")

var screenSize: Vector2


func _ready() -> void:
	screenSize = get_viewport_rect().size
	initializeClouds()


func initializeClouds() -> void:
	for i: int in range(cloudCound):
		var cloudInstance: Entity = cloudEntityScene.instantiate()
		resetCloudPosition(cloudInstance, true)
		add_child(cloudInstance)

		var screenNotifier: VisibleOnScreenNotifier2D = cloudInstance.findFirstChildOfType(VisibleOnScreenNotifier2D)
		if screenNotifier != null:
			Tools.connectSignal(screenNotifier.screen_exited, onVisibleOnScreenNotifier_screen_exited.bind(cloudInstance))


func resetCloudPosition(cloudInstance: Entity, isInit: bool = false) -> void:
	var viewportRect: Rect2 = get_viewport_rect()
	var startX: float

	if isInit:
		startX = randf() * viewportRect.size.x
	else:
		startX = viewportRect.size.x + 100.0

	var randomY: float = randf_range(minPositionY, maxPositionY)
	cloudInstance.position = Vector2(startX, randomY)
	
	var linearMotionComponent: LinearMotionComponent = cloudInstance.getComponent(LinearMotionComponent)
	if linearMotionComponent:
		linearMotionComponent.speed = 10 + randf_range(-5.0, 5.0)


func onVisibleOnScreenNotifier_screen_exited(cloudInstance: Entity) -> void:
	resetCloudPosition(cloudInstance, false)

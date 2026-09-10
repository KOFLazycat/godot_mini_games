class_name CloudManager
extends Node2D

@export var cloudCound: int = 2
@export var minPositionY: float = 50.0
@export var maxPositionY: float = 250.0
@export var cloudEntityScene: PackedScene = preload("res://Game/Entities/CloudEntity.tscn")
@export var minHorizontalDistance: float = 100.0

var screenSize: Vector2
var cloudInstances: Array[Entity] = []


func _ready() -> void:
	screenSize = get_viewport_rect().size
	initializeClouds()


func initializeClouds() -> void:
	for i: int in range(cloudCound):
		var cloudInstance: Entity = cloudEntityScene.instantiate()
		add_child(cloudInstance)
		cloudInstances.append(cloudInstance)
		resetCloudPosition(cloudInstance, true)

		var screenNotifier: VisibleOnScreenNotifier2D = cloudInstance.findFirstChildOfType(VisibleOnScreenNotifier2D)
		if screenNotifier != null:
			Tools.connectSignal(screenNotifier.screen_exited, onVisibleOnScreenNotifier_screen_exited.bind(cloudInstance))


func resetCloudPosition(cloudInstance: Entity, isInit: bool = false) -> void:
	var viewportRect: Rect2 = get_viewport_rect()
	var startX: float

	if isInit:
		startX = getRandomXWithMinDistance(viewportRect.size.x)
	else:
		startX = viewportRect.size.x + 100.0

	var randomY: float = randf_range(minPositionY, maxPositionY)
	cloudInstance.position = Vector2(startX, randomY)

	var linearMotionComponent: LinearMotionComponent = cloudInstance.getComponent(LinearMotionComponent)
	if linearMotionComponent:
		linearMotionComponent.speed = 10 + randf_range(-5.0, 5.0)


func getRandomXWithMinDistance(screenWidth: float) -> float:
	var maxAttempts: int = 50
	for attempt: int in range(maxAttempts):
		var randomX: float = randf() * screenWidth
		if isHorizontalDistanceValid(randomX):
			return randomX
	return randf() * screenWidth


func isHorizontalDistanceValid(newX: float) -> bool:
	for existingCloud: Entity in cloudInstances:
		if existingCloud == null:
			continue
		var distance: float = abs(newX - existingCloud.position.x)
		if distance < minHorizontalDistance:
			return false
	return true


func onVisibleOnScreenNotifier_screen_exited(cloudInstance: Entity) -> void:
	resetCloudPosition(cloudInstance, false)

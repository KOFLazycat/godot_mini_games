class_name DotManager
extends Node2D

@export var dotWithRopeScene: PackedScene = preload("res://Game/Scenes/Dot/DotWithRope.tscn")
@export var dotTextureFront: Texture

var dots: Array[DotWithRope] = []
const MAX_DOTS: int = 10
const TARGET_DOT_COUNT: int = 5
const FIXED_Y: float = -20.0
const SPAWN_X: float = 400.0


func _ready() -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouseEvent: InputEventMouseButton = event
		if mouseEvent.button_index == MOUSE_BUTTON_LEFT and mouseEvent.pressed:
			addDot()


func addDot() -> void:
	if dots.size() >= MAX_DOTS:
		return

	var newDot: DotWithRope = dotWithRopeScene.instantiate()
	newDot.position = Vector2(SPAWN_X, FIXED_Y)
	if dotTextureFront != null:
		newDot.dotTextureFront = dotTextureFront
	add_child(newDot)
	dots.append(newDot)
	await get_tree().create_timer(0.5).timeout
	
	if dots.size() <= 5:
		newDot.initialize(100.0)
	else:
		newDot.initialize(150.0)
	
	updateDotPositions()


func updateDotPositions() -> void:
	var screenWidth: float = get_viewport_rect().size.x
	var currentCount: int = dots.size()

	for i in range(currentCount):
		var targetX: float = getTargetX(i, currentCount, screenWidth)
		var dot: DotWithRope = dots[i]
		var tween: Tween = create_tween()
		tween.tween_property(dot, "position:x", targetX, 0.5).set_trans(Tween.TRANS_SINE)


func getTargetX(index: int, count: int, screenWidth: float) -> float:
	if count <= TARGET_DOT_COUNT:
		return screenWidth * (index + 1) / (count + 1)
	else:
		if index == 0:
			return screenWidth * 1.0 / 6.0
		elif index == 1:
			return screenWidth * 2.0 / 6.0
		elif index == 2:
			return screenWidth * 3.0 / 6.0
		elif index == 3:
			return screenWidth * 4.0 / 6.0
		elif index == 4:
			return screenWidth * 5.0 / 6.0
		elif index == 5:
			return screenWidth * 1.5 / 6.0
		elif index == 6:
			return screenWidth * 2.5 / 6.0
		elif index == 7:
			return screenWidth * 3.5 / 6.0
		elif index == 8:
			return screenWidth * 4.5 / 6.0
		elif index == 9:
			return screenWidth * 5.5 / 6.0

	return screenWidth * 0.5

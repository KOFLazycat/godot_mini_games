class_name DotManager
extends Node2D

@export var dotWithRopeScene: PackedScene = preload("res://Game/Scenes/Dot/DotWithRope.tscn")
@export var dotTextureFront: Texture
@export var dotAddResource: SoundResource

var dots: Array[DotWithRope] = []
const MAX_DOTS: int = 10
const TARGET_DOT_COUNT: int = 5
const FIXED_Y: float = -20.0
const SPAWN_X: float = 400.0


func _ready() -> void:
	_connectionSignals()


func _exit_tree() -> void:
	_disconnectionSignals()


func _connectionSignals() -> void:
	Tools.connectSignal(GlobalEvent.blockColorAdded, onGlobalEvent_blockColorAdded)
	Tools.connectSignal(GlobalEvent.gameEnded, onGlobalEvent_gameEnded)


func _disconnectionSignals() -> void:
	Tools.disconnectSignal(GlobalEvent.blockColorAdded, onGlobalEvent_blockColorAdded)
	Tools.disconnectSignal(GlobalEvent.gameEnded, onGlobalEvent_gameEnded)


func addDot(dotColor: Color = Color.WHITE) -> void:
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
		newDot.initialize(100.0, dotColor)
	else:
		newDot.initialize(150.0, dotColor)
	
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


func onGlobalEvent_blockColorAdded(color: Color) -> void:
	addDot(color)
	await get_tree().create_timer(0.5).timeout
	if dotAddResource != null:
		dotAddResource.play_managed()


func onGlobalEvent_gameEnded(_isWin: bool) -> void:
	pass

class_name BloodSplatter extends Node2D

@onready var sprite2d: Sprite2D = $Sprite2D
@export var spriteSheetFrameCount: int = 4

@export_color_no_alpha var bloodDarkColor: Color
@export_color_no_alpha var bloodLightColor: Color

@export var minTravelSpeed: float = 500.0
@export var maxTravelSpeed: float = 700.0
@export var inAirScale: float = 0.4
@export var inAirModulatePercent: float = 0.3

var baseColor: Color

const GROUND_Z_INDEX: int = 1
const IN_AIR_Z_INDEX: int = 10

@export var maxBloodScale: float = 0.7
@export var minBloodScale: float = 0.4

@export var chanceToStretch: float = 0.2
@export var splatterSoundResource: SoundResource

var flyDirection: Vector2 = Vector2.RIGHT
var inAir: bool = false
var finalPos: Vector2
@onready var finalScale: Vector2 = scale
@onready var finalAngle: float = global_rotation

var loadedFromSave: bool = false

@export var isStatic: bool = false


func _ready() -> void:
	if loadedFromSave:
		return
	randomizeBloodSplatter()


func randomizeBloodSplatter() -> void:
	sprite2d.frame = randi_range(0, spriteSheetFrameCount - 1)
	if not isStatic:
		sprite2d.rotation = randf_range(0.0, TAU)
		sprite2d.scale = Vector2.ONE * randf_range(minBloodScale, maxBloodScale)
	baseColor = bloodDarkColor.lerp(bloodLightColor, randf_range(0.0, 1.0))
	modulate = baseColor


func flingBlood(startPos: Vector2, endPos: Vector2, shouldPlaySplatterSound: bool = false) -> void:
	if isStatic:
		return

	finalPos = endPos
	flyDirection = startPos.direction_to(endPos)
	z_index = IN_AIR_Z_INDEX
	global_position = startPos
	scale = Vector2.ONE * inAirScale
	modulate = baseColor.lerp(Color.BLACK, inAirModulatePercent)

	if randf_range(0.0, 1.0) < chanceToStretch:
		finalAngle = flyDirection.angle()
		finalScale.y = finalScale.y * 0.7
		finalScale.x = finalScale.x * 1.4

	var travelSpeed: float = randf_range(minTravelSpeed, maxTravelSpeed)
	var travelTime: float = startPos.distance_to(endPos) / travelSpeed

	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", endPos, travelTime)
	tween.tween_callback(onHitGround.bind(shouldPlaySplatterSound))


func onHitGround(shouldPlaySplatterSound: bool = false) -> void:
	modulate = baseColor
	z_index = GROUND_Z_INDEX
	global_rotation = finalAngle
	scale = finalScale

	if shouldPlaySplatterSound and splatterSoundResource:
		splatterSoundResource.play_managed()

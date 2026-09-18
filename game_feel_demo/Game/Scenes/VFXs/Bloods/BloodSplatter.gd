class_name BloodSplatter extends Node2D

@export var spriteSheetFrameCount: int = 4
@export_color_no_alpha var bloodDarkColor : Color
@export_color_no_alpha var bloodLightColor : Color
@export var minTravelSpeed: float = 500.0 # pixels per second
@export var maxTravelSpeed: float = 700.0 # pixels per second
@export var inAirScale: float = 0.4
@export var inAirModulatePercent: float = 0.3 # 0 to 1, determines how dark blood is while flying through air
@export var maxBloodScale: float = 0.7
@export var minBloodScale: float = 0.4
@export var chanceToStretch: float = 0.2
## 血迹消失动画时长
@export var disappearTweenTime: float = 5.0
## 溅血音效
@export var splashListSoundResource: ListSoundResource
@export var isStatic: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var finalScale : Vector2 = scale
@onready var finalAngle : float = global_rotation

var baseColor : Color
const GROUND_Z_INDEX: int = 0
const IN_AIR_Z_INDEX: int = 10
var flyDirection: Vector2 = Vector2.RIGHT
var inAir: bool = false
var finalPos : Vector2

func _ready() -> void:
	randomizeBloodSplatter()


## 获取随机血液图片
func randomizeBloodSplatter() -> void:
	sprite.frame = randi_range(0, spriteSheetFrameCount-1)
	if !isStatic:
		sprite.rotation = randf_range(0.0, TAU)
		sprite.scale = Vector2.ONE*randf_range(minBloodScale, maxBloodScale)
	baseColor = bloodDarkColor.lerp(bloodLightColor, randf_range(0.0, 1.0))
	modulate = baseColor


func flingBlood(startPos: Vector2, endPos: Vector2, shoulePlaySplatterSound: bool = false) -> void:
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
	tween.tween_callback(onHitGround.bind(shoulePlaySplatterSound))


func onHitGround(shoulePlaySplatterSound: bool = false) -> void:
	modulate = baseColor
	z_index = GROUND_Z_INDEX
	global_rotation = finalAngle
	scale = finalScale
	# 播放飞溅音效（校验节点类型和播放标志）
	if shoulePlaySplatterSound and splashListSoundResource and splashListSoundResource.sound_list.size() > 0:
		splashListSoundResource.play_managed()
	
	var tweenDisappear: Tween = create_tween()
	tweenDisappear.tween_property(self, "modulate:a", 0, disappearTweenTime)
	tweenDisappear.tween_callback(queue_free)

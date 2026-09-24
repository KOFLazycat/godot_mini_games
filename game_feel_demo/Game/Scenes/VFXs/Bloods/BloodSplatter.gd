class_name BloodSplatter extends Node2D
## 血迹飞溅特效节点
## 负责血迹的飞行、落地、变形等效果的渲染

## 是否启用调试模式
@export var debugMode: bool = false
## 是否为静态血迹（不进行飞行动画）
@export var isStatic: bool = false
## spritesheet 中的帧数
@export var spriteSheetFrameCount: int = 4
## 血迹暗色（血液凝固后的颜色）
@export_color_no_alpha var bloodDarkColor: Color
## 血迹亮色（新鲜血液的颜色）
@export_color_no_alpha var bloodLightColor: Color
## 飞行最小速度（像素/秒）
@export var minTravelSpeed: float = 500.0
## 飞行最大速度（像素/秒）
@export var maxTravelSpeed: float = 700.0
## 飞行时的缩放比例
@export var inAirScale: float = 0.4
## 飞行时的变暗程度（0-1），值越大飞行的血迹越暗
@export var inAirModulatePercent: float = 0.3
## 血迹最大缩放
@export var maxBloodScale: float = 0.7
## 血迹最小缩放
@export var minBloodScale: float = 0.4
## 变形拉伸的概率
@export var chanceToStretch: float = 0.2
## 落地后等待淡出的时间（秒）
@export var fadeDelay: float = 1.0
## 淡出动画持续时间（秒）
@export var fadeDuration: float = 2.0
## 落地音效资源
@export var splatterSoundResource: SoundResource


@onready var sprite2d: Sprite2D = $Sprite2D
## 最终缩放值（包含拉伸变形）
@onready var finalScale: Vector2 = scale
## 最终旋转角度
@onready var finalAngle: float = global_rotation


## 基础颜色（由暗色和亮色随机混合）
var baseColor: Color
## 落地后的 Z 轴索引
const GROUND_Z_INDEX: int = 1
## 飞行时的 Z 轴索引
const IN_AIR_Z_INDEX: int = 10
## 飞行方向
var flyDirection: Vector2 = Vector2.RIGHT
## 是否在空中飞行
var inAir: bool = false
## 最终落点位置
var finalPos: Vector2
## 是否已落地
var hasLanded: bool = false


## 调试日志输出
func _debugLog(message: String) -> void:
	if debugMode:
		Debug.printDebug(message)


func _ready() -> void:
	visible = false
	randomizeBloodSplatter()


## 随机化血迹外观
## 随机选择帧、旋转、缩放和颜色
func randomizeBloodSplatter() -> void:
	sprite2d.frame = randi_range(0, spriteSheetFrameCount - 1)
	if not isStatic:
		sprite2d.rotation = randf_range(0.0, TAU)
		sprite2d.scale = Vector2.ONE * randf_range(minBloodScale, maxBloodScale)

	# 在暗色和亮色之间随机混合
	baseColor = bloodDarkColor.lerp(bloodLightColor, randf_range(0.0, 1.0))
	modulate = baseColor
	visible = true


## 飞行血迹到目标位置
## @startPos: 起始位置
## @endPos: 目标位置（落地位置）
## @shouldPlaySplatterSound: 是否播放落地音效
func flingBlood(startPos: Vector2, endPos: Vector2, shouldPlaySplatterSound: bool = false) -> void:
	if isStatic:
		_debugLog("BloodSplatter: isStatic 静态血迹跳过飞行")
		hasLanded = true
		return

	finalPos = endPos
	flyDirection = startPos.direction_to(endPos)

	# 设置为飞行层级
	z_index = IN_AIR_Z_INDEX
	global_position = startPos

	# 飞行时缩小
	scale = Vector2.ONE * inAirScale
	# 飞行时变暗
	modulate = baseColor.lerp(Color.BLACK, inAirModulatePercent)

	# 随机决定是否进行拉伸变形（模拟运动模糊效果）
	if randf_range(0.0, 1.0) < chanceToStretch:
		finalAngle = flyDirection.angle()
		# 沿运动方向拉长，垂直方向压扁
		finalScale.y = finalScale.y * 0.7
		finalScale.x = finalScale.x * 1.4
		_debugLog("BloodSplatter: 拉伸变形 angle=%s" % [finalAngle])

	# 计算飞行时间
	var travelSpeed: float = randf_range(minTravelSpeed, maxTravelSpeed)
	var travelTime: float = startPos.distance_to(endPos) / travelSpeed

	_debugLog("BloodSplatter: 开始飞行 startPos=%s endPos=%s travelTime=%.2f" % [startPos, endPos, travelTime])

	# 创建补间动画
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", endPos, travelTime)
	tween.tween_callback(onHitGround.bind(shouldPlaySplatterSound))


## 落地处理
## @shouldPlaySplatterSound: 是否播放落地音效
func onHitGround(shouldPlaySplatterSound: bool = false) -> void:
	hasLanded = true

	# 恢复颜色
	modulate = baseColor
	# 设置为地面层级
	z_index = GROUND_Z_INDEX
	# 应用最终角度和缩放
	global_rotation = finalAngle
	scale = finalScale

	_debugLog("BloodSplatter: 落地 finalPos=%s" % [finalPos])

	# 播放落地音效
	if shouldPlaySplatterSound and splatterSoundResource:
		_debugLog("BloodSplatter: 播放落地音效")
		splatterSoundResource.play_managed()

	# 开始淡出流程
	startFadeOut()


## 开始淡出流程
func startFadeOut() -> void:
	if fadeDelay > 0:
		await get_tree().create_timer(fadeDelay).timeout

	_debugLog("BloodSplatter: 开始淡出 fadeDuration=%s" % [fadeDuration])

	# 创建淡出补间动画
	var tween: Tween = get_tree().create_tween()
	var fadedColor: Color = baseColor
	fadedColor.a = 0.0
	tween.tween_property(self, "modulate", fadedColor, fadeDuration)
	tween.tween_callback(queue_free)

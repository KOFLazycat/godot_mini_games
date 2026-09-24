class_name BloodSpawner extends Node2D

## 血迹生成器
## 根据伤害数据生成血迹飞溅效果、血迹云和音效

## 是否启用调试模式
@export var debugMode: bool = false
## 飞溅最大距离
@export var maxSplatterDist: float = 130.0
## 墙壁偏移量（防止血迹嵌入墙壁）
@export var bloodWallOffset: float = 15.0
## 最大飞溅数量
@export var maxSplatterCount: int = 5
## 最小飞溅数量
@export var minSplatterCount: int = 3
## 血迹喷洒角度范围（度）
@export var bloodSprayArc: float = 180.0
## 撞击音效资源
@export var impactSoundResource: SoundResource
## 血迹 splatter 场景资源
@export var bloodSplatterScene: PackedScene = preload("res://Game/Scenes/VFXs/Bloods/BloodSplatter.tscn")
## 血迹云场景资源
@export var bloodCloudScene: PackedScene = preload("res://Game/Scenes/VFXs/Bloods/BloodCloud.tscn")


## 射线检测组件，用于检测墙壁
@onready var rayCast2d: RayCast2D = $RayCast2D


## 调试日志输出
func _debugLog(message: String) -> void:
	if debugMode:
		Debug.printDebug(message)


## 根据伤害数据生成血迹
## @damagePosition: 伤害发生的世界位置
## @hitNormal: 击中法线方向
## @damageDirection: 伤害来源方向
## @shouldPlaySound: 是否播放音效
## @shouldSpawnExtraBlood: 是否生成额外血迹
## @shouldSpawnBloodCloud: 是否生成血迹云
func spawnBloodFromData(damagePosition: Vector2, hitNormal: Vector2, damageDirection: Vector2, shouldPlaySound: bool, shouldSpawnExtraBlood: bool, shouldSpawnBloodCloud: bool) -> void:
	global_position = damagePosition

	_debugLog("BloodSpawner: 生成血迹 damagePosition=%s hitNormal=%s damageDirection=%s" % [damagePosition, hitNormal, damageDirection])

	# 计算血迹发射方向：综合击中法线和伤害方向
	var dir: Vector2 = hitNormal - damageDirection

	# 向两个方向喷洒血迹
	splatterBlood(dir / 2.0, shouldPlaySound)
	splatterExtraBlood(-dir / 2.0, shouldPlaySound)

	# 如果需要额外血迹，沿着击中法线方向生成
	if shouldSpawnExtraBlood:
		splatterExtraBlood(hitNormal, shouldPlaySound)
		_debugLog("BloodSpawner: 生成额外血迹")

	# 如果需要血迹云
	if shouldSpawnBloodCloud:
		spawnBloodCloud()
		_debugLog("BloodSpawner: 生成血迹云")

	# 播放撞击音效
	if shouldPlaySound and impactSoundResource:
		_debugLog("BloodSpawner: 播放撞击音效")
		impactSoundResource.play_managed()


## 喷洒血迹（基础数量）
## @dir: 喷洒方向
## @shouldPlaySound: 是否播放音效
func splatterBlood(dir: Vector2 = Vector2.DOWN, shouldPlaySound: bool = true) -> void:
	var splatterCount: int = randi_range(minSplatterCount, maxSplatterCount)
	_debugLog("BloodSpawner: 喷洒血迹 count=%s dir=%s" % [splatterCount, dir])

	for i in splatterCount:
		spawnBlood(getSplatterOffset(dir), i % 3 == 0 and shouldPlaySound)


## 喷洒额外血迹（数量翻倍，距离更远）
## @dir: 喷洒方向
## @shouldPlaySound: 是否播放音效
func splatterExtraBlood(dir: Vector2 = Vector2.DOWN, shouldPlaySound: bool = true) -> void:
	var splatterCount: int = randi_range(minSplatterCount, maxSplatterCount) * 2
	_debugLog("BloodSpawner: 喷洒额外血迹 count=%s dir=%s" % [splatterCount, dir])

	for i in splatterCount:
		spawnBlood(getSplatterOffset(dir) * 1.5, i % 3 == 0 and shouldPlaySound)


## 计算飞溅偏移量
## 在指定方向上添加随机角度和距离偏移
## @dir: 基础方向
## 返回: 随机偏移后的位置向量
func getSplatterOffset(dir: Vector2 = Vector2.DOWN) -> Vector2:
	# 随机偏转角度（在 arc 范围内）
	var splatterDir: Vector2 = dir.rotated(deg_to_rad(randf_range(-bloodSprayArc, bloodSprayArc) / 2.0))
	# 随机距离
	var splatterDist: float = randf_range(0.0, maxSplatterDist)
	return splatterDir * splatterDist


## 生成单个血迹实例
## @posOffset: 相对位置偏移
## @playSplatterSound: 是否播放落地音效
func spawnBlood(posOffset: Vector2 = Vector2.ZERO, playSplatterSound: bool = false) -> void:
	var bloodSplatter: BloodSplatter = bloodSplatterScene.instantiate()
	bloodSplatter.debugMode = debugMode
	bloodSplatter.global_position = global_position
	get_tree().get_first_node_in_group("visuals").add_child(bloodSplatter)
	#get_tree().get_root().add_child(bloodSplatter)

	# 计算目标位置
	var goalPos: Vector2 = global_position + posOffset

	# 使用射线检测墙壁，防止血迹嵌入
	rayCast2d.enabled = true
	rayCast2d.target_position = rayCast2d.to_local(goalPos)
	rayCast2d.force_raycast_update()

	if rayCast2d.is_colliding():
		goalPos = rayCast2d.get_collision_point()
		_debugLog("BloodSpawner: 射线检测到墙壁 adjustedPos=%s" % [goalPos])
	rayCast2d.enabled = false
	# 计算墙壁偏移量，使血迹贴在墙上而不是嵌入
	var offset: Vector2 = goalPos.direction_to(global_position) * bloodWallOffset

	_debugLog("BloodSpawner: 生成血迹 from=%s to=%s offset=%s" % [global_position, goalPos, offset])

	# 触发飞行动画
	bloodSplatter.flingBlood(global_position, goalPos + offset, playSplatterSound)


## 生成血迹云（静态装饰效果）
func spawnBloodCloud() -> void:
	var bloodCloud: Node2D = bloodCloudScene.instantiate()
	bloodCloud.global_position = global_position
	get_tree().get_root().add_child(bloodCloud)
	_debugLog("BloodSpawner: 实例化血迹云 at %s" % [global_position])

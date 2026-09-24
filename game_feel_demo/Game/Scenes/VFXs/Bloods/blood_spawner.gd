class_name BloodSpawner extends Node2D

## Spawns blood clouds and flings splatters

@export var bloodSplatterScene: PackedScene = preload("res://Game/Scenes/VFXs/Bloods/blood_splatter.tscn")
@export var bloodCloudScene: PackedScene = preload("res://Game/Scenes/VFXs/Bloods/blood_cloud.tscn")

@export var maxSplatterDist: float = 130.0
@export var bloodWallOffset: float = 15.0

@export var maxSplatterCount: int = 5
@export var minSplatterCount: int = 3

@export var bloodSprayArc: float = 180.0

@export var impactSoundResource: SoundResource

@onready var rayCast2d: RayCast2D = $RayCast2D


func spawnBloodFromDamageData(damagePosition: Vector2, hitNormal: Vector2, damageDirection: Vector2, shouldPlaySound: bool, shouldSpawnExtraBlood: bool, shouldSpawnBloodCloud: bool) -> void:
	global_position = damagePosition

	var dir: Vector2 = hitNormal - damageDirection

	splatterBlood(dir / 2.0, shouldPlaySound)
	splatterExtraBlood(-dir / 2.0, shouldPlaySound)

	if shouldSpawnExtraBlood:
		splatterExtraBlood(hitNormal, shouldPlaySound)

	if shouldSpawnBloodCloud:
		spawnBloodCloud()

	if shouldPlaySound and impactSoundResource:
		impactSoundResource.play_managed()


func splatterBlood(dir: Vector2 = Vector2.DOWN, shouldPlaySound: bool = true) -> void:
	var splatterCount: int = randi_range(minSplatterCount, maxSplatterCount)
	for i in splatterCount:
		spawnBlood(getSplatterOffset(dir), i % 3 == 0 and shouldPlaySound)


func splatterExtraBlood(dir: Vector2 = Vector2.DOWN, shouldPlaySound: bool = true) -> void:
	var splatterCount: int = randi_range(minSplatterCount, maxSplatterCount) * 2
	for i in splatterCount:
		spawnBlood(getSplatterOffset(dir) * 1.5, i % 3 == 0 and shouldPlaySound)


func getSplatterOffset(dir: Vector2 = Vector2.DOWN) -> Vector2:
	var splatterDir: Vector2 = dir.rotated(deg_to_rad(randf_range(-bloodSprayArc, bloodSprayArc) / 2.0))
	var splatterDist: float = randf_range(0.0, maxSplatterDist)
	return splatterDir * splatterDist


func spawnBlood(posOffset: Vector2 = Vector2.ZERO, playSplatterSound: bool = false) -> void:
	var bloodSplatter: BloodSplatter = bloodSplatterScene.instantiate()
	get_tree().get_root().add_child(bloodSplatter)

	var goalPos: Vector2 = global_position + posOffset
	rayCast2d.enabled = true
	rayCast2d.target_position = rayCast2d.to_local(goalPos)
	rayCast2d.force_raycast_update()

	if rayCast2d.is_colliding():
		goalPos = rayCast2d.get_collision_point()

	rayCast2d.enabled = false

	var offset: Vector2 = goalPos.direction_to(global_position) * bloodWallOffset
	bloodSplatter.flingBlood(global_position, goalPos + offset, playSplatterSound)


func spawnBloodCloud() -> void:
	var bloodCloud: Node2D = bloodCloudScene.instantiate()
	bloodCloud.global_position = global_position
	get_tree().get_root().add_child(bloodCloud)

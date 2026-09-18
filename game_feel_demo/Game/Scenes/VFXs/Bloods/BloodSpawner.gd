class_name BloodSpawner extends Node2D

## Spawns blood clouds and flings splatters
@export var bloodSplatterScene: PackedScene
@export var bloodCloudScene: PackedScene
@export var maxSplatterDist: float = 130.0
@export var bloodWallOffset: float = 15.0
@export var maxSplatterCount: int = 5
@export var minSplatterCount: int = 3
@export var bloodSprayArc: float = 180.0
@export var parentGroupName: StringName = "visuals"

@onready var rayCast: RayCast2D = $RayCast2D

var parentNode: Node

func _ready() -> void:
	if not parentGroupName.is_empty():
		parentNode = get_tree().get_first_node_in_group(parentGroupName)
	if parentNode == null:
		parentNode = get_tree().get_root()


func spawnBloodFromParameter(damagePosition: Vector2, damageDirection: Vector2, shoulePlaySplatterSound: bool = true, shouldSpawnBloodCloud: bool = false) -> void:
	global_position = damagePosition
	# spray blood in both directions
	splatterBlood(damageDirection / 2.0, shoulePlaySplatterSound)
	splatterExtraBlood(-damageDirection / 2.0, shoulePlaySplatterSound)
	
	if shouldSpawnBloodCloud:
		spawnBloodCloud()


func splatterBlood(dir: Vector2 = Vector2.DOWN, shoulePlaySplatterSound: bool = true) -> void:
	var splatterCount: int = randi_range(minSplatterCount, maxSplatterCount)
	for i in splatterCount:
		spawnBlood(getSplatterOffset(dir), i%3==0 and shoulePlaySplatterSound)


func splatterExtraBlood(dir: Vector2 = Vector2.DOWN, shoulePlaySplatterSound: bool = true) -> void:
	var splatterCount: int = randi_range(minSplatterCount, maxSplatterCount) * 2
	for i: int in splatterCount:
		spawnBlood(getSplatterOffset(dir) * 1.5, i%3==0 and shoulePlaySplatterSound)


func getSplatterOffset(dir: Vector2 = Vector2.DOWN) -> Vector2:
	var splatterDir: Vector2 = dir.rotated(deg_to_rad(randf_range(-bloodSprayArc, bloodSprayArc)/2.0))
	var splatterDist: float = randf_range(0.0, maxSplatterDist)
	return splatterDir * splatterDist


func spawnBlood(posOffset: Vector2 = Vector2.ZERO, shoulePlaySplatterSound: bool = false) -> void:
	var bloodSplatter: BloodSplatter = bloodSplatterScene.instantiate()
	bloodSplatter.global_position = global_position
	parentNode.add_child(bloodSplatter)
	
	var goalPos: Vector2 = global_position + posOffset
	rayCast.enabled = true
	rayCast.target_position = rayCast.to_local(goalPos)
	rayCast.force_raycast_update()
	if rayCast.is_colliding():
		goalPos = rayCast.get_collision_point()
	rayCast.enabled = false
	
	var offset: Vector2 = goalPos.direction_to(global_position) * bloodWallOffset
	bloodSplatter.flingBlood(global_position, goalPos + offset, shoulePlaySplatterSound)


func spawnBloodCloud() -> void:
	var bloodCloud: Node2D = bloodCloudScene.instantiate()
	bloodCloud.global_position = global_position
	parentNode.add_child(bloodCloud)

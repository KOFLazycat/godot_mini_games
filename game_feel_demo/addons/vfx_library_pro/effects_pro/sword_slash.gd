extends Node2D
## 剑气斩击特效
## 🔒 商业版独占
## 从起点到终点的华丽剑气轨迹

@onready var trail = $SlashTrail
@onready var particles = $SlashParticles
@onready var glow = $SlashGlow
@onready var impact = $ImpactFlash

const TRAIL_DURATION = 0.3
const SLASH_SPEED = 2000.0

var start_pos: Vector2
var end_pos: Vector2
var slash_color: Color = Color(0.8, 0.9, 1, 1)


func _ready() -> void:
	if start_pos != Vector2.ZERO and end_pos != Vector2.ZERO:
		create_slash(start_pos, end_pos, slash_color)


func create_slash(from: Vector2, to: Vector2, color: Color = Color.WHITE) -> void:
	start_pos = from
	end_pos = to
	slash_color = color
	
	# 设置颜色
	trail.default_color = color
	particles.color = color
	glow.color = Color(color.r * 1.2, color.g * 1.2, color.b * 1.2, 0.8)
	
	# 计算方向和距离
	var direction = (to - from).normalized()
	var distance = from.distance_to(to)
	var angle = direction.angle()
	
	# 设置轨迹线的位置和旋转
	global_position = from
	trail.rotation = angle
	
	# 粒子位置设置到中点
	var mid_point = (to - from) / 2
	particles.position = mid_point
	particles.rotation = angle
	glow.position = mid_point
	glow.rotation = angle
	
	# 调整粒子发射范围
	particles.emission_rect_extents = Vector2(distance / 2, 10)
	glow.emission_rect_extents = Vector2(distance / 2, 5)
	
	# 播放轨迹动画
	_animate_trail(distance)
	
	# 启动粒子
	particles.restart()
	glow.restart()
	
	# 终点冲击特效
	impact.global_position = to
	impact.restart()
	
	# 自动清理
	await get_tree().create_timer(0.8).timeout
	queue_free()


func _animate_trail(distance: float) -> void:
	if not trail:
		return
	
	# 生成轨迹点
	var point_count = int(distance / 10) + 2
	var points: Array[Vector2] = []
	
	var tween = create_tween()
	
	# 从0到完整距离动画
	for i in range(point_count + 1):
		var t = float(i) / point_count
		var offset = t * distance
		
		# 添加轻微的曲线波动
		var wave_offset = sin(t * PI) * 5.0
		var point = Vector2(offset, wave_offset)
		points.append(point)
	
	# 动画显示轨迹
	tween.tween_method(_update_trail_points, 0.0, 1.0, TRAIL_DURATION)
	
	# 淡出
	tween.tween_property(trail, "modulate:a", 0.0, 0.3)


func _update_trail_points(progress: float) -> void:
	if not trail:
		return
	
	var direction = (end_pos - start_pos).normalized()
	var distance = start_pos.distance_to(end_pos)
	var current_distance = distance * progress
	
	var point_count = int(current_distance / 10) + 2
	var points: PackedVector2Array = []
	
	for i in range(point_count):
		var t = float(i) / max(point_count - 1, 1)
		var offset = t * current_distance
		
		# 添加轻微的曲线波动
		var wave_offset = sin(t * PI) * randf_range(3.0, 8.0)
		points.append(Vector2(offset, wave_offset))
	
	trail.points = points

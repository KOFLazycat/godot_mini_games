extends Node2D
## 爆炸冲击波特效
## 🔒 商业版独占
## 多层次冲击波 + 爆炸粒子 + 火焰 + 烟雾 + 碎片

@onready var wave1 = $ShockWave1
@onready var wave2 = $ShockWave2
@onready var wave3 = $ShockWave3
@onready var explosion_particles = $ExplosionParticles
@onready var fire_particles = $FireParticles
@onready var smoke_particles = $SmokeParticles
@onready var debris_particles = $DebrisParticles

const WAVE_SEGMENTS = 48
const MAX_RADIUS = 300.0
const EXPANSION_DURATION = 0.6


func _ready() -> void:
	create_explosion()


func create_explosion(radius: float = MAX_RADIUS, color: Color = Color(1, 0.5, 0.2)) -> void:
	# 设置颜色
	wave1.default_color = color
	wave2.default_color = Color(color.r, color.g * 1.2, color.b * 1.5, 0.6)
	wave3.default_color = Color(color.r * 1.2, color.g * 1.2, color.b * 1.2, 0.3)
	
	explosion_particles.color = color
	fire_particles.color = Color(color.r, color.g * 0.5, color.b * 0.2)
	
	# 启动所有粒子
	explosion_particles.restart()
	fire_particles.restart()
	smoke_particles.restart()
	debris_particles.restart()
	
	# 冲击波扩散动画
	_animate_shockwave(wave1, radius, 0.0, EXPANSION_DURATION)
	_animate_shockwave(wave2, radius * 1.2, 0.1, EXPANSION_DURATION * 1.1)
	_animate_shockwave(wave3, radius * 1.4, 0.2, EXPANSION_DURATION * 1.2)
	
	# 自动清理
	await get_tree().create_timer(2.0).timeout
	queue_free()


func _animate_shockwave(wave: Line2D, max_radius: float, delay: float, duration: float) -> void:
	if not wave:
		return
	
	await get_tree().create_timer(delay).timeout
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 半径扩散
	tween.tween_method(
		func(radius: float): _update_wave_circle(wave, radius),
		0.0,
		max_radius,
		duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 透明度变化
	tween.tween_property(wave, "modulate:a", 0.0, duration * 0.8).set_delay(duration * 0.2)


func _update_wave_circle(wave: Line2D, radius: float) -> void:
	if not wave:
		return
	
	var points: PackedVector2Array = []
	
	for i in range(WAVE_SEGMENTS + 1):
		var angle = (float(i) / WAVE_SEGMENTS) * TAU
		
		# 添加随机扰动，制造不规则冲击波效果
		var distortion = randf_range(0.9, 1.1)
		var current_radius = radius * distortion
		
		var x = cos(angle) * current_radius
		var y = sin(angle) * current_radius
		points.append(Vector2(x, y))
	
	wave.points = points

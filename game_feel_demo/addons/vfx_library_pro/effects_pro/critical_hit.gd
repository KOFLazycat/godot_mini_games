extends Node2D
## 暴击特效
## 🔒 商业版独占
## 华丽的暴击冲击 + 星爆 + 光线 + 屏幕闪光

@onready var impact_burst = $ImpactBurst
@onready var shock_wave = $ShockWave
@onready var star1 = $StarBurst1
@onready var star2 = $StarBurst2
@onready var glow = $GlowParticles
@onready var light_rays = $LightRays
@onready var flash = $FlashLight

const WAVE_SEGMENTS = 48
const STAR_RAYS = 8
const MAX_WAVE_RADIUS = 200.0


func _ready() -> void:
	trigger_critical()


func trigger_critical(damage_multiplier: float = 2.0) -> void:
	# 启动所有粒子
	impact_burst.restart()
	glow.restart()
	light_rays.restart()
	
	# 根据暴击倍率调整特效强度
	var intensity = clamp(damage_multiplier / 3.0, 0.5, 2.0)
	impact_burst.amount = int(60 * intensity)
	glow.amount = int(40 * intensity)
	light_rays.amount = int(20 * intensity)
	
	# 冲击波扩散
	_animate_shockwave()
	
	# 星爆效果
	_animate_starburst()
	
	# 屏幕闪光
	_flash_screen()
	
	# 自动清理
	await get_tree().create_timer(1.2).timeout
	queue_free()


func _animate_shockwave() -> void:
	if not shock_wave:
		return
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 扩散动画
	tween.tween_method(
		func(radius: float): _update_wave_circle(radius),
		0.0,
		MAX_WAVE_RADIUS,
		0.5
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 淡出
	tween.tween_property(shock_wave, "modulate:a", 0.0, 0.4).set_delay(0.1)


func _update_wave_circle(radius: float) -> void:
	if not shock_wave:
		return
	
	var points: PackedVector2Array = []
	
	for i in range(WAVE_SEGMENTS + 1):
		var angle = (float(i) / WAVE_SEGMENTS) * TAU
		var x = cos(angle) * radius
		var y = sin(angle) * radius
		points.append(Vector2(x, y))
	
	shock_wave.points = points


func _animate_starburst() -> void:
	if not star1 or not star2:
		return
	
	# 第一层星爆
	_create_star(star1, 100.0, 0.0)
	# 第二层星爆（稍晚稍大）
	await get_tree().create_timer(0.05).timeout
	_create_star(star2, 120.0, PI / STAR_RAYS)


func _create_star(star: Line2D, max_length: float, angle_offset: float) -> void:
	var points: PackedVector2Array = []
	points.append(Vector2.ZERO)
	
	# 创建星芒射线
	for i in range(STAR_RAYS):
		var angle = (float(i) / STAR_RAYS) * TAU + angle_offset
		var dir = Vector2(cos(angle), sin(angle))
		
		# 添加中心点
		points.append(Vector2.ZERO)
		# 添加射线终点
		points.append(dir * max_length)
	
	points.append(Vector2.ZERO)
	star.points = points
	
	# 射线伸展动画
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(star, "scale", Vector2.ONE, 0.2).from(Vector2(0.1, 0.1))
	tween.tween_property(star, "modulate:a", 0.0, 0.4).set_delay(0.1)


func _flash_screen() -> void:
	if not flash:
		return
	
	# 快速闪白
	var tween = create_tween()
	tween.tween_property(flash, "color", Color(1.5, 1.5, 1.5, 1), 0.05)
	tween.tween_property(flash, "color", Color(1, 1, 1, 1), 0.15)
	
	await tween.finished
	flash.queue_free()

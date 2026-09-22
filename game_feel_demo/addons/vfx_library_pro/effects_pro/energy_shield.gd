extends Node2D
## 能量护盾特效
## 🔒 商业版独占
## 旋转的双环护盾 + 能量流动粒子

@onready var ring1 = $ShieldRing1
@onready var ring2 = $ShieldRing2
@onready var shield_particles = $ShieldParticles
@onready var energy_flow = $EnergyFlow
@onready var glow_particles = $GlowParticles
@onready var rotation_timer = $RotationTimer

const RING_SEGMENTS = 64
const SHIELD_RADIUS = 80.0
const ROTATION_SPEED = 2.0

var shield_active = true
var shield_color: Color = Color(0.3, 0.7, 1, 0.8)
var rotation_angle = 0.0
var pulse_time = 0.0


func _ready() -> void:
	_create_shield_rings()
	rotation_timer.timeout.connect(_on_rotation_timer_timeout)


func _create_shield_rings() -> void:
	# 创建第一个护盾环（外环）
	var points1: PackedVector2Array = []
	for i in range(RING_SEGMENTS + 1):
		var angle = (float(i) / RING_SEGMENTS) * TAU
		var x = cos(angle) * SHIELD_RADIUS
		var y = sin(angle) * SHIELD_RADIUS
		points1.append(Vector2(x, y))
	ring1.points = points1
	
	# 创建第二个护盾环（内环，稍小）
	var points2: PackedVector2Array = []
	for i in range(RING_SEGMENTS + 1):
		var angle = (float(i) / RING_SEGMENTS) * TAU
		var x = cos(angle) * (SHIELD_RADIUS * 0.85)
		var y = sin(angle) * (SHIELD_RADIUS * 0.85)
		points2.append(Vector2(x, y))
	ring2.points = points2


func _on_rotation_timer_timeout() -> void:
	if not shield_active:
		return
	
	rotation_angle += ROTATION_SPEED * rotation_timer.wait_time
	pulse_time += rotation_timer.wait_time
	
	# 旋转两个环（不同速度）
	ring1.rotation = rotation_angle
	ring2.rotation = -rotation_angle * 1.5
	
	# 脉冲效果
	var pulse = abs(sin(pulse_time * 3.0))
	var alpha = lerp(0.6, 1.0, pulse)
	
	ring1.modulate.a = alpha * 0.8
	ring2.modulate.a = alpha * 0.5
	shield_particles.modulate.a = alpha * 0.6


func set_shield_color(color: Color) -> void:
	shield_color = color
	ring1.default_color = color
	ring2.default_color = Color(color.r * 1.2, color.g * 1.2, color.b * 1.2, color.a * 0.6)
	shield_particles.color = Color(color.r, color.g, color.b, 0.6)
	energy_flow.color = Color(color.r * 1.1, color.g * 1.1, color.b * 1.1, 0.8)
	glow_particles.color = Color(color.r * 1.3, color.g * 1.3, color.b * 1.3, 0.3)


func activate(duration: float = -1) -> void:
	shield_active = true
	show()
	
	# 护盾展开动画
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).from(Vector2(0.1, 0.1))
	tween.tween_property(self, "modulate:a", 1.0, 0.3).from(0.0)
	
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		deactivate()


func deactivate() -> void:
	shield_active = false
	
	# 护盾收缩动画
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	queue_free()


func hit_effect() -> void:
	# 受击闪烁效果
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(2, 2, 2, 1), 0.1)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.15)
	
	# 增加粒子爆发
	var burst = energy_flow.duplicate()
	add_child(burst)
	burst.amount = 20
	burst.one_shot = true
	burst.emitting = true
	burst.explosiveness = 1.0
	burst.initial_velocity_max = 150.0
	
	await get_tree().create_timer(burst.lifetime).timeout
	burst.queue_free()

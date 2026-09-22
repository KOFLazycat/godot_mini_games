extends Node2D
## 蓄力特效
## 🔒 商业版独占
## 能量汇聚 + 闪电弧 + 脉冲环

@onready var core_glow = $CoreGlow
@onready var energy_stream = $EnergyStream
@onready var lightning1 = $LightningArcs
@onready var lightning2 = $LightningArcs2
@onready var lightning3 = $LightningArcs3
@onready var pulse_ring = $PulseRing
@onready var inner_glow = $InnerGlow

const RING_SEGMENTS = 48
const LIGHTNING_SEGMENTS = 8

var charge_progress: float = 0.0
var charge_color: Color = Color(0.5, 0.8, 1)
var is_charging: bool = false
var lightning_timer: float = 0.0


func _ready() -> void:
    set_process(false)


func start_charging(duration: float = 2.0, color: Color = Color(0.5, 0.8, 1)) -> void:
    charge_color = color
    is_charging = true
    set_process(true)
    
    # 设置颜色
    core_glow.color = color
    energy_stream.color = Color(color.r * 0.8, color.g, color.b, 0.6)
    inner_glow.color = Color(color.r * 1.2, color.g * 1.2, color.b * 1.2, 0.4)
    
    # 蓄力进度动画
    var tween = create_tween()
    tween.tween_property(self, "charge_progress", 1.0, duration)
    
    await tween.finished
    complete_charging()


func complete_charging() -> void:
    is_charging = false
    
    # 完成时的爆发效果
    var burst = core_glow.duplicate()
    add_child(burst)
    burst.amount = 100
    burst.one_shot = true
    burst.explosiveness = 1.0
    burst.initial_velocity_max = 300.0
    burst.radial_accel_min = 50.0
    burst.radial_accel_max = 100.0
    burst.emitting = true
    
    await get_tree().create_timer(burst.lifetime).timeout
    burst.queue_free()
    queue_free()


func _process(delta: float) -> void:
    if not is_charging:
        return
    
    lightning_timer += delta
    
    # 更新粒子强度
    var intensity = charge_progress
    core_glow.amount = int(50 * intensity) + 1
    energy_stream.amount = int(80 * intensity) + 1
    
    # 闪电弧效果（越充越密集）
    if lightning_timer > 0.1 / max(intensity, 0.1):
        lightning_timer = 0.0
        _create_lightning_arc(lightning1, 100.0 * intensity)
        _create_lightning_arc(lightning2, 120.0 * intensity)
        _create_lightning_arc(lightning3, 140.0 * intensity)
    
    # 脉冲环
    _update_pulse_ring(intensity)


func _create_lightning_arc(line: Line2D, max_dist: float) -> void:
    if not line:
        return
    
    var angle = randf() * TAU
    var end_point = Vector2(cos(angle), sin(angle)) * max_dist
    
    var points: PackedVector2Array = []
    points.append(Vector2.ZERO)
    
    # 创建闪电路径（折线）
    for i in range(1, LIGHTNING_SEGMENTS):
        var t = float(i) / LIGHTNING_SEGMENTS
        var base_pos = end_point * t
        
        # 随机偏移
        var offset = Vector2(
            randf_range(-20, 20),
            randf_range(-20, 20)
        )
        
        points.append(base_pos + offset)
    
    points.append(end_point)
    line.points = points
    
    # 闪电闪烁
    line.modulate.a = randf_range(0.5, 1.0)
    
    # 淡出
    var tween = create_tween()
    tween.tween_property(line, "modulate:a", 0.0, 0.2)


func _update_pulse_ring(intensity: float) -> void:
    if not pulse_ring:
        return
    
    var radius = 50.0 + intensity * 30.0
    var points: PackedVector2Array = []
    
    for i in range(RING_SEGMENTS + 1):
        var angle = (float(i) / RING_SEGMENTS) * TAU
        var distortion = 1.0 + sin(angle * 3.0 + Time.get_ticks_msec() * 0.01) * 0.1
        var x = cos(angle) * radius * distortion
        var y = sin(angle) * radius * distortion
        points.append(Vector2(x, y))
    
    pulse_ring.points = points
    
    # 脉冲透明度
    var pulse = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.005)
    pulse_ring.modulate.a = pulse * intensity

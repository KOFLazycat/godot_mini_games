## TimerFreeParticle
## 定时释放粒子特效节点
##
## 功能：
## - 自动管理粒子特效的生命周期
## - 支持爆炸和冲击波动画
## - 支持随机旋转
## - 播放完成后自动释放
##
## 使用方法：
## 1. 在场景中添加此节点作为根节点
## 2. 添加子节点：GPUParticles2D、Sprite2D、AnimationPlayer
## 3. 在代码中调用 emitParticles() 播放特效
## 4. 播放完成后自动释放节点
##
## 节点结构示例：
## TimerFreeParticle (根节点)
## ├── Timer (子节点)
## ├── GPUParticles2D (粒子)
## ├── Explosion (Sprite2D - 爆炸特效)
## ├── Shockwave (Sprite2D - 冲击波)
## └── AnimationPlayer (动画播放器)

class_name TimerFreeParticle
extends Node2D


#region Parameters
## ============================================================================
## 导出参数
## ============================================================================

## 自动释放的时间（秒）
@export var timeToFree: float = 1.0:
	set(newValue):
		timeToFree = newValue
		if timer != null:
			timer.wait_time = timeToFree

## 动画播放器节点中播放的动画名称
@export var animationName: StringName = &"default"

## 是否随机旋转节点
@export var shouldRandomRotation: bool = false

## 是否启用爆炸效果
@export var enableExplosion: bool = true

## 是否启用冲击波效果
@export var enableShockwave: bool = true

## 爆炸/冲击波动画持续时间（秒）
@export var explosionDuration: float = 0.25

## 爆炸颜色（爆炸消失时的颜色）
@export var explosionColor: Color = Color(0.945, 0.537, 0.086, 0.0)

## 冲击波初始透明度
@export var shockwaveInitialAlpha: float = 0.25

## 冲击波相对于爆炸的缩放比例
@export var shockwaveScaleRatio: float = 0.7

#endregion


#region Dependencies
## ============================================================================
## 依赖
## ============================================================================

@onready var timer: Timer = $Timer

#endregion


#region Signal
## ============================================================================
## 信号
## ============================================================================

## 粒子特效播放完成信号
signal didFinishParticle()

#endregion


#region State
## ============================================================================
## 状态变量
## ============================================================================

## 获取冲击波颜色
var shockwaveColor: Color:
	get:
		return Color(explosionColor.r, explosionColor.g, explosionColor.b)

#endregion


#region Lifecycle
## ============================================================================
## 生命周期
## ============================================================================

func _ready() -> void:
	## 设置定时器时间
	timer.wait_time = timeToFree
	## 连接定时器超时信号
	Tools.connectSignal(timer.timeout, self.onTimer_timeout)


func _exit_tree() -> void:
	Tools.disconnectSignal(timer.timeout, self.onTimer_timeout)

#endregion


#region Public Methods
## ============================================================================
## 公开方法
## ============================================================================

## 发射粒子特效
##
## 完整的粒子发射流程：启动定时器 → 随机旋转 → 显示子节点 → 播放爆炸 → 播放动画
##
## @param _scale - 爆炸特效的缩放比例
func emitParticles(_scale: float = 1.0) -> void:
	## 1. 启动定时器
	startTimer()

	## 2. 随机旋转（如果启用）
	applyRandomRotation()

	## 3. 显示子节点（粒子等）
	showChildren()

	## 4. 播放爆炸效果
	if enableExplosion:
		emitExplosion(_scale)

	## 5. 播放动画
	playAnimation()

	## 6. 发送完成信号（如果禁用了爆炸和动画，立即触发）
	if not enableExplosion and (animationName.is_empty() or not hasAnimationPlayer()):
		didFinishParticle.emit()


## 停止粒子特效
##
## 立即停止并释放节点
func stopParticles() -> void:
	hideChildren()
	stopAllParticles()
	didFinishParticle.emit()
	queue_free.call_deferred()


#endregion


#region Private Methods
## ============================================================================
## 私有方法
## ============================================================================

## 启动定时器
func startTimer() -> void:
	timer.start()


## 应用随机旋转
func applyRandomRotation() -> void:
	if shouldRandomRotation:
		rotation = randf_range(0, TAU)


## 显示所有子节点
func showChildren() -> void:
	for child: Node in get_children():
		if child is Node2D and child != timer:
			child.visible = true


## 隐藏所有子节点
func hideChildren() -> void:
	for child: Node in get_children():
		if child is Node2D and child != timer:
			child.visible = false


## 停止所有粒子发射
func stopAllParticles() -> void:
	for child: Node in get_children():
		if child is GPUParticles2D:
			var particle: GPUParticles2D = child as GPUParticles2D
			## 如果不是一次性粒子且正在发射，则停止
			if not particle.one_shot and particle.emitting:
				particle.emitting = false


## 播放爆炸和冲击波动画
func emitExplosion(_scale: float = 1.0) -> void:
	## 查找爆炸和冲击波节点
	var explosion: Sprite2D = find_child("Explosion", false, false) as Sprite2D
	var shockwave: Sprite2D = find_child("Shockwave", false, false) as Sprite2D

	## 如果缺少必要的节点，直接停止粒子并返回
	if explosion == null or shockwave == null:
		turnOffParticles.call_deferred()
		return

	## 随机旋转爆炸效果
	explosion.rotation = randf_range(0, TAU)

	## 创建 Tween 动画
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)

	## 爆炸效果：缩放 + 渐隐
	if enableExplosion:
		tween.tween_property(explosion, "scale", Vector2.ONE * _scale, explosionDuration)
		tween.parallel().tween_property(explosion, "modulate", explosionColor, explosionDuration)

	## 冲击波效果：缩放 + 渐隐
	if enableShockwave:
		tween.parallel().tween_property(shockwave, "scale", Vector2.ONE * _scale * shockwaveScaleRatio, explosionDuration)
		tween.parallel().tween_property(shockwave, "modulate", Color(shockwaveColor.r, shockwaveColor.g, shockwaveColor.b, shockwaveInitialAlpha), explosionDuration)

	## 动画完成后停止粒子
	tween.tween_callback(turnOffParticles)


## 播放 AnimationPlayer 动画
func playAnimation() -> void:
	if animationName.is_empty():
		return

	var animationPlayer: AnimationPlayer = find_child("AnimationPlayer", false, false) as AnimationPlayer
	if animationPlayer != null and animationPlayer.has_animation(animationName):
		animationPlayer.play(animationName)


## 检查是否存在 AnimationPlayer
func hasAnimationPlayer() -> bool:
	return find_child("AnimationPlayer", false, false) != null


## 关闭粒子效果
func turnOffParticles() -> void:
	## 隐藏非粒子节点
	hideChildren()

	## 停止粒子发射
	stopAllParticles()


## 定时器超时回调
func onTimer_timeout() -> void:
	didFinishParticle.emit()
	queue_free.call_deferred()

#endregion

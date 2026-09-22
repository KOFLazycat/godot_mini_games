## 定时自动清理
class_name TimedParticleBase
extends Node2D

#region Parameters
## 是否启用
@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
## 是否开启试
@export var debugMode: bool = false
## 粒子节点清理限时
@export_range(0.1, 10.0, 0.1) var timeToFree: float = 1.0

#endregion


#region State

#endregion


#region Signals
## 粒子特效播放完成信号
signal didFinishParticle()
#endregion


#region Dependencies
@onready var particles: Node2D = $Particles
@onready var sprites: Node2D = $Sprites
@onready var animations: Node2D = $Animations
@onready var timer: Timer = $Timer
#endregion


func _ready() -> void:
	timer.wait_time = timeToFree
	visible = false
	_connectSignals()


func _exit_tree() -> void:
	_disconnectSignals()


func _connectSignals() -> void:
	Tools.connectSignal(timer.timeout, onTimer_timeout)


func _disconnectSignals() -> void:
	Tools.disconnectSignal(timer.timeout, onTimer_timeout)


#region Emit

## 开启粒子特效
func startParticles() -> void:
	timer.start()
	visible = true
	for c: Node in particles.get_children():
		if c is GPUParticles2D and not c.emitting:
			c.emitting = true
		elif c is CPUParticles2D and not c.emitting:
			c.emitting = true


## 关闭粒子特效
func stopParticles(timeWait: float = 0.1) -> void:
	if timeWait > 0.0:
		await get_tree().create_timer(timeWait).timeout
	onTimer_timeout()

#endregion


#region Signal Handler

func onTimer_timeout() -> void:
	visible = false
	didFinishParticle.emit()
	queue_free.call_deferred()

#endregion

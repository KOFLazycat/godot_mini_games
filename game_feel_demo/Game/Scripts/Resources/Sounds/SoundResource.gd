## SoundResource — 音效资源配置
##
## 定义"一个音效应该如何播放"的数据结构。
## 包含音频文件、音量、音高范围、重触发冷却、连击音高变化等参数。
## [br]
## 使用方式：
## 1. 在编辑器中创建 SoundResource 资源文件。
## 2. 关联音效文件并配置参数。
## 3. 通过 SoundEmitterNode / SoundPlayer / SoundManager 触发播放。
## [br]
## 扩展方式：
## - ListSoundResource：从多个音频中顺序/随机选一个播放。
## - NestedSoundResource：从多个 SoundResource 子对象中选一个播放。
## - 子类重写 get_sound() / get_volume() / get_pitch() 可自定义行为。
class_name SoundResource
extends Resource

## 随机音高的最低值（播放时在此范围内随机选择）
@export var pitch_min:float = 1.0

## 随机音高的最高值（播放时在此范围内随机选择）
@export var pitch_max:float = 1.0

## 播放音量（分贝 dB），范围 -80 到 +24
@export_range(-80.0, +24.0) var volume:float = 0.0

## 重触发冷却时间（秒）。在此时间内的再次触发会被忽略。
## 用于防止同一动作快速触发多次音效导致声音过于密集。
@export var retrigger_time:float = 0.032

## 从指定位置开始播放（秒）。默认为 0.0 表示从头播放。
## 可用于播放音频的某个特定片段。
@export var from_position:float = 0.0

## 快速连击时每次额外增加的音高偏移值。
## 值越大，快速连击时音调升高越明显（连击紧迫感效果）。
@export var pitch_add:float = 0.0

## 快速触发时音高增加效果的持续时间阈值（秒）。
## 触发后在这个时间窗口内，每次都会累加 pitch_add。
@export var pitch_cooldown:float

## 音高从升高状态回落到正常水平所需的时间（秒）。
## 在 pitch_cooldown 之后，音高会在 pitch_return 时间内线性回落。
@export var pitch_return:float

## 实际播放的音频文件
@export var sound:AudioStream

## 上一次触发播放的时间戳（秒），用于计算重触发和连击效果
var last_play_time:float

## 距上次触发的时间间隔（秒）
var delta:float

## 当前分配给此资源的 AudioStreamPlayer 实例引用
var sound_player:SoundPlayer

## 当前使用的音高值（会随连击系统动态变化）
var pitch:float

## 获取要播放的音频流。
## 可被子类重写以实现从列表中选取等逻辑。
func get_sound()->AudioStream:
	return sound

## 计算并返回当前应使用的音高值。
##
## 三段逻辑：
## 1. 连击阶段（delta < pitch_cooldown）：音高持续累加 pitch_add
## 2. 回落阶段（delta < pitch_cooldown + pitch_return）：音高线性插值回落
## 3. 重置阶段：音高重置为随机值（pitch_min ~ pitch_max 之间）
func get_pitch()->float:
	if delta < pitch_cooldown:
		# 仍在连击窗口内，音高累加
		pitch = pitch + pitch_add
		return pitch
	elif delta < pitch_cooldown + pitch_return:
		# 连击结束，开始回落
		var pitch_lerp:float = lerp(pitch_min, pitch_max, 0.5)
		var t:float = (delta - pitch_cooldown) / pitch_return
		pitch = lerp(pitch, pitch_lerp, t)
	else:
		# 完全冷却，重置为新的随机值
		pitch = randf_range(pitch_min, pitch_max)
	return pitch

## 获取当前音量。可被子类重写以实现动态音量等逻辑。
func get_volume()->float:
	return volume

## 使用指定的 SoundPlayer 播放此音效。
## 会检查重触发冷却、计算随机音高、设置音量和音调后启动播放。
func play(_sound_player:SoundPlayer)->void:
	var time: = Time.get_ticks_msec() * 0.001
	# 检查重触发冷却：距离上次播放时间过短则忽略本次触发
	if time < last_play_time + retrigger_time:
		return
	# 更新计时器和连击间隔
	delta = time - last_play_time
	sound_player = _sound_player
	last_play_time = time
	# 应用音效参数并播放
	sound_player.stream = get_sound()
	sound_player.pitch_scale = get_pitch()
	sound_player.volume_db = get_volume()
	sound_player.play(from_position)

## 通过 SoundManager 单例托管播放。
## 适用于场景切换时仍需播放完音效的场景。
## SoundManager 会从对象池中取 SoundPlayer 来播放。
func play_managed()->void:
	SoundManager.play(self)

## 停止当前音效播放。
func stop()->void:
	if sound_player == null:
		return
	sound_player.stop()

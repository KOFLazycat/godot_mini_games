@tool
extends AudioStream
class_name SeamlessStream
## [SeamlessStream] — 无缝循环音频流
##
## 继承自 [AudioStream]，用于解决普通音频循环在衔接处的可察觉断层问题。
## 原理：在当前音频播放结束前，提前 [member ReverbTail] 秒启动下一个循环实例，
## 两个实例重叠播放，利用人耳的听觉残留效应实现平滑过渡。
##
## 使用方式：将此资源赋值给 [AudioStreamPlayer] 的 stream 属性即可。
## [SeamlessStreamManager] 会自动管理重叠播放逻辑。

## 要播放的音频文件
@export
var Song : AudioStream

## 重叠播放的持续时间（秒）。当前音频结束前这么多秒就开始播放下一个循环。
## 较大的值使过渡更平滑，但会"延长"总播放时间（因为两个实例同时出声的时间更长）。
@export
var ReverbTail : float = 1

## 用于多音流播放的内部播放器实例
var poly_stream : AudioStreamPolyphonic = AudioStreamPolyphonic.new()

## 实例化回放对象时被调用（AudioStream 系统的标准接口）
## 返回一个 AudioStreamPlaybackPolyphonic，并同时创建一个 SeamlessStreamManager
## 来管理无缝循环的重叠播放逻辑。
func _instantiate_playback() -> AudioStreamPlayback:
	var playback : AudioStreamPlaybackPolyphonic = poly_stream.instantiate_playback()
	var new_manager : SeamlessStreamManager = SeamlessStreamManager.new()
	# 添加到当前场景节点树中，使其能够接收 _process() 回调
	get_local_scene().add_child(new_manager, true, Node.INTERNAL_MODE_FRONT)
	new_manager.seamless_stream = weakref(self)
	new_manager.poly_man = weakref(playback)
	return playback

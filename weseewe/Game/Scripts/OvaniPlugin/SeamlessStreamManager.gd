@tool
class_name SeamlessStreamManager
extends Node
## [SeamlessStreamManager] — 无缝循环管理器
##
## 由 [SeamlessStream] 自动创建并管理，用于控制单个音频流的无缝循环播放。
##
## 工作原理：
## - 记录"有效播放时长" = 歌曲总长 - ReverbTail
## - 当当前播放时间超过有效时长时，立即启动一个新的音频实例
## - 保留最近的两个播放实例（正在出声的那个 + 即将停止的那个）
## - 停止最早的播放实例
## - 通过重叠播放实现听觉上的无缝衔接
##
## 注意：此节点由 SeamlessStream 自动创建和销毁（当引用无效时自动 queue_free），
## 不需要手动管理。

## 对所属 SeamlessStream 的弱引用（避免循环引用）
var seamless_stream : WeakRef
## 对 AudioStreamPlaybackPolyphonic 的弱引用
var poly_man : WeakRef

## 上一次记录的音频资源（用于检测是否切换了歌曲）
var last_song : AudioStream
## 上一次记录的 ReverbTail（用于检测是否更改了参数）
var last_RT : float
## 当前歌曲的有效播放时长（总长 - ReverbTail）
var cur_song_length : float

## 当前正在播放的所有音频实例 ID（最多保留2个）
var current_playbacks : Array[int] = []

## 当前已播放的时间（累计）
var curTime : float

func _process(delta: float) -> void:
	# 如果引用已失效，说明 SeamlessStream 已被销毁，清理自身
	if (poly_man == null) or (seamless_stream == null):
		queue_free()
		return

	var curStream : SeamlessStream = seamless_stream.get_ref()
	var curPoly : AudioStreamPlaybackPolyphonic = poly_man.get_ref()
	# 同上，检查引用是否仍然有效
	if (curStream == null) or (curPoly == null):
		queue_free()
		return

	# --- 检测配置变更：Song 或 ReverbTail 改变时，重置播放状态 ---
	if (last_song != curStream.Song) or (last_RT != curStream.ReverbTail):
		last_song = curStream.Song
		last_RT = curStream.ReverbTail

		# 停止所有旧的播放实例
		for cur_play in current_playbacks:
			curPoly.stop_stream(cur_play)
		current_playbacks = []

		# 重置计时器
		curTime = 0

		# 如果有新歌曲，立即开始播放
		if curStream.Song != null:
			current_playbacks = [curPoly.play_stream(curStream.Song)]
			# 有效播放时长 = 总长 - 重叠时长
			cur_song_length = curStream.Song.get_length() - last_RT

	# --- 无缝循环逻辑：到达重叠点时启动新实例 ---
	if (last_song != null):
		# 当已播放时间超过有效时长时，说明已到达 ReverbTail 重叠区域
		if (curTime > cur_song_length):
			# 启动新的循环实例（此时旧实例仍在播放，形成重叠）
			current_playbacks.append(curPoly.play_stream(curStream.Song))
			# 最多保留2个播放实例，超过则停止最早的
			if len(current_playbacks) > 2:
				curPoly.stop_stream(current_playbacks.pop_front())
			# 重置计时器，开始下一轮循环
			curTime = 0

	# 累加时间（支持 Engine.time_scale，即受到游戏暂停/倍速影响）
	curTime += delta * Engine.time_scale

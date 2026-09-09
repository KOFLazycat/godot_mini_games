@tool
@icon("res://Game/Scripts/OvaniPlugin/OvaniPlayerIcon.png")
class_name OvaniPlayer
## [OvaniPlayer] — 动态音乐播放器
##
## 强大的游戏音乐管理节点，基于无缝循环理念构建，支持：
## 1. **无缝循环**：利用"混音尾巴"（ReverbTail）实现无断点循环。
## 2. **强度混音**：在多个音乐层之间动态交叉淡入淡出（仅 Intensities 模式）。
## 3. **歌曲队列**：按顺序播放多首歌曲，支持队列循环。
## 4. **平滑过渡**：在歌曲切换、强度变化、音量变化时支持淡入淡出。
##
## 基本用法：
## 1. 将此节点添加到场景中。
## 2. 创建一个 [OvaniSong] 资源，配置音乐文件。
## 3. 调用 [method PlaySongNow] 开始播放，或通过 [member QueuedSongs] 配置队列。
##
## [br]
## **强度混音原理（Intensities 模式）：**
## 三层音乐同时播放，每层的音量由当前 Intensity 值计算：
## [code]音量 = max(0, 0.5 - |层索引/2 - Intensity| / 0.5)[/code]
## - Intensity = 0.0 → 只听到 Intensity1（全音量）
## - Intensity = 0.5 → 三层均衡混合
## - Intensity = 1.0 → 只听到 Intensity3（全音量）
## - 中间值时相邻两层平滑过渡。
extends Node


## 是否启用音乐播放
## true: 启用音乐播放（默认）
## false: 禁用音乐播放，不进行任何播放逻辑
@export var isEnabled : bool = true;

## 设为 true 可以在编辑器中实时预览播放效果。
## 注意：预览时会自动从队列中移除已播放完毕的歌曲。
@export var PlayInEditor : bool = false;

## 设为 true 时，当队列中所有歌曲播放完毕后，
## 当前歌曲会回到队列末尾重新播放（无限循环整个队列）。
@export var LoopQueue : bool

## 歌曲播放队列。队列中的歌曲按先进先出顺序播放。
## 可直接在编辑器中配置，也可通过 [method QueueSong] 动态添加。
## 第一个元素是当前正在播放的歌曲。
@export var QueuedSongs : Array[OvaniSong];

## 播放器的音量（分贝 dB），范围 -80 到 20。
## 设置此值会同步更新所有当前播放中的声音管理器的音量。
@export_range(-80, 20) var Volume : float = 0:
	get:
		return Volume;
	set(value):
		for psm in _soundManagers:
			psm.Volume = value;
		Volume = value;

## 当前强度值（0.0 ~ 1.0），仅在 [member OvaniSong.SongMode] = [code]Intensities[/code] 时有效。
## 控制三个强度层的混音权重。改变此值会同步更新所有播放实例。
## 可以直接赋值，也可以用 [method FadeIntensity] 在一段时间内平滑过渡。
@export_range(0, 1) var Intensity : float = 0:
	get:
		return Intensity;
	set(value):
		for psm in _soundManagers:
			psm.Intensity = value;
		Intensity = value;

## 音频输出的目标音频总线名称。
## 可以在运行时动态修改，Setter 会同步更新底层 AudioStreamPlayer。
@export var Bus : StringName = "Master":
	get:
		if _audioPlayer != null && !Engine.is_editor_hint():
			return _audioPlayer.bus;
		else:
			return Bus;
	set(value):
		Bus = value;
		if _audioPlayer != null:
			_audioPlayer.bus = value;

## 底层的 AudioStreamPlayer 引用。
## 仅在非编辑器模式下才使用其实时 bus 设置。
var _audioPlayer : AudioStreamPlayer:
	get:
		return _audioPlayer;
	set(value):
		value.bus = Bus;
		_audioPlayer = value


## 立即用指定歌曲替换当前播放的歌曲，同时开始过渡。
## - 如果队列为空，会先插入一个 null 占位。
## - 当前歌曲根据 transitionTime 开始淡出，新歌曲在原曲淡出时开始淡入。
## - transitionTime = -1（默认）时，使用当前歌曲的 ReverbTail 作为过渡时长。
func PlaySongNow(song : OvaniSong, transitionTime : float = -1) -> void:
	if (len(QueuedSongs) == 0):
		QueuedSongs.append(null)

	# 将新歌曲插入队列第二位（紧跟当前歌曲）
	QueuedSongs.insert(1, song);
	if (len(_soundManagers) != 0):
		if (transitionTime == -1):
			# 使用 ReverbTail 作为过渡时间点
			_soundManagers[0].StartTime = (_curTime - _soundManagers[0].SongLength) + _soundManagers[0].ReverbTail;
			_soundManagers[0].FadeOut = _soundManagers[0].ReverbTail
		else:
			# 使用指定的过渡时间
			_soundManagers[0].StartTime = (_curTime - _soundManagers[0].SongLength) + transitionTime;
			_soundManagers[0].FadeOut = transitionTime

## 立即停止播放所有歌曲。
## - 清空队列，只保留当前歌曲。
## - transition_time > 0 时，当前歌曲会淡出后停止。
func StopSongsNow(transition_time : int = 0) -> void:
	if (len(QueuedSongs) > 0):
		QueuedSongs = [QueuedSongs[0]]
		PlaySongNow(null, transition_time)

## 将一首歌曲添加到队列末尾。
func QueueSong(song : OvaniSong) -> void:
	QueuedSongs.append(song);

## 底层的"多音流回放"对象，用于 polyphonic（多声部）音频播放。
var _audioStreamPlayback : AudioStreamPlaybackPolyphonic;
## 当前所有活跃的 PolySoundManager 实例列表。
var _soundManagers : Array[PolySoundManager];

## 内部枚举，用于标记一首歌曲播放结束后的"后续状态"。
## 仅供 OvaniPlayer 内部逻辑使用。
enum NextState {
	None = 0,         ## 尚未处理后续
	StartedLoop = 1,  ## 循环当前歌曲（队列只有一首歌）
	StartedDifferent = 2  ## 切换到队列中的下一首歌
}

## PolySoundManager — 单首歌曲的播放控制器
## 每个实例管理一首歌曲的一个或多个音频层的播放。
## 一个 OvaniPlayer 可能有多个 PolySoundManager 同时存在（用于无缝过渡）。
class PolySoundManager:
	## 对应的多音流回放对象
	var MyStream : AudioStreamPlaybackPolyphonic;
	## 当前播放的所有音频层 ID 列表（Intensities 模式有3个，Loop 模式有1个）
	var Ids : Array[int];

	## 此播放器的音量（分贝），Setter 会根据 Intensity 更新各层实际音量。
	var Volume : float:
		get:
			return Volume;
		set(value):
			var realIntensity : float;
			# Intensities 模式有3个ID，Loop模式只有1个
			if (len(Ids) == 3):
				realIntensity = Intensity;
			else:
				realIntensity = 0;
			for i in range(len(Ids)):
				# 根据当前 Intensity 计算每一层的音量
				# 公式：音量 = 原始音量 × max(0, 0.5 - |层索引/2 - Intensity| / 0.5)
				MyStream.set_stream_volume(Ids[i], linear_to_db(db_to_linear(value) * max((.5 - abs((i as float)/2 - realIntensity))/.5, 0)));
			Volume = value;

	## 当前强度值，影响各层的混音权重
	var Intensity : float:
		get:
			return Intensity;
		set(value):
			Intensity = value;
			# 触发 Volume setter 重新计算各层音量
			Volume = Volume;

	## 当前实例的开始播放时间（全局时间线）
	var StartTime : float;
	## 当前歌曲的总长度（秒）
	var SongLength : float;
	## 重叠混音时长（秒）
	var ReverbTail : float;
	## 淡入时长（秒），-1 表示无需淡入
	var FadeIn : float = -1;
	## 淡出时长（秒），-1 表示无需淡出
	var FadeOut : float = -1;
	## 歌曲结束后的后续状态
	var StartedNextState : NextState = NextState.None;


## 创建并初始化一个 PolySoundManager 实例。
## 根据 OvaniSong.SongMode 决定播放哪些音频资源。
func _constructPolySoundManager(song : OvaniSong) -> PolySoundManager:
	var o : PolySoundManager = PolySoundManager.new();
	o.MyStream = _audioStreamPlayback;

	if (song != null):
		if (song.SongMode == OvaniSong.OvaniMode.Intensities):
			# 强度模式：同时播放3个音频层
			o.Ids.append(_audioStreamPlayback.play_stream(song.Intensity1));
			o.Ids.append(_audioStreamPlayback.play_stream(song.Intensity2));
			o.Ids.append(_audioStreamPlayback.play_stream(song.Intensity3));
			o.Intensity = Intensity;
			o.SongLength = song.Intensity1.get_length();
		elif (song.SongMode == OvaniSong.OvaniMode.Loop30):
			# 30秒循环模式
			o.Ids.append(_audioStreamPlayback.play_stream(song.Loop30));
			o.Intensity = 0;
			o.SongLength = song.Loop30.get_length();
		else:
			# 60秒循环模式
			o.Ids.append(_audioStreamPlayback.play_stream(song.Loop60));
			o.Intensity = 0;
			o.SongLength = song.Loop60.get_length();
		o.ReverbTail = song.ReverbTail;

	o.Volume = Volume;
	o.StartTime = _curTime;
	return o;


## 节点就绪时，初始化底层的 AudioStreamPlayer 和多音流回放系统。
func _ready() -> void:
	_audioPlayer = AudioStreamPlayer.new();
	_audioPlayer.stream = AudioStreamPolyphonic.new();
	add_child(_audioPlayer, INTERNAL_MODE_BACK);
	_audioPlayer.owner = null;
	_audioPlayer.play();
	_audioStreamPlayback = _audioPlayer.get_stream_playback();

## 强度渐变的起始值
var _startIntFadeVal : float = 0;
## 强度渐变的目标值
var _endIntFadeVal : float = 1;
## 强度渐变开始的时间戳
var _timeIntFadeStarted : float = 0;
## 强度渐变结束的时间戳
var _timeIntFadeEnded : float = 1;

## 在指定时间内平滑渐变到目标强度值。
## 期间每帧会根据 lerp 自动更新 [member Intensity]。
## 注意：如果在渐变进行中再次调用，会立即跳到新渐变的起点。
func FadeIntensity(intensity : float, transitionTime : float) -> void:
	_timeIntFadeStarted = _curTime
	_timeIntFadeEnded  = _curTime + transitionTime;
	_startIntFadeVal = Intensity;
	_endIntFadeVal = intensity;

## 音量渐变的起始值
var _startVolFadeVal : float = 0;
## 音量渐变的目标值
var _endVolFadeVal : float = 1;
## 音量渐变开始的时间戳
var _timeVolFadeStarted : float = 0;
## 音量渐变结束的时间戳
var _timeVolFadeEnded : float = 1;

## 在指定时间内平滑渐变到目标音量（分贝）。
## 期间每帧会根据 lerp 自动更新 [member Volume]。
func FadeVolume(volume : float, transitionTime : float) -> void:
	_timeVolFadeStarted = _curTime
	_timeVolFadeEnded  = _curTime + transitionTime;
	_startVolFadeVal = Volume;
	_endVolFadeVal = volume;

## 当前歌曲已播放的时间（秒），只读。
## 如果没有歌曲在播放，返回 0。
var CurrentSongTime : float:
	get:
		if (len(_soundManagers) > 0):
			return _curTime - _soundManagers[0].StartTime;
		else:
			return 0;

## 当前歌曲的总时长（秒），只读。
var CurrentSongLength : float:
	get:
		if (len(_soundManagers) > 0):
			return _soundManagers[0].SongLength;
		else:
			return 0;

## 全局时间线计数器（秒）
var _curTime : float = 500;

func _process(delta: float) -> void:
	# 如果未启用音乐播放，直接返回
	if not isEnabled:
		return

	# 编辑器预览模式：每首歌播放1秒后自动触发循环逻辑，防止卡住
	if (Engine.is_editor_hint() && !PlayInEditor):
		for psm in _soundManagers:
			if (psm.StartedNextState != NextState.StartedLoop):
				psm.StartTime = (_curTime - psm.SongLength) + 1;
				psm.FadeOut = 1;
				psm.StartedNextState = NextState.StartedLoop;

	# 累加时间（支持 Engine.time_scale，即受到游戏暂停/倍速影响）
	_curTime += delta / Engine.time_scale;

	# --- 强度渐变逻辑 ---
	if (_timeIntFadeStarted < _curTime && _timeIntFadeEnded > _curTime):
		Intensity = lerp(_startIntFadeVal, _endIntFadeVal, (_curTime - _timeIntFadeStarted)/(_timeIntFadeEnded - _timeIntFadeStarted))

	# --- 音量渐变逻辑 ---
	if (_timeVolFadeStarted < _curTime && _timeVolFadeEnded > _curTime):
		Volume = lerp(_startVolFadeVal, _endVolFadeVal, (_curTime - _timeVolFadeStarted)/(_timeVolFadeEnded - _timeVolFadeStarted))

	# --- 歌曲播放队列逻辑 ---
	if (len(QueuedSongs) > 0):
		# 如果当前没有活跃的播放实例，立即创建（开始播放队列第一首歌）
		if (len(_soundManagers) == 0 && (!Engine.is_editor_hint() || PlayInEditor)):
			_soundManagers.append(_constructPolySoundManager(QueuedSongs[0]));

		for psm in _soundManagers:
			# 已播放时长 = 当前时间 - 开始播放时间
			var timePlayed : float = _curTime - psm.StartTime;

			# --- 淡入处理 ---
			if (psm.FadeIn != -1 && timePlayed < psm.FadeIn):
				# 从0线性淡入到当前音量
				psm.Volume = linear_to_db((timePlayed / psm.FadeIn) * db_to_linear(Volume));

			# --- 淡出处理 ---
			# remainingTime = 歌曲结束前的剩余时间（负数表示已结束）
			var remainingTime : float = -(_curTime - (psm.StartTime + psm.SongLength));
			if (psm.FadeOut != -1 && remainingTime < psm.FadeOut):
				# 从当前音量线性淡出到0
				psm.Volume = linear_to_db((remainingTime / psm.FadeOut) * db_to_linear(Volume));

			# --- 触发下一首歌曲（无缝衔接） ---
			if (remainingTime < psm.ReverbTail || remainingTime < psm.FadeOut):
				if (psm.StartedNextState == NextState.None):

					if (!Engine.is_editor_hint() || PlayInEditor):
						var nextSong : OvaniSong;
						if (len(QueuedSongs) == 1):
							# 队列只有一首歌 → 循环当前歌曲
							nextSong = QueuedSongs[0];
							psm.StartedNextState = NextState.StartedLoop;
						else:
							# 队列有多首歌 → 切换到下一首
							nextSong = QueuedSongs[1];
							psm.StartedNextState = NextState.StartedDifferent;

						# 创建新的 PolySoundManager（开始播放下一首）
						var newPSM : PolySoundManager = _constructPolySoundManager(nextSong)
						_soundManagers.append(newPSM);

						# 如果旧歌曲正在淡出，新歌曲的淡入时间 = 旧歌曲的淡出时间（无缝衔接）
						if remainingTime < psm.FadeOut:
							newPSM.FadeIn = psm.FadeOut;

				# --- 移除已完全结束的播放实例 ---
				if (remainingTime < 0):
					_soundManagers.erase(psm);
					for id in psm.Ids:
						psm.MyStream.stop_stream(id);

					# 如果是切换到不同歌曲，从队列中弹出已完成的那首
					if (psm.StartedNextState == NextState.StartedDifferent):
						var leavingSong : OvaniSong = QueuedSongs.pop_front()
						if LoopQueue:
							QueuedSongs.append(leavingSong);
						notify_property_list_changed();

		return;

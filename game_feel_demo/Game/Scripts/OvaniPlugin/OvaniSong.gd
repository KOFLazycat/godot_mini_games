@tool
@icon("res://Game/Scripts/OvaniPlugin/OvaniSongIcon.png")
class_name OvaniSong
## [OvaniSong] — 动态音乐资源定义
##
## 用于定义一首"动态音乐"的全部配置，作为 [OvaniPlayer] 的输入数据。
## [br]
## 它支持两种音乐模式：
## 1. **强度模式（Intensities）**：同时播放3个不同强度的音乐层，
##    通过 [OvaniPlayer.Intensity] 参数在运行时动态混音，适合战斗等需要渐变的场景。
## 2. **循环模式（Loop30/Loop60）**：播放单一循环片段，
##    适合不需要强度变化的背景音乐。
##
## 使用方式：在 Godot 编辑器中右键 → 新建 Resource → 选择 [code]OvaniSong[/code]，
## 然后在检视面板中配置音频文件和参数。
extends Resource

@export_category("Sound Files")
## 【强度模式专用】低强度音乐文件（如平静、舒缓的背景音乐）。
## 当 OvaniPlayer.Intensity = 0 时此层达到全音量，Intensity 增大时音量逐渐降低。
@export var Intensity1 : AudioStream
## 【强度模式专用】中等强度音乐文件（如稍带紧张感但不激烈的氛围）。
## 当 OvaniPlayer.Intensity ≈ 0.5 时此层达到全音量。
@export var Intensity2 : AudioStream
## 【强度模式专用】高强度音乐文件（如战斗、紧急、高潮部分）。
## 当 OvaniPlayer.Intensity = 1 时此层达到全音量，Intensity 降低时音量逐渐降低。
@export var Intensity3 : AudioStream

## 【循环模式专用】30秒循环片段。
## 当 [member SongMode] = [code]Loop30[/code] 时使用此字段。
## 适用于需要快速切换或内存敏感的场景。
@export var Loop30 : AudioStream
## 【循环模式专用】60秒循环片段。
## 当 [member SongMode] = [code]Loop60[/code] 时使用此字段。
## 适用于常规长度的背景循环音乐。
@export var Loop60 : AudioStream

## 【重要】重叠混音时长（秒）。
## 在当前循环结束前多少秒开始播放下一个循环实例，从而实现无缝衔接。
## 值越大过渡越平滑，但会造成两个循环同时出声的时间变长。
## OvaniPlayer 在歌曲切换时也会参考此值作为默认过渡时长。
@export var ReverbTail : float


@export_category("Default Settings")
## 定义 OvaniSong 的播放模式，决定使用哪些音频字段。
enum OvaniMode {
	## 强度混音模式：同时播放 [member Intensity1]、[member Intensity2]、[member Intensity3]。
	## 三层通过 OvaniPlayer.Intensity 参数动态混音，可实现强度的平滑过渡。
	Intensities = 0,
	## 30秒循环模式：仅播放 [member Loop30]。
	## 适合短片段或内存受限场景。
	Loop30 = 1,
	## 60秒循环模式：仅播放 [member Loop60]。
	## 适合中等长度的背景音乐。
	Loop60 = 2
}

## 选择该歌曲使用的播放模式。默认为强度混音模式。
@export var SongMode : OvaniMode = OvaniMode.Intensities;

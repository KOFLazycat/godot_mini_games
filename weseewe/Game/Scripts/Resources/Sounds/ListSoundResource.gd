## ListSoundResource — 音效列表资源
##
## 继承自 SoundResource，支持从一组音频文件中选一个播放。
## [br]
## random_order = false：按顺序循环遍历（Round-robin），
## 确保每个音效变体都会被均匀使用。
## random_order = true：每次随机挑选一个音频。
## [br]
## 与 NestedSoundResource 的区别：
## 此资源只管理 AudioStream 音频文件，所有变体共用一套音量/音高参数。
## 而 NestedSoundResource 的每个子资源有各自独立的音量/音高等参数。
extends SoundResource
class_name ListSoundResource

## 音效文件列表
@export var sound_list:Array[AudioStream]
## true = 随机选择；false = 顺序循环遍历
@export var random_order:bool

## 当前顺序播放的索引
var index:int = 0

## 重写 get_sound()，根据 random_order 决定从列表中选哪个音频
func get_sound()->AudioStream:
	if random_order:
		return sound_list[randi() % sound_list.size()]
	else:
		# 顺序遍历，超出末尾时回绕到开头
		index = (index +1) % sound_list.size()
		return sound_list[index]

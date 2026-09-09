## NestedSoundResource — 嵌套音效资源
##
## 继承自 SoundResource，支持从一组 SoundResource 子对象中选一个播放。
## [br]
## 与 ListSoundResource 的区别：
## ListSoundResource 只管理 AudioStream 文件，所有变体共用一套音量/音高参数。
## 此资源管理的是完整的 SoundResource 对象，每个子资源有各自的：
##  - 音频文件
##  - 音量
##  - 音高范围
##  - 连击音高变化参数
## [br]
## 适用于场景：同一类动作有多种"风格"的音效，
## 每种风格有自己独立的随机音高和音量设置。
extends SoundResource
class_name NestedSoundResource

## SoundResource 子对象列表，每个子对象可有独立的音频和音效参数
@export var sound_resource_list:Array[SoundResource]
## true = 随机选择；false = 顺序循环遍历
@export var random_order:bool

## 当前顺序播放的索引
var index:int = 0

## 重写 play()，从列表中选一个子 SoundResource 并触发播放。
## 注意：直接调用子资源的 play() 而非自己的，因此每个子资源
## 使用自己的音高/音量参数。
func play(_sound_player:SoundPlayer)->void:
	if random_order:
		sound_resource_list.pick_random().play(_sound_player)
	else:
		index = (index +1) % sound_resource_list.size()
		sound_resource_list[index].play(_sound_player)

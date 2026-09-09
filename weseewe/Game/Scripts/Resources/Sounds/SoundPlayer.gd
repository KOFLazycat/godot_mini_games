## SoundPlayer — 音效播放器节点
##
## 继承自 AudioStreamPlayer，专门用于播放 SoundResource。
## 提供了两种播放方式：
## - play_sound()：直接用自己作为播放器，适用于 SoundPlayer 节点持有一个 SoundResource 的场景。
## - play_managed_sound()：通过 SoundManager 单例的对象池播放，
##   适用于场景切换时需要音效继续播放完成的场景。
## [br]
## 使用方式：
## 1. 在场景中添加 SoundPlayer 节点。
## 2. 赋值 sound_resource。
## 3. 调用 play_sound() 或 play_managed_sound()。
class_name SoundPlayer
extends AudioStreamPlayer

## 此播放器关联的 SoundResource
@export var sound_resource:SoundResource

## 直接播放 sound_resource，使用当前节点作为 AudioStreamPlayer。
## 适用于 SoundPlayer 节点在场景中存在且不会被提前销毁的情况。
func play_sound()->void:
	if sound_resource == null:
		print(owner.name, ": ", name, " doesn't have a sound")
		return
	sound_resource.play(self)

## 通过 SoundManager 单例托管播放。
## SoundManager 会从对象池中取一个 SoundPlayer 来实际播放。
## 适用于：当前节点可能在音效播放过程中被销毁（如场景切换），
## 但希望音效能完整播放完成的场景。
func play_managed_sound()->void:
	if sound_resource == null:
		print(owner.name, ": ", name, " doesn't have a sound")
		return
	sound_resource.play_managed()

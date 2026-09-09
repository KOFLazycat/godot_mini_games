## SoundEmitterNode — 音效触发器节点
##
## 轻量级 Node，用于在场景中触发音效播放。
## 通过 play_managed() 走 SoundManager 单例的托管播放。
## [br]
## 优势：可以在编辑器中直接拖拽 SoundResource 到检视面板，
## 也支持通过代码动态赋值。可通过 enabled 属性动态控制是否允许播放。
## [br]
## 使用方式：
## 1. 在场景中添加 SoundEmitterNode 节点。
## 2. 在检视面板中将 SoundResource 资源赋值给 sound 属性。
## 3. 调用 play() 即可触发音效。
class_name SoundEmitterNode
extends Node

## 要播放的 SoundResource 资源
@export var sound:SoundResource
## 是否允许播放。可在运行时动态修改以启用/禁用音效触发。
@export var enabled:bool = true
## 调试模式标志（当前未实现具体逻辑，可扩展）
@export var debug:bool = false

## 设置启用状态
func set_enabled(value:bool)->void:
	enabled = value

## 触发音效播放。
## 会检查 sound 是否为空以及 enabled 状态，
## 通过 SoundManager 单例进行托管播放。
func play()->void:
	if sound == null:
		return
	if !enabled:
		return
	if debug:
		pass
	sound.play_managed()

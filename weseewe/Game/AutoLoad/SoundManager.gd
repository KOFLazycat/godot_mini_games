## SoundManager — 音效管理单例（自动加载）
##
## 全局音效管理器，核心功能是维护 SoundPlayer **对象池**。
## [br]
## 为什么需要对象池？
## 如果音效由场景中的 SoundPlayer 节点播放，一旦场景切换/销毁，
## SoundPlayer 节点也会随之销毁，正在播放的音效会戛然而止。
## SoundManager 作为自动加载的单例，其节点树不随场景切换而销毁，
## 因此由它持有的 SoundPlayer 可以持续播放到音效结束。
## [br]
## 工作流程：
## 1. _ready() 时预先创建 N 个 SoundPlayer 到池中。
## 2. play() 被调用时从池中取出一个 SoundPlayer，播放音效。
## 3. 音效播放完毕后（finished 信号），自动将 SoundPlayer 归还池中。
extends Node

## _ready() 时预创建的 SoundPlayer 数量
@export var start_count:int = 10

## 音效输出的音频总线名称（留空则走 Master）
@export var audio_bus:StringName


## SoundPlayer 对象池
var player_list:Array[SoundPlayer]

## 当前正在播放的声音资源数组
var playingSounds: Array[SoundResource] = []

## 创建一个新的 SoundPlayer，加入池中
func create_player()->void:
	var new_player:SoundPlayer = SoundPlayer.new()
	new_player.bus = audio_bus
	add_child(new_player)
	player_list.append(new_player)

func _ready()->void:
	if audio_bus.is_empty():
		printerr("SoundManager [INFO]: Audio buss name is empty. Will play through Master.")
	# 预创建对象池
	for i in start_count:
		create_player()

## 从池中获取一个 SoundPlayer。如果池为空则先创建一个。
func get_player()->SoundPlayer:
	if player_list.is_empty():
		create_player()
	return player_list.pop_back()

## 播放指定的 SoundResource。
## 优先使用资源之前关联的 SoundPlayer（如果仍有效），
## 否则从池中取一个新的 SoundPlayer 播放。
## 播放完成后通过 CONNECT_ONE_SHOT 信号自动归还池中。
func play(sound:SoundResource)->void:
	if sound.sound_player != null:
		# 资源已有绑定的播放器，直接复用
		sound.play(sound.sound_player)
		_addToPlayingSounds(sound)
		return
	var player:SoundPlayer = get_player()
	# 播放完毕后自动归还到池中（一次性连接）
	player.finished.connect(return_player.bind(player, sound), CONNECT_ONE_SHOT)
	sound.play(player)
	_addToPlayingSounds(sound)

## 将 SoundPlayer 归还到池中。
## 由 finished 信号触发（CONNECT_ONE_SHOT），无需手动调用。
func return_player(player:SoundPlayer, sound:SoundResource)->void:
	sound.sound_player = null
	player_list.append(player)
	_removeFromPlayingSounds(sound)


## 停止指定声音的播放
## @param sound - 要停止的声音资源
func stop(sound: SoundResource) -> void:
	if sound == null:
		return
	sound.stop()
	_removeFromPlayingSounds(sound)


## 停止所有正在播放的声音
func stopAll() -> void:
	for sound in playingSounds:
		sound.stop()
	playingSounds.clear()


## 添加声音到播放追踪
func _addToPlayingSounds(sound: SoundResource) -> void:
	if not playingSounds.has(sound):
		playingSounds.append(sound)


## 从播放追踪中移除声音
func _removeFromPlayingSounds(sound: SoundResource) -> void:
	var index: int = playingSounds.find(sound)
	if index >= 0:
		playingSounds.remove_at(index)

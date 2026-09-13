##=================================================================================================
## char_move.gd - 角色移动与攻击控制器
##
## 本脚本是 all_projectiles 演示中的角色控制器
## 功能：
## 1. 角色状态机管理（空闲、行走、跳跃、攻击等）
## 2. 移动控制（A/D键）
## 3. 跳跃物理（带重力和落地检测）
## 4. 攻击系统集成（与 ProjectileManager2D 结合）
## 5. 动画状态管理
## 6. 武器切换
##
## 这个脚本展示了如何在游戏中控制一个可以使用投射物攻击的角色
##=================================================================================================

class_name CharacterTest
extends CharacterBody2D


##=================================================================================================
## 允许动作枚举
##
## 定义在攻击过程中允许执行的额外动作
## 用于控制攻击时是否可以移动、跳跃等
##=================================================================================================
enum AllowActions{
	MOVE,
	JUMP,
	JUMP_CANCEL,
	ROTATE,
	LOOK_MOUSE
}

##=================================================================================================
## 角色状态枚举
##
## 角色的所有可能状态
## 用于状态机管理
##=================================================================================================
enum States{
	IDLE,
	WALK,
	JUMP_ANTICIPATE,
	JUMP,
	FALL,
	LANDING_RECOVERY,
	ATTACK_CHARGE,
	ATTACK_ANTICIPATE,
	ATTACK,
	ATTACK_RECOVERY
}


##=================================================================================================
## 导出变量 - 主属性
##=================================================================================================
@export_group("Main Attributes")
@export var on_walk_move_speed: float = 300.0          ## 行走时的移动速度
@export var on_jump_move_speed: float = 400.0          ## 跳跃时的移动速度
@export var on_attack_move_speed: float = 90.0          ## 攻击时的移动速度
@export var on_jump_and_attack_move_speed: float = 90.0 ## 跳跃+攻击时的移动速度

@export var jump_velocity: float = -400.0              ## 跳跃初速度（负值向上）
@export var gravity_amplification: float = 1.0         ## 重力倍率
@export var will_look_at_mouse: bool = false           ## 是否朝向鼠标
@export var audio_scene: PackedScene                    ## 音效场景

##=================================================================================================
## 导出变量 - 碰撞偏移
##=================================================================================================
@export_group("Collsion Offsets")
@export var coll_move_offset: Vector2                  ## 移动时碰撞盒的偏移量

##=================================================================================================
## 导出变量 - 攻击转换要求
##=================================================================================================
@export_group("Attack2D Requirements")
## 可以立即跳过直接进入攻击状态的动作位掩码
@export_flags_2d_physics var on_change_transition_actions: int
## 可以无缝过渡到攻击状态的动作位掩码
@export_flags_2d_physics var on_update_transition_actions: int

##=================================================================================================
## 导出变量 - 武器
##=================================================================================================
@export_group("Weapons")
@export var start_attack: int                          ## 初始武器ID

##=================================================================================================
## 导出变量 - 跳跃延迟
##=================================================================================================
@export_group("Jump Delays")
@export var jump_anticipation_duration: float          ## 跳跃预兆持续时间
@export var landind_recovery_duration: float           ## 落地恢复持续时间


##=================================================================================================
## @onready 变量 - 节点引用
##=================================================================================================
@onready var projectile_manager: ProjectileManager2D = $ProjectileManager2D  ## 投射物管理器
@onready var animator: AnimationPlayer = $AnimationPlayer                    ## 动画播放器
@onready var sprite: Sprite2D = $Sprite2D                                    ## 精灵图
@onready var basic_timer: Timer = $BasicTimer                                ## 基础计时器（用于状态延迟）

@onready var collision: CollisionShape2D = $Collision                        ## 碰撞形状
@onready var base_coll_pos: Vector2 = collision.position                     ## 碰撞盒基础位置

@onready var direction: int = 0                                               ## 当前输入方向（-1, 0, 1）
@onready var facing_direction: int = 1                                       ## 角色朝向（1=右, -1=左）


##=================================================================================================
## 运行时变量
##=================================================================================================
var selected_attack: Attack2D                          ## 当前选中的攻击实例
var selected_projectile_id: int                        ## 当前选中的投射物ID
var hover_projectile_id: int                           ## 鼠标悬停的投射物ID（用于切换武器）

var attack_loop_allow_actions: int                     ## 攻击循环中允许的动作
var charge_delta: float                                ## 蓄力进度


var current_state: States = States.IDLE                ## 当前状态
var previous_state: States = States.IDLE               ## 上一状态

var next_state: States = States.IDLE                  ## 下一状态（计时器到期后切换）
var next_animation_speed: float                        ## 下一动画速度
var next_can_skip_states: bool                         ## 是否可以跳过状态



##=================================================================================================
## _ready() - 初始化方法
##
## 设置计时器回调，初始化攻击和投射物
##=================================================================================================
func _ready() -> void:
	## 连接计时器超时信号到状态变更函数
	basic_timer.timeout.connect(func() -> void: change_state(next_state, next_animation_speed, next_can_skip_states))

	## 从投射物管理器获取初始攻击
	selected_attack = projectile_manager.get_attack(start_attack)
	selected_projectile_id = start_attack
	hover_projectile_id = start_attack




##=================================================================================================
## cycle_weapons() - 武器切换方法
##
## 在可用武器之间循环切换
## 参数: ammount - 切换数量（正数向前，负数向后）
## 返回: 武器名称（StringName）
##=================================================================================================
func cycle_weapons(ammount: int) -> StringName:
	## 注释掉的代码：原本用于阻止在攻击时切换武器
	# if (current_state in [States.ATTACK_CHARGE, States.ATTACK_ANTICIPATE, States.ATTACK]):
	# 	return false

	## 计算新的武器索引（循环）
	if (hover_projectile_id + ammount) >= projectile_manager.attacks.size():
		hover_projectile_id = 0
	elif (hover_projectile_id + ammount) < 0:
		hover_projectile_id = projectile_manager.attacks.size() - 1
	else:
		hover_projectile_id += ammount

	## 返回武器名称（资源文件名转大写）
	return projectile_manager.attacks[hover_projectile_id].resource.resource_path.get_file().trim_suffix(".tres").to_upper()




##=================================================================================================
## change_state() - 状态变更方法
##
## 角色状态机的核心方法
## 处理状态切换、动画播放、攻击触发等
## 参数:
##   _state: 目标状态
##   current_animation_speed: 动画播放速度
##   can_skip_stages: 是否可以跳过阶段
##   _next_animation_speed: 下一动画速度
##=================================================================================================
func change_state(_state: States, current_animation_speed: float = 1.0, can_skip_stages: bool = true, _next_animation_speed: float = 1.0) -> void:
	previous_state = current_state
	current_state = _state

	## 如果按下鼠标左键且允许跳过阶段，检查是否可以立即进入攻击状态
	if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) && can_skip_stages):
		## 检查当前状态是否在可转换列表中
		if (on_change_transition_actions & (1 << current_state)):
			## 调整碰撞盒位置
			position = collision.global_position - base_coll_pos
			collision.position = base_coll_pos
			## 切换到攻击状态
			change_state(States.ATTACK, 1.0, can_skip_stages)
			return

	## 根据状态执行对应逻辑
	match current_state:
		## IDLE - 空闲状态
		States.IDLE:
			collision.position = base_coll_pos

		## JUMP_ANTICIPATE - 跳跃预兆
		States.JUMP_ANTICIPATE:
			## 设置定时状态变更（预兆结束后跳转跳跃）
			set_timed_state_change(States.JUMP, jump_anticipation_duration, "jump_anticipate", current_animation_speed, can_skip_stages)

		## JUMP - 跳跃状态
		States.JUMP:
			velocity.y = jump_velocity  ## 设置向上初速度
			animator.play("jump", -1, current_animation_speed)
			animator.advance(0)  ## 立即推进到动画第一帧

		## FALL - 下落状态
		States.FALL:
			animator.play("fall", -1, current_animation_speed)
			animator.advance(0)

		## LANDING_RECOVERY - 落地恢复
		States.LANDING_RECOVERY:
			velocity = Vector2.ZERO  ## 停止水平移动
			## 调整位置和碰撞盒
			position += collision.position - base_coll_pos
			collision.position = base_coll_pos
			## 设置定时状态变更（恢复结束后跳转空闲）
			set_timed_state_change(States.IDLE, landind_recovery_duration, "landing_recovery", current_animation_speed, can_skip_stages)

		## ATTACK - 攻击状态
		States.ATTACK:
			spawn_projectile()  ## 生成投射物




##=================================================================================================
## create_audio_player() - 音效播放器创建方法
##
## 创建带延迟播放的音效
## 参数:
##   audio_stream: 音频流
##   audio_headstart: 延迟时间（秒）
##   audio_db: 音量
##=================================================================================================
func create_audio_player(audio_stream: AudioStream, audio_headstart: float, audio_db: float) -> void:
	## 实例化音效场景
	var buffer: TimedAudio = audio_scene.instantiate()
	add_child(buffer)
	## 设置延迟播放
	buffer.timed_free(audio_stream, audio_headstart, audio_db)




##=================================================================================================
## spawn_projectile() - 投射物生成方法
##
## 请求投射物管理器生成投射物
## 投射物从角色位置射向鼠标位置
##=================================================================================================
func spawn_projectile() -> void:
	## 计算投射物发射位置（角色位置 + 攻击偏移 * 朝向）
	var _position: Vector2 = position + Vector2(selected_attack.attack_offset.x * facing_direction, selected_attack.attack_offset.y)
	## 目标位置为鼠标位置
	var destination: Vector2 = get_global_mouse_position()

	## 请求投射物管理器执行投射物
	## 参数: 投射物ID, 攻击ID, 起始位置, 目标位置
	projectile_manager.request_execution(selected_projectile_id, selected_projectile_id, _position, destination)




##=================================================================================================
## set_timed_state_change() - 定时状态变更方法
##
## 设置计时器，在指定时间后切换状态
## 参数:
##   _next_state: 下一状态
##   time_delay: 延迟时间
##   animation_name: 动画名称
##   current_animation_speed: 当前动画速度
##   can_skip: 是否可以跳过
##   _next_animation_speed: 下一动画速度
##=================================================================================================
func set_timed_state_change(_next_state: States, time_delay: float, animation_name: String, current_animation_speed: float, can_skip: bool, _next_animation_speed: float = 1.0) -> void:
	next_state = _next_state
	next_animation_speed = _next_animation_speed
	next_can_skip_states = can_skip

	## 启动计时器
	basic_timer.start(time_delay * current_animation_speed)
	## 播放动画
	animator.play(animation_name, -1, current_animation_speed)
	animator.advance(0)




##=================================================================================================
## _process() - 每帧处理方法
##
## 处理输入检测和状态机输入逻辑
## 不涉及物理计算
##=================================================================================================
func _process(_delta: float) -> void:
	## 重置方向
	direction = 0
	## 检测A/D键输入
	if Input.is_key_pressed(KEY_A):
		direction -= 1
	if Input.is_key_pressed(KEY_D):
		direction += 1

	## 根据当前状态处理输入
	match current_state:
		## 空闲或行走状态下，按下跳跃键且不在空中
		States.IDLE, States.WALK when Input.is_action_just_pressed("ui_accept") && !is_on_air():
			velocity = Vector2.ZERO
			change_state(States.JUMP_ANTICIPATE)

		## 空闲状态下有移动输入
		States.IDLE when direction != 0:
			change_state(States.WALK)

		## 行走状态下没有移动输入
		States.WALK when direction == 0:
			change_state(States.IDLE)

		## 落地恢复状态下，按跳跃键且计时器剩余时间少于60%
		States.LANDING_RECOVERY when Input.is_action_just_pressed("ui_accept") && basic_timer.time_left <= (landind_recovery_duration * 0.6):
			basic_timer.stop()
			change_state(States.JUMP_ANTICIPATE, 0.35)

		## 攻击状态下，按住鼠标左键持续发射
		States.ATTACK:
			if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
				spawn_projectile()

		## 其他状态（no_match），按下鼠标左键则进入攻击
		var no_match when Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			## 如果选中的武器与悬停武器不同，更新选中武器
			if (selected_projectile_id != hover_projectile_id):
				selected_projectile_id = hover_projectile_id
				selected_attack = projectile_manager.get_attack(hover_projectile_id)

			## 检查当前状态是否在可更新转换列表中
			if (on_update_transition_actions & (1 << no_match)):
				## 调整碰撞盒位置
				position = collision.global_position - base_coll_pos
				collision.position = base_coll_pos
				## 切换到攻击状态
				change_state(States.ATTACK, 1.0, false)




##=================================================================================================
## _physics_process() - 物理处理方法
##
## 处理物理运动：重力、速度、碰撞等
##=================================================================================================
func _physics_process(_delta: float) -> void:
	## 如果在空中，应用重力
	if is_on_air():
		velocity += get_gravity() * _delta * gravity_amplification

	## 根据状态处理物理
	match current_state:
		## IDLE - 空闲状态
		States.IDLE:
			flip_sprite_if_mouse(will_look_at_mouse)  ## 根据设置决定是否朝向鼠标
			## 水平速度逐渐减到0
			velocity.x = move_toward(velocity.x, 0, on_walk_move_speed)
			animator.play("idle")

		## WALK - 行走状态
		States.WALK:
			flip_sprite_if_needed(direction)  ## 根据输入翻转精灵
			velocity.x = direction * on_walk_move_speed  ## 设置移动速度
			## 碰撞盒偏移
			collision.position = base_coll_pos + (coll_move_offset * direction)
			animator.play("walk")

		## JUMP - 跳跃状态
		States.JUMP:
			flip_sprite_if_needed(direction)
			velocity.x = direction * on_jump_move_speed
			## 如果开始下落，切换到下落状态
			if (velocity.y > 0):
				change_state(States.FALL)

		## FALL - 下落状态
		States.FALL:
			flip_sprite_if_needed(direction)
			velocity.x = direction * on_jump_move_speed
			## 如果落地，切换到落地恢复状态
			if (!is_on_air()):
				change_state(States.LANDING_RECOVERY)

		## ATTACK - 攻击状态
		States.ATTACK:
			velocity.x = 0  ## 停止水平移动

			## 检查是否允许移动
			if (attack_loop_allow_actions & (1 << AllowActions.MOVE)):
				velocity.x = direction * on_attack_move_speed

			## 检查是否允许跳跃取消
			if (attack_loop_allow_actions & (1 << AllowActions.JUMP_CANCEL)):
				if (Input.is_action_pressed("ui_accept") && !is_on_air()):
					basic_timer.stop()
					change_state(States.JUMP)
					move_and_slide()
					return  ## 提前返回，不执行后续代码

			## 检查是否允许跳跃
			if (attack_loop_allow_actions & (1 << AllowActions.JUMP)):
				if (is_on_air() && velocity.x != 0):
					velocity.x = direction * on_jump_and_attack_move_speed
				if (Input.is_action_pressed("ui_accept") && !is_on_air()):
					velocity.y = jump_velocity

			## 检查是否允许旋转
			if (attack_loop_allow_actions & (1 << AllowActions.ROTATE)):
				flip_sprite_if_needed(direction)

			## 检查是否允许朝向鼠标
			if (attack_loop_allow_actions & (1 << AllowActions.LOOK_MOUSE)):
				flip_sprite_if_mouse(true)

	## 执行移动和碰撞
	move_and_slide()




##=================================================================================================
## flip_sprite_if_mouse() - 鼠标朝向方法
##
## 根据鼠标位置决定角色朝向
## 参数: can_look_at_moves - 是否启用鼠标朝向
##=================================================================================================
func flip_sprite_if_mouse(can_look_at_moves: bool) -> void:
	if (can_look_at_moves):
		## 鼠标在角色右侧则朝右，否则朝左
		if (get_global_mouse_position().x >= position.x):
			flip_sprite_if_needed(1)
		else:
			flip_sprite_if_needed(-1)




##=================================================================================================
## flip_sprite_if_needed() - 方向翻转方法
##
## 根据输入方向翻转精灵图
## 参数: _direction - 输入方向（-1, 0, 1）
##=================================================================================================
func flip_sprite_if_needed(_direction: int) -> void:
	if (_direction > 0):
		sprite.flip_h = false
		facing_direction = 1
	elif (_direction < 0):
		sprite.flip_h = true
		facing_direction = -1




##=================================================================================================
## is_on_air() - 空中检测方法
##
## 检测角色是否在空中
## 包含特殊逻辑用于处理跳跃/下落状态
## 返回: true = 在空中, false = 在地面
##=================================================================================================
func is_on_air() -> bool:
	## 首先检查是否在地面
	if (is_on_floor()):
		return false

	## 处理y坐标的边界情况
	if (position.y >= 0):
		## 如果在跳跃或下落状态
		if (current_state in [States.JUMP, States.FALL]):
			## 检查是否已经落地（y坐标条件）
			if (position.y >= (collision.position.y + 40) * -1):
				return false
			return true
		## 归零垂直速度
		velocity.y = 0
		position.y = 0
		return false

	## 其他情况认为在空中
	return true


##=================================================================================================
## 注释结束 - char_move.gd
##
## 本脚本展示了：
## 1. 完整的状态机实现
## 2. 与 all_projectiles 插件的集成
## 3. 角色移动和跳跃物理
## 4. 动画状态管理
## 5. 武器切换系统
##
## 可以作为塔、敌人、玩家角色控制器的参考
##=================================================================================================

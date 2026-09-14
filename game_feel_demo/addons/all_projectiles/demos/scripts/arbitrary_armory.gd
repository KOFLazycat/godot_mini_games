##=================================================================================================
## arbitrary_armory.gd - 投射物军械库自定义脚本
##
## 本脚本展示了 all_projectiles 插件的高级用法：
## 1. 自定义投射物的生命周期回调（发射、移动、碰撞、过期）
## 2. 自定义攻击的生命周期回调（蓄力、预兆、主攻击、恢复、完成）
## 3. 使用修正器（Modifier）修改投射物和攻击的属性
## 4. 实现各种特殊投射物效果（激光、正弦波、追踪、火焰等）
##
## 这是一个很好的参考，用于理解如何为塔、敌人、卡牌等创建自定义投射物效果
##=================================================================================================

extends Node2D


##=================================================================================================
## 导出变量 - 用于Mega Laser效果的视觉组件
##=================================================================================================
@export_group("Mega Laser Enviroment")
@export var curtain: ColorRect                    # 激光蓄力时的幕布遮罩
@export var curtain_node: Node2D                  # 幕布节点
@export var curtain_color: Color                  # 幕布颜色
@export var spark: CPUParticles2D                 # 激光蓄力时的火花粒子


##=================================================================================================
## 私有变量
##=================================================================================================
var laser_tween: Tween                            # 用于激光蓄力动画的Tween实例
@onready var projectile_manager: ProjectileManager2D = $ProjectileManager2D  # 投射物管理器引用


##=================================================================================================
## _ready() - 初始化方法
##
## 设置所有投射物和攻击的自定义回调函数
## 这是整个脚本的核心入口点
##=================================================================================================
func _ready() -> void:
	##------------------------------------------
	## 设置投射物回调 - 针对所有已存在的投射物
	## set_on_start: 投射物发射时调用
	## set_on_move: 投射物每帧移动时调用
	## set_on_expired: 投射物过期/销毁时调用
	## set_on_collision: 投射物碰撞时调用
	##------------------------------------------
	for proj: Projectile2D in projectile_manager.projectiles:
		## 为所有投射物设置粒子拖尾效果
		proj.set_on_start(start_custom_particle_trail).set_on_move(update_custom_particle_trail).set_on_expired(expired_custom_particle_trail)

	## 为特定投射物设置特殊行为
	projectile_manager.get_projectile(FrogCharacter.Spells.SOUL_SEEKER).set_on_move(custom_seekeing)           # 灵魂追踪箭 - 追踪效果
	projectile_manager.get_projectile(FrogCharacter.Spells.HEAVY_SOUL_SEEKER).set_on_move(custom_seekeing)   # 重型灵魂追踪箭
	projectile_manager.get_projectile(FrogCharacter.Spells.THE_PURSUER).set_on_move(custom_pursuer)          # 追踪者 - 追踪+持续伤害
	projectile_manager.get_projectile(FrogCharacter.Spells.EVEN_GLARE).set_on_move(update_custom_glare)      # 目光凝视 - 尺寸/速度变化
	projectile_manager.get_projectile(FrogCharacter.Spells.FIREBALL).set_on_expired(expired_custom_fireball) # 火球 - 爆炸效果
	projectile_manager.get_projectile(FrogCharacter.Spells.GREAT_FIREBALL).set_on_expired(expired_custom_fireball) # 大火球
	projectile_manager.get_projectile(FrogCharacter.Spells.DRAGONS_BREATH).set_on_start(start_custom_flame).set_on_move(update_custom_flame) # 龙息 - 火焰喷射
	projectile_manager.get_projectile(FrogCharacter.Spells.ERUPTION).set_on_move(update_custom_eruption).set_on_collision(no_collision).set_property("rehit_lifetime", 0) # 喷发 - 无碰撞
	projectile_manager.get_projectile(FrogCharacter.Spells.BURNING_SKIES).set_on_move(update_custom_falling_star) # 燃烧天空 - 陨石下落
	projectile_manager.get_projectile(FrogCharacter.Spells.CELESTIAL_MISSILE).set_on_start(start_custom_sine).set_on_move(update_custom_sine) # 天体导弹 - 正弦波轨迹
	projectile_manager.get_projectile(FrogCharacter.Spells.MEGA_LASER).set_on_start(start_custom_laser).set_on_move(update_custom_laser).set_on_collision(no_collision) # 超级激光 - 激光效果

	## 通过ID直接获取投射物并设置回调（备用方法）
	projectile_manager.get_projectile(14).set_on_move(update_custom_closest_collision).set_on_collision(no_collision)
	projectile_manager.get_projectile(15).set_on_move(update_custom_closest_collision).set_on_collision(no_collision)

	##------------------------------------------
	## 设置攻击回调 - 针对所有已存在的攻击
	## set_on_charge_enter: 蓄力开始时调用
	## set_on_anticipate_enter: 预兆开始时调用（攻击动作前摇）
	## set_on_main_enter: 主攻击时调用（实际发射投射物）
	## set_on_recovery_enter: 恢复阶段开始时调用
	## set_on_completed: 攻击完成时调用
	## set_on_main_exit: 主攻击阶段结束时调用
	##------------------------------------------
	for attack: Attack2D in projectile_manager.attacks:
		attack.set_on_charge_enter(on_charge_enter).set_on_anticipate_enter(on_anticipate_enter).set_on_main_enter(on_main_enter).set_on_recovery_enter(on_recovery_enter).set_on_completed(on_completed)

	## 为特定攻击设置特殊行为
	projectile_manager.get_attack(FrogCharacter.Spells.DRAGONS_BREATH).set_on_main_exit(main_exit_repeat_weapon_state)        # 龙息 - 持续喷射
	projectile_manager.get_attack(FrogCharacter.Spells.ERUPTION).set_on_main_enter(main_enter_custom_eruption)              # 喷发 - 自定义位置射线检测
	projectile_manager.get_attack(FrogCharacter.Spells.BURNING_SKIES).set_on_main_exit(main_exit_repeat_weapon_state).set_on_main_enter(main_enter_custom_star_position) # 燃烧天空 - 陨石位置
	projectile_manager.get_attack(FrogCharacter.Spells.MEGA_LASER).set_on_charge_enter(charge_enter_custom_laser)            # 超级激光 - 蓄力效果

	##------------------------------------------
	## 注册修正器（Modifier）- 临时修改投射物/攻击属性
	## Projectile2DModifier: 修改投射物属性
	## Attack2DModifier: 修改攻击属性
	## 参数: 名称, 持续时间, 进入回调, 退出回调, 更新回调, 验证回调
	##------------------------------------------
	## 投射物修正器 - 进入时增强投射物（追踪+分裂）
	APDatabase.set_modifier(Projectile2DModifier.new("PROJECTILE_BUFF", 1, on_projectile_enter, on_projectile_exit
		, Callable(), refresh_projectile_validation))
	## 攻击修正器 - 进入时加快攻击速度
	APDatabase.set_modifier(Attack2DModifier.new("ATTACK_BUFF", 1, on_attack_enter, on_attack_exit
		, Callable(), refresh_attack_validation))



##=================================================================================================
## 攻击修正器方法 (Attack Buff Methods)
##
## 当 ATTACK_BUFF 修正器被激活时调用
## 用于临时修改攻击的时间参数，实现攻击加速效果
##=================================================================================================

## on_attack_enter - 修正器激活时调用
## 参数: _modifier - 修正器实例, attack - 被修改的攻击实例
## 功能: 将攻击各阶段时间缩短为原来的10%
func on_attack_enter(_modifier: Attack2DModifier, attack: Attack2D) -> void:
	var previous_state_duration: float = attack.get_current_state_duration()  # 记录修改前当前状态的持续时间

	## 将攻击各阶段时间缩短90%（乘以0.1）
	attack.attack_charge_time *= 0.1       # 蓄力时间
	attack.attack_anticipate_time *= 0.1   # 预兆时间
	attack.attack_duration_time *= 0.1     # 主攻击持续时间
	attack.attack_recovery_time *= 0.1     # 恢复时间

	## 调整当前状态已持续时间，保持动画进度一致
	attack.current_state_lifetime += (attack.get_current_state_duration() - previous_state_duration)


## on_attack_exit - 修正器结束时调用
## 功能: 恢复攻击各阶段时间为原始值
func on_attack_exit(_modifier: Attack2DModifier, attack: Attack2D) -> void:
	## 从攻击资源中恢复原始时间参数
	attack.attack_charge_time = attack.resource.attack_charge_time
	attack.attack_anticipate_time = attack.resource.attack_anticipate_time
	attack.attack_duration_time = attack.resource.attack_duration_time
	attack.attack_recovery_time = attack.resource.attack_recovery_time
	## 注释掉的代码：如果当前状态是主攻击阶段，会额外增加持续时间
	# if (attack.current_state == Attack2D.AttackState.ATTACK_MAIN):
	# 	attack.current_state_lifetime += (attack.attack_duration_time - attack.current_state_lifetime)


## refresh_attack_validation - 修正器验证回调
## 功能: 检查修正器是否已存在，如果存在则刷新持续时间并返回false（不重复添加）
## 返回: true - 允许添加新修正器, false - 已存在并刷新了持续时间
func refresh_attack_validation(_modifier: Attack2DModifier, _attack: Attack2D) -> bool:
	if (_attack.attack_modifiers.has(_modifier.name)):
		_attack.attack_modifiers[_modifier.name].lifetime = _modifier.duration  # 刷新持续时间
		return false
	return true


##=================================================================================================
## 投射物修正器方法 (Projectile Buff Methods)
##
## 当 PROJECTILE_BUFF 修正器被激活时调用
## 用于临时修改投射物的行为属性，实现追踪和分裂效果
##=================================================================================================

## on_projectile_enter - 修正器激活时调用
## 参数: _modifier - 修正器实例, proj - 被修改的投射物实例
## 功能: 增强投射物 - 增加数量、启用追踪、启用角度分散
func on_projectile_enter(_modifier: Projectile2DModifier, proj: Projectile2D) -> void:
	proj.instances += 2              # 增加投射物实例数量（分裂成多个）
	proj.proj_spread = Projectile2D.ProjectileSpread.ANGULAR  # 设置为角度分散模式
	proj.angular_spread = 90        # 设置角度分散范围（90度）
	proj.seeking = true              # 启用追踪功能
	proj.seeking_mask = proj.collision_mask  # 设置追踪目标掩码（与碰撞层相同）

	proj.angular_speed = 150         # 设置角速度（追踪转向速度）
	proj.cast_radius = 350           # 设置探测半径

	## 保存原始的移动回调，以便修正器退出时恢复
	proj.global_properties.erase("ORIGINAL_CALLABLE")
	proj.add_global_property("ORIGINAL_CALLABLE", proj.on_move)
	## 设置新的移动回调 - 渐进式追踪
	proj.set_on_move(progressive_seeking)


## on_projectile_exit - 修正器结束时调用
## 功能: 恢复投射物为原始属性
func on_projectile_exit(_modifier: Projectile2DModifier, proj: Projectile2D) -> void:
	proj.instances -= 2              # 减少投射物实例数量
	proj.proj_spread = proj.resource.proj_spread  # 恢复分散模式
	proj.angular_spread = proj.resource.angular_spread  # 恢复角度分散
	proj.seeking = proj.resource.seeking  # 恢复追踪设置

	## 恢复原始的移动回调
	var callable: Callable = proj.global_properties["ORIGINAL_CALLABLE"]
	proj.set_on_move(callable)


## progressive_seeking - 渐进式追踪方法
## 参数: proj - 投射物实例, delta - 帧时间
## 功能: 不断增加追踪角速度，同时调用原始移动逻辑
## 返回: 新的移动方向向量
func progressive_seeking(proj: Projectile2D, delta: float) -> Vector2:
	proj.angular_speed += 350 * delta  # 持续增加角速度（越来越灵活）
	## 调用原始移动回调，保持原有运动逻辑
	var callable: Callable = proj.global_properties["ORIGINAL_CALLABLE"]
	return callable.call(proj, delta)


## on_projectile_update - 修正器更新回调（已注释）
## 功能: 随着时间推移持续增强投射物（这里是增加角速度）
## 注意: 在set_modifier中传入的是空Callable，所以此方法未被使用
# func on_projectile_update(_modifier: Projectile2DModifier, projectile: Projectile2D, delta: float) -> void:
# 	projectile.angular_speed += 100 * delta


## refresh_projectile_validation - 修正器验证回调
## 功能: 检查修正器是否已存在，如果存在则刷新持续时间
## 返回: true - 允许添加新修正器, false - 已存在并刷新了持续时间
func refresh_projectile_validation(_modifier: Projectile2DModifier, _proj: Projectile2D) -> bool:
	if (_proj.projectile_modifiers.has(_modifier.name)):
		_proj.projectile_modifiers[_modifier.name].lifetime = _modifier.duration
		return false
	return true


##=================================================================================================
## 自定义激光蓄力攻击方法 (Custom Laser Charge Attack Method)
##
## 当 MEGA_LASER 攻击进入蓄力阶段时调用
## 功能: 创建蓄力视觉效果（幕布遮罩 + 火花粒子）
##=================================================================================================

## charge_enter_custom_laser - 激光蓄力开始回调
## 参数: attack - 攻击实例
## 功能: 设置蓄力时的视觉效果（遮罩动画 + 火花粒子）
func charge_enter_custom_laser(attack: Attack2D) -> void:
	## 获取攻击目标
	var target: CharacterTest = attack.individual_properties.get("TARGET")
	if (target == null):
		return

	## 设置火花粒子位置（目标位置 + 攻击偏移）
	spark.position = target.position + Vector2(target.selected_attack.attack_offset.x * target.facing_direction, target.selected_attack.attack_offset.y)
	spark.emitting = true  # 开始发射火花

	## 创建Tween动画控制幕布遮罩
	if (laser_tween):
		laser_tween.kill()  # 终止之前的动画
	## 创建新的Tween - 使用二次缓动和 Ease Out
	laser_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	## 1.2秒内将幕布变为目标颜色（蓄力动画）
	laser_tween.tween_property(curtain, "color", curtain_color, 1.2)
	## 延迟1.63秒后，0.3秒内将幕布变透明（释放激光）
	laser_tween.tween_property(curtain, "color", Color(0, 0, 0, 0), 0.3).set_delay(1.63)
	## 并行动画：延迟1.1秒后停止火花粒子
	laser_tween.parallel().tween_property(spark, "emitting", false, 0).set_delay(1.1)

	## 调用默认的蓄力进入回调
	on_charge_enter(attack)


##=================================================================================================
## 自定义喷发攻击方法 (Custom Eruption Attack Method)
##
## 当 ERUPTION 攻击进入主攻击阶段时调用
## 功能: 使用射线检测确定喷发位置（从天空落下的位置）
##=================================================================================================

## main_enter_custom_eruption - 喷发攻击主进入回调
## 参数: attack - 攻击实例
## 功能: 延迟执行射线检测，确定投射物应该从何处落下
func main_enter_custom_eruption(attack: Attack2D) -> void:
	## 使用call_deferred延迟一帧执行，确保物理空间已准备好
	querry_raycast_down.call_deferred(attack)


## querry_raycast_down - 向下射线检测
## 参数: attack - 攻击实例
## 功能: 从鼠标位置向下发射射线，找到地面位置作为投射物生成点
func querry_raycast_down(attack: Attack2D) -> void:
	## 设置攻击目标位置为鼠标位置
	attack.pi.destination = get_global_mouse_position()

	## 获取墙壁层用于射线检测
	var walls_layer: String = attack.global_properties["WALLS_LAYER"]
	## 创建射线参数：从鼠标位置向下发射到 y=-10
	var querry: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		attack.pi.destination, Vector2(attack.pi.destination.x, -10), walls_layer.bin_to_int())

	## 执行射线检测
	var result: Dictionary = get_world_2d().direct_space_state.intersect_ray(querry)

	## 计算投射物位置：如果检测到地面则使用地面位置，否则使用默认值
	var proj_pos: Vector2 = Vector2(attack.pi.destination.x, 0)
	if (result):
		proj_pos = result["position"]  # 使用射线检测到的地面位置

	## 设置投射物位置和目标位置
	attack.pi.position = proj_pos
	attack.pi.destination = proj_pos + Vector2.UP  # 向上偏移一点

	## 执行基础攻击（生成投射物）
	attack_base(attack)


##=================================================================================================
## 自定义陨石攻击方法 (Custom Falling Star Attack Method)
##
## 当 BURNING_SKIES 攻击进入主攻击阶段时调用
## 功能: 设置陨石从屏幕上方随机位置落下
##=================================================================================================

## main_enter_custom_star_position - 陨石位置设置回调
## 参数: attack - 攻击实例
## 功能: 随机设置投射物起始位置（在屏幕上方）和目标位置（鼠标周围）
func main_enter_custom_star_position(attack: Attack2D) -> void:
	## 设置目标位置为鼠标位置
	attack.pi.destination = get_global_mouse_position()

	## 设置投射物起始位置：在屏幕上方随机位置
	## x坐标：在目标位置左侧50-350像素范围内随机
	## y坐标：在屏幕上方-600到-900之间随机
	attack.pi.position = Vector2(randf_range(attack.pi.destination.x - 50, attack.pi.destination.x - 350), -600 + randf_range(0, -300))

	## 目标位置添加随机偏移，使陨石不完全集中在一个点
	attack.pi.destination += Vector2(randf_range(-50, 50), randf_range(-50,50))

	## 执行基础攻击
	attack_base(attack)


##=================================================================================================
## 自定义火焰喷射器攻击方法 (Custom Flamethrower Attack Method)
##
## 当 DRAGONS_BREATH 或 BURNING_SKIES 攻击主阶段结束时调用
## 功能: 如果攻击被连续请求，则保持主攻击状态（持续喷射效果）
##=================================================================================================

## main_exit_repeat_weapon_state - 武器状态重复回调
## 参数: attack - 攻击实例
## 功能: 检查是否应该继续维持主攻击状态（用于持续性攻击如火焰喷射）
func main_exit_repeat_weapon_state(attack: Attack2D) -> void:
	## 如果攻击处于不中断请求状态（玩家持续按住攻击键）
	if (attack.is_under_uninterrupted_request):
		## 切换回主攻击状态，继续发射投射物
		attack.change_state(attack.AttackState.ATTACK_MAIN)
	else:
		## 否则正常退出主攻击阶段进入恢复阶段
		attack.main_exit()


##=================================================================================================
## 自定义攻击回调方法 (Custom Attack Methods)
##
## 这些是攻击生命周期各阶段的默认回调函数
## 处理动画播放、音效播放、状态切换等
##=================================================================================================

## on_completed - 攻击完成回调
## 参数: attack - 攻击实例
## 功能: 攻击结束后将角色切换回空闲状态
func on_completed(attack: Attack2D) -> void:
	var target: CharacterTest = attack.individual_properties.get("TARGET")
	if (target == null):
		return

	target.attack_loop_allow_actions = 0  # 禁止攻击循环动作
	target.change_state(target.States.IDLE)  # 切换到空闲状态


## on_charge_enter - 蓄力阶段开始回调
## 参数: attack - 攻击实例
## 功能: 处理蓄力阶段的动画和音效
func on_charge_enter(attack: Attack2D) -> void:
	attack.charge_enter()  # 调用攻击组件的蓄力进入方法

	var target: CharacterTest = attack.individual_properties.get("TARGET")
	if (target == null):
		return

	## 播放蓄力动画
	target.animator.play("attack_charge")
	target.animator.advance(0)  # 立即推进到动画第一帧

	## 播放蓄力音效（如果配置了）
	var audio: AudioStream = attack.global_properties.get("CHARGE_AUDIO")
	if (audio != null):
		var volume: float = attack.global_properties["CHARGE_DB"]
		var start: float = attack.global_properties["CHARGE_HEADSTART"]
		target.create_audio_player(audio, start, volume)

	## 设置允许的动作标志
	target.attack_loop_allow_actions = 0
	if (attack.global_properties.get("ON_CHARGE_ACTIONS") != null):
		var allow_actions: String = attack.global_properties.get("ON_CHARGE_ACTIONS")
		target.attack_loop_allow_actions = allow_actions.bin_to_int()


## on_anticipate_enter - 预兆阶段开始回调
## 参数: attack - 攻击实例
## 功能: 处理预兆阶段的动画（前摇动作）
func on_anticipate_enter(attack: Attack2D) -> void:
	attack.anticipate_enter()  # 调用攻击组件的预兆进入方法

	var target: CharacterTest = attack.individual_properties.get("TARGET")
	if (target == null):
		return

	## 播放预兆/延迟动画
	target.animator.play("attack_delay")
	target.animator.advance(0)

	## 设置允许的动作标志
	target.attack_loop_allow_actions = 0
	if (attack.global_properties.get("ON_ANTICIPATE_ACTIONS") != null):
		var allow_actions: String = attack.global_properties.get("ON_ANTICIPATE_ACTIONS")
		target.attack_loop_allow_actions = allow_actions.bin_to_int()


## on_main_enter - 主攻击阶段开始回调
## 参数: attack - 攻击实例
## 功能: 设置投射物发射位置和目标，然后生成投射物
func on_main_enter(attack: Attack2D) -> void:
	var target: CharacterTest = attack.individual_properties.get("TARGET")
	## 如果有目标，设置投射物发射位置为角色位置+偏移
	if (target != null):
		attack.pi.position = target.position + Vector2(attack.attack_offset.x * target.facing_direction, attack.attack_offset.y)

	## 设置目标位置为鼠标位置
	attack.pi.destination = get_global_mouse_position()

	## 执行基础攻击
	attack_base(attack)


## attack_base - 基础攻击执行方法
## 参数: attack - 攻击实例
## 功能: 播放攻击动画、请求生成投射物、播放音效
func attack_base(attack: Attack2D) -> void:
	## 设置当前状态持续时间为攻击持续时间
	attack.current_state_lifetime = attack.attack_duration_time

	var target: CharacterTest = attack.individual_properties.get("TARGET")
	if (target == null):
		return

	## 播放攻击动画
	target.animator.play("attack")
	target.animator.advance(0)

	## 请求生成投射物
	attack.request_projectile()

	## 播放攻击释放音效（如果配置了）
	var audio: AudioStream = attack.global_properties.get("RELEASE_AUDIO")
	if (audio != null):
		var volume: float = attack.global_properties["RELEASE_DB"]
		var start: float = attack.global_properties["RELEASE_HEADSTART"]
		target.create_audio_player(audio, start, volume)

	## 设置允许的动作标志
	target.attack_loop_allow_actions = 0
	if (attack.global_properties.get("ON_MAIN_ACTIONS") != null):
		var allow_actions: String = attack.global_properties.get("ON_MAIN_ACTIONS")
		target.attack_loop_allow_actions = allow_actions.bin_to_int()


## on_recovery_enter - 恢复阶段开始回调
## 参数: attack - 攻击实例
## 功能: 处理恢复阶段的动画（后摇动作）
func on_recovery_enter(attack: Attack2D) -> void:
	attack.recovery_enter()  # 调用攻击组件的恢复进入方法

	var target: CharacterTest = attack.individual_properties.get("TARGET")
	if (target == null):
		return

	## 播放恢复动画
	target.animator.play("attack_recovery")
	target.animator.advance(0)

	## 禁止攻击循环动作
	target.attack_loop_allow_actions = 0


##=================================================================================================
## 自定义激光投射物方法 (Custom Laser Projectile Methods)
##
## 激光投射物是一种持续伤害型投射物
## 特点：不会移动，但会在其路径上的敌人持续造成伤害
##=================================================================================================

## update_custom_laser - 激光移动回调
## 参数: proj - 投射物实例, _delta - 帧时间
## 功能: 动态调整激光宽度、处理持续碰撞检测
## 返回: 激光方向向量（激光不移动，所以始终返回原始方向）
func update_custom_laser(proj: InstancedProjectile2D, _delta: float) -> Vector2:
	## 计算激光生命周期进度（0.0 = 开始, 1.0 = 结束）
	var delta: float = (proj.resource.lifetime - proj.lifetime) / proj.resource.lifetime

	## 获取激光前后边缘的Line2D引用和尺寸曲线
	var laser_front: Line2D = proj.individual_properties.get("FRONT_LINE")
	var laser_back: Line2D = proj.individual_properties.get("BACK_LINE")
	var buffer: Curve = proj.global_properties.get("SIZE_CURVE")

	## 根据生命周期进度动态调整激光宽度
	if (laser_front != null):
		laser_front.width = buffer.sample(delta) * 190
	if (laser_back != null):
		laser_back.width = buffer.sample(delta) * 220

	## 激光开始前20%时间保持稳定方向
	if (delta < 0.2):
		return proj.direction

	## 启动火花粒子效果（一旦激光"启动"）
	if (proj.individual_properties["HAS_STARTED"] == false):
		var trail: TimedParticle = proj.individual_properties.get("START_TIMED_PARTICLE_TRAIL")
		if (trail != null):
			## 粒子跟随激光前端移动
			trail.global_position = proj.position + (proj.direction * _delta * proj.speed * 0.15)
			trail.rotation = proj.direction.angle()
			trail.emitting = true
			## 激活所有子粒子节点
			for child: CPUParticles2D in trail.get_children():
				child.emitting = true

		proj.individual_properties["HAS_STARTED"] = true

	## 如果不允许重复碰撞，直接返回方向
	if (!proj.resource.allow_rehit):
		return proj.direction

	## 如果重击冷却时间未到，返回方向
	if !(proj.rehit_lifetime < 0):
		return proj.direction

	## 重置重击冷却时间
	proj.rehit_lifetime = proj.rehit_cooldown

	## 获取激光覆盖区域内的所有物体
	var area_bodies: Array[Node2D] = proj.area.get_overlapping_bodies()
	## 按距离排序，最近的优先
	area_bodies.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.position.distance_to(proj.position) < b.position.distance_to(proj.position))

	## 对每个重叠物体执行碰撞处理
	for body: Node2D in area_bodies:
		## 调用物体上的命中回调方法
		if body.has_method(proj.resource.on_hit_call):
			body.call(proj.resource.on_hit_call, proj)

		## 穿透次数-1
		proj.pierce -= 1

		## 如果穿透次数用尽
		if (proj.pierce < 1):
			## 更新激光线条末端位置到碰撞点
			if (laser_front != null):
				laser_front.set_point_position(1, (body.global_position - proj.position) * Vector2.RIGHT)
			if (laser_back != null):
				laser_back.set_point_position(1, (body.global_position - proj.position) * Vector2.RIGHT)
			## 显示火花粒子
			var trail: TimedParticle = proj.individual_properties.get("START_TIMED_PARTICLE_TRAIL")
			if (trail != null):
				var spark2: CPUParticles2D = trail.get_node("Spark2")
				spark2.position = (body.global_position - proj.position) * Vector2.RIGHT
			break

	## 恢复穿透次数（激光可以持续伤害多个敌人）
	proj.pierce = proj.resource.pierce
	return proj.direction


## start_custom_laser - 激光启动回调
## 参数: proj - 投射物实例
## 功能: 初始化激光视觉效果（线条、粒子）
func start_custom_laser(proj: InstancedProjectile2D) -> void:
	## 调用通用的粒子拖尾初始化
	start_custom_particle_trail(proj)

	## 初始化重击冷却时间
	proj.rehit_lifetime = 0

	## 保存前后激光线条的引用
	proj.individual_properties["FRONT_LINE"] = proj.instance.get_node("Front")
	proj.individual_properties["BACK_LINE"] = proj.instance.get_node("Back")
	proj.individual_properties["HAS_STARTED"] = false

	## 初始化激光线条宽度（从曲线起点开始）
	var buffer: Line2D = proj.instance.get_node("Front")
	var curve: Curve = proj.global_properties.get("SIZE_CURVE")
	buffer.width = curve.sample(0)

	buffer = proj.instance.get_node("Back")
	buffer.width = curve.sample(0)


##=================================================================================================
## 自定义正弦波投射物方法 (Custom Sine Wave Projectile Methods)
##
## 正弦波投射物以正弦曲线路径移动
## 特点：类似蛇形或波浪形轨迹
##=================================================================================================

## update_custom_sine - 正弦波移动回调
## 参数: proj - 投射物实例, _delta - 帧时间
## 功能: 计算正弦波偏移，更新位置
## 返回: 新的方向向量
func update_custom_sine(proj: InstancedProjectile2D, _delta: float) -> Vector2:
	## 调用陨石更新方法（旋转效果）
	update_custom_falling_star(proj, _delta, -3)

	## 更新时间累积
	var time: float = proj.individual_properties["TIME"] + _delta
	proj.individual_properties["TIME"] = time

	## 获取正弦波参数
	var frequency: float = proj.global_properties["FRECUENCY"]      # 频率（震荡速度）
	var amplitude: float = proj.global_properties["AMPLITUDE"]     # 振幅（震荡幅度）

	## 计算正弦波方向偏移
	## 公式: 新方向 = 原始方向 + (垂直方向 * sin(时间 * 频率) * 振幅)
	## orthogonal() 获取垂直向量
	return (proj.direction + (proj.direction.orthogonal() * cos(time * frequency)) * amplitude).normalized()


## start_custom_sine - 正弦波启动回调
## 参数: proj - 投射物实例
## 功能: 初始化时间参数和粒子拖尾方向
func start_custom_sine(proj: Projectile2D) -> void:
	## 调用通用的粒子拖尾初始化
	start_custom_particle_trail(proj)

	## 初始化时间累积
	proj.individual_properties["TIME"] = 0

	## 调整粒子拖尾的方向（旋转90度）
	var trail: TimedParticle = proj.individual_properties.get("START_TIMED_PARTICLE_TRAIL")
	if (trail != null):
		trail.transform = Transform2D(proj.direction.angle() - (PI / 2), Vector2.ONE, 0, proj.position)


##=================================================================================================
## 自定义陨石投射物方法 (Custom Falling Star Projectile Methods)
##
## 陨石投射物从天空坠落
## 特点：旋转下落，带有粒子拖尾效果
##=================================================================================================

## update_custom_falling_star - 陨石移动回调
## 参数: proj - 投射物实例, _delta - 帧时间, spin - 旋转速度（默认3.0）
## 功能: 处理陨石旋转动画和粒子拖尾位置
## 返回: 陨石飞行方向（始终向下）
func update_custom_falling_star(proj: InstancedProjectile2D, _delta: float, spin: float = 3.0) -> Vector2:
	## 旋转陨石（TAU = 2*PI = 360度）
	proj.transform = proj.transform.rotated(TAU * spin * _delta)

	## 更新粒子拖尾位置
	var trail: TimedParticle = proj.individual_properties.get("START_TIMED_PARTICLE_TRAIL")
	if (trail != null):
		## 粒子跟随在陨石后上方
		trail.global_position = proj.position + (proj.direction * _delta * proj.speed * 0.15)
		trail.rotation = proj.direction.angle() - (PI / 2)
		## 如果等待时间结束（投射物实际开始移动），显示拖尾
		if (proj.wait_time < 0):
			trail.visible = true

	return proj.direction


##=================================================================================================
## 自定义喷发投射物方法 (Custom Eruption Projectile Methods)
##
## 喷发投射物是一种特殊的投射物
## 特点：从地面喷发上升，到达顶点后下落
##=================================================================================================

## update_custom_eruption - 喷发移动回调
## 参数: proj - 投射物实例, _delta - 帧时间
## 功能: 处理重击逻辑和粒子拖尾
## 返回: 投射物方向
func update_custom_eruption(proj: InstancedProjectile2D, _delta: float) -> Vector2:
	## 如果允许重复命中
	if (proj.resource.allow_rehit):
		## 检查重击冷却
		if (proj.rehit_lifetime < 0):
			## 清除排除目标列表（允许再次命中之前命中的目标）
			proj.excluded_targets.clear()
			proj.rehit_lifetime = proj.rehit_cooldown  # 重置冷却
			proj.query.exclude = proj.excluded_targets
			proj.target = null  # 清除目标

			## 执行最近碰撞检测
			update_custom_closest_collision(proj, _delta)

	## 返回粒子拖尾更新结果（带旋转）
	return update_custom_particle_trail(proj, _delta, true)



##=================================================================================================
## 自定义火焰投射物方法 (Custom Flame Projectile Methods)
##
## 火焰喷射投射物是一种持续性伤害投射物
## 特点：速度从快到慢逐渐变化，大小随之变化，带持续碰撞检测
##=================================================================================================

## update_custom_flame - 火焰移动回调
## 参数: proj - 投射物实例, _delta - 帧时间
## 功能: 根据生命周期调整速度和大小，执行持续碰撞检测
## 返回: 投射物方向
func update_custom_flame(proj: InstancedProjectile2D, _delta: float) -> Vector2:
	var dic: Dictionary = proj.global_properties
	if (dic == null):
		return proj.direction

	## 计算生命周期进度
	var delta: float = (proj.resource.lifetime - proj.lifetime) / proj.resource.lifetime

	## 根据曲线调整速度（火焰喷射逐渐减慢）
	var buffer: Curve = dic.get("SPEED_CURVE")
	proj.speed = proj.resource.linear_speed * buffer.sample(delta)

	## 根据曲线调整大小
	buffer = dic.get("SIZE_CURVE")
	proj.transform = Transform2D(0.0, Vector2.ONE * buffer.sample(delta), 0, Vector2.ZERO)

	## 执行持续碰撞检测
	update_custom_constant_collision(proj)

	## 更新粒子拖尾
	return update_custom_particle_trail(proj, _delta, true)


## start_custom_flame - 火焰启动回调
## 参数: proj - 投射物实例
## 功能: 初始化火焰视觉效果（大小、粒子方向）
func start_custom_flame(proj: Projectile2D) -> void:
	## 调用通用粒子拖尾初始化
	start_custom_particle_trail(proj)

	## 根据曲线设置初始大小和旋转
	var buffer: Curve = proj.global_properties.get("SIZE_CURVE")
	proj.transform = Transform2D(proj.direction.angle(), Vector2.ONE * buffer.sample(0), 0, proj.position)

	## 同时调整粒子拖尾
	var trail: TimedParticle = proj.individual_properties.get("START_TIMED_PARTICLE_TRAIL")
	if (trail != null):
		trail.transform = Transform2D(proj.direction.angle(), Vector2.ONE * buffer.sample(0), 0, proj.position)


##=================================================================================================
## 自定义火球投射物方法 (Custom Fireball Projectile Methods)
##
## 火球投射物是一种标准的投射物
## 特点：飞向目标，碰撞后爆炸
##=================================================================================================

## update_custom_closest_collision - 最近碰撞检测回调
## 参数: proj - 投射物实例, _delta - 帧时间
## 功能: 检测最近的物体并触发碰撞
## 返回: 投射物方向
func update_custom_closest_collision(proj: InstancedProjectile2D, _delta: float) -> Vector2:
	## 获取投射物碰撞区域内的所有物体
	var area_bodies: Array[Node2D] = proj.area.get_overlapping_bodies()
	## 按距离排序，最近的优先
	area_bodies.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.position.distance_to(proj.position) < b.position.distance_to(proj.position))

	## 遍历所有物体进行碰撞检测
	for body: Node2D in area_bodies:
		## 跳过非碰撞对象
		if !(body is CollisionObject2D):
			continue

		var buffer: CollisionObject2D = body as CollisionObject2D

		## 验证碰撞是否有效（检查是否应该碰撞）
		if (!proj.validate_collision(buffer.get_rid(), body)):
			continue

		## 调用物体的命中回调
		if body.has_method(proj.resource.on_hit_call):
			body.call(proj.resource.on_hit_call, proj)

		## 处理穿透
		proj.on_pierced(buffer.get_rid())

		## 如果投射物已过期，停止处理
		if (proj.is_expired):
			return proj.direction

	return proj.direction


## expired_custom_fireball - 火球过期回调
## 参数: proj - 投射物实例
## 功能: 火球消失时触发爆炸效果
func expired_custom_fireball(proj: Projectile2D) -> void:
	## 释放粒子拖尾
	var trail: TimedParticle = proj.individual_properties.get("START_TIMED_PARTICLE_TRAIL")
	if (trail != null):
		trail.timed_free()

	## 获取爆炸场景
	var _scale: float = proj.global_properties.get("SCALE")
	var blast_scene: PackedScene = proj.global_properties.get("PROJECTILE_GLOBAL_PROPERTIES_KEY_EXPIRED_SCENE")

	## 如果配置了爆炸场景，实例化并播放
	if (blast_scene != null):
		var blast: TimedParticle = blast_scene.instantiate()
		blast.transform = proj.transform
		get_tree().current_scene.add_child(blast)
		## 自动释放爆炸效果
		blast.timed_free(true, true, _scale)


## no_collision - 空碰撞回调
## 参数: 所有碰撞相关参数（被忽略）
## 功能: 用于禁用默认碰撞行为的投射物（如激光、喷发）
func no_collision(_proj: Projectile2D, _area_rid: RID, _area_node: Node2D, _target_node: Node2D, _area_shape_index: int, _local_shape_index: int) -> void:
	return



##=================================================================================================
## 自定义凝视投射物方法 (Custom Glare Projectile Methods)
##
## 凝视投射物是一种视觉特效投射物
## 特点：大小和速度随生命周期变化，同时旋转
##=================================================================================================

## update_custom_glare - 凝视移动回调
## 参数: proj - 投射物实例, _delta - 帧时间
## 功能: 根据曲线调整速度、大小和旋转
## 返回: 投射物方向
func update_custom_glare(proj: InstancedProjectile2D, _delta: float) -> Vector2:
	## 计算生命周期进度
	var delta: float = (proj.resource.lifetime - proj.lifetime) / proj.resource.lifetime

	## 根据速度曲线调整速度
	var buffer: Curve = proj.global_properties.get("SPEED_CURVE")
	proj.speed = proj.resource.linear_speed * buffer.sample(delta)

	## 根据大小曲线调整大小
	buffer = proj.global_properties.get("SIZE_CURVE")
	## 根据旋转曲线调整旋转
	var buffer2: Curve = proj.global_properties.get("ROTATION_CURVE")
	proj.transform = Transform2D(buffer2.sample(delta), Vector2.ONE * buffer.sample(delta), 0, Vector2.ZERO)

	## 执行持续碰撞检测
	update_custom_constant_collision(proj)

	## 更新粒子拖尾
	return update_custom_particle_trail(proj, _delta)



##=================================================================================================
## 自定义追踪者投射物方法 (Custom Pursuer Projectile Methods)
##
## 追踪者投射物结合了追踪和持续碰撞
## 特点：持续追踪目标，同时持续造成伤害
##=================================================================================================

## custom_pursuer - 追踪者移动回调
## 参数: proj - 投射物实例, _delta - 帧时间
## 功能: 执行持续碰撞检测 + 追踪逻辑
## 返回: 新的方向向量
func custom_pursuer(proj: InstancedProjectile2D, _delta: float) -> Vector2:
	## 执行持续碰撞检测
	update_custom_constant_collision(proj)

	## 执行追踪逻辑
	return custom_seekeing(proj, _delta)



##=================================================================================================
## 持续碰撞检测方法 (Constant Collision Check Method)
##
## 用于持续伤害型投射物（如火焰、激光、追踪者）
## 特点：在投射物生命周期内持续检测并伤害路径上的敌人
##=================================================================================================

## update_custom_constant_collision - 持续碰撞检测
## 参数: proj - 投射物实例
## 功能: 每帧检测投射物覆盖区域内的物体，并造成伤害
func update_custom_constant_collision(proj: InstancedProjectile2D) -> void:
	## 如果是第一次命中，或不允许重复命中，则跳过
	if (proj.first_hit || !proj.resource.allow_rehit):
		return

	## 检查重击冷却是否结束
	if (proj.rehit_lifetime < 0):
		## 清除排除目标列表，允许再次命中
		proj.excluded_targets.clear()
		proj.rehit_lifetime = proj.rehit_cooldown  # 重置冷却
		proj.query.exclude = proj.excluded_targets
		proj.target = null  # 清除目标（允许重新追踪）
		proj.try_retarget()  # 尝试重新寻找目标

		## 获取投射物覆盖区域内的所有物体
		var area_bodies: Array[Node2D] = proj.area.get_overlapping_bodies()
		for body: Node2D in area_bodies:
			## 如果投射物已过期，停止处理
			if (proj.is_expired):
				return

			## 调用物体的命中回调
			if body.has_method(proj.resource.on_hit_call):
				body.call(proj.resource.on_hit_call, proj)

			## 穿透次数-1
			proj.pierce -= 1

			## 如果穿透次数用尽，标记投射物过期
			if (proj.pierce < 1):
				proj.is_expired = true



##=================================================================================================
## 渐进式追踪方法 (Variable/Progressive Seeking Method)
##
## 追踪型投射物的移动逻辑
## 特点：不断调整角速度来追踪目标
##=================================================================================================

## custom_seekeing - 追踪回调
## 参数: proj - 投射物实例, _delta - 帧时间
## 功能: 持续增加追踪角速度，同时更新粒子拖尾
## 返回: 新的方向向量
func custom_seekeing(proj: Projectile2D, _delta: float) -> Vector2:
	## 持续增加角速度（使用after_hit_angular_speed作为增量）
	proj.angular_speed += _delta * proj.resource.after_hit_angular_speed

	## 更新粒子拖尾位置
	return update_custom_particle_trail(proj, _delta)



##=================================================================================================
## 粒子拖尾方法 (Particle Trail Methods)
##
## 这些是所有投射物共用的粒子拖尾效果处理方法
## 用于在投射物后方创建视觉效果
##=================================================================================================

## start_custom_particle_trail - 粒子拖尾启动回调
## 参数: proj - 投射物实例
## 功能: 实例化粒子拖尾场景并设置初始位置
func start_custom_particle_trail(proj: Projectile2D) -> void:
	## 从全局属性获取粒子拖尾场景
	var trail_scene: PackedScene = proj.global_properties.get("START_TIMED_PARTICLE_TRAIL")
	if (trail_scene != null):
		## 实例化粒子节点
		var buffer: Node2D = trail_scene.instantiate()
		## 设置初始位置为投射物位置
		buffer.global_position = proj.position
		## 添加到当前场景
		get_tree().current_scene.add_child(buffer)

		## 如果有等待时间（在发射前等待），隐藏粒子
		if (proj.wait_time > 0):
			buffer.visible = false

		## 保存粒子引用以便后续更新
		proj.individual_properties["START_TIMED_PARTICLE_TRAIL"] = buffer



## update_custom_particle_trail - 粒子拖尾更新回调
## 参数: proj - 投射物实例, _delta - 帧时间, exeption - 是否旋转粒子（默认false）
## 功能: 更新粒子位置和可见性
## 返回: 投射物方向向量
func update_custom_particle_trail(proj: Projectile2D, _delta: float, exeption: bool = false) -> Vector2:
	## 获取粒子引用
	var trail: TimedParticle = proj.individual_properties.get("START_TIMED_PARTICLE_TRAIL")
	if (trail != null):
		## 同步变换
		trail.transform = proj.transform
		## 粒子位置：在投射物位置前方
		trail.global_position = proj.position + (proj.direction * _delta * proj.speed)

		## 如果需要旋转（火焰效果），旋转粒子
		if (exeption):
			trail.rotate(proj.direction.angle())

		## 等待时间结束后显示粒子
		if (proj.wait_time < 0):
			trail.visible = true

	return proj.direction


## expired_custom_particle_trail - 粒子拖尾过期回调
## 参数: proj - 投射物实例
## 功能: 释放粒子拖尾，并可选生成爆炸效果
func expired_custom_particle_trail(proj: Projectile2D) -> void:
	## 释放粒子拖尾
	var trail: TimedParticle = proj.individual_properties.get("START_TIMED_PARTICLE_TRAIL")
	if (trail != null):
		trail.timed_free()

	## 获取爆炸场景并实例化
	var blast_scene: PackedScene = proj.global_properties.get("PROJECTILE_GLOBAL_PROPERTIES_KEY_EXPIRED_SCENE")
	if (blast_scene != null):
		var blast: TimedParticle = blast_scene.instantiate()
		blast.transform = proj.transform
		get_tree().current_scene.add_child(blast)
		## 自动释放爆炸效果
		blast.timed_free(true)


##=================================================================================================
## 注释结束 - arbitrary_armory.gd
##
## 本文件展示了 all_projectiles 插件的完整用法
## 包括：
## 1. 攻击生命周期回调（蓄力→预兆→主攻击→恢复→完成）
## 2. 投射物生命周期回调（发射→移动→碰撞→过期）
## 3. 修正器系统（临时修改属性）
## 4. 各种特殊投射物效果（激光、正弦波、追踪、火焰等）
##
## 这些模式可以直接应用到塔、敌人、卡牌的投射物系统中
##=================================================================================================

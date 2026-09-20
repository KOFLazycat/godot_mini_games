## AbilitySystemComponent - 能力系统组件
##
## 功能说明：
## GodotGAS 框架的核心大脑
## 管理实体的标签、属性和能力
##
## 使用场景：
## - 挂载在角色/敌人/任何需要游戏能力系统的实体上
## - 管理技能激活、属性修改、效果应用
## - 通过信号与 UI 系统通信（血条、Buff图标等）
##
## 核心系统：
## - Tags (标签): 状态管理如眩晕、中毒等
## - Attributes (属性): 生命值、魔法值、攻击力等
## - Abilities (技能): 主动/被动技能
## - Effects (效果): Buff、Debuff、伤害、治疗等
##
## @meta_addon: GodotGAS Version 1 (See plugin version for exact version)
## @meta_author: YulRun (https://YulRun.Dev)
## @meta_license: MIT

@icon("res://addons/GodotGAS/icons/godot_gas_asc.svg")
class_name AbilitySystemComponent extends Node

## ============================================================================
## 信号系统
## ============================================================================

## 标签添加信号
## 标签计数从 0 变为 1 时触发
signal tag_added(tag: StringName)

## 标签计数增加信号
## 标签计数增加时触发
signal tag_count_changed(tag: StringName, new_count: int)

## 标签移除信号
## 标签计数降为 0 完全移除时触发
signal tag_removed(tag: StringName)

## 属性变化信号
## 属性的 current_value 实际被修改时触发
## 用途：连接 UI 血条或检测死亡（Health <= 0）
signal attribute_changed(attribute_name: String, old_value: float, new_value: float, effect_spec: GameplayEffectSpec)

## 效果应用到目标信号
## 攻击者命中目标时触发，通知自己的系统
signal effect_applied_to_target(target_asc: AbilitySystemComponent, spec: GameplayEffectSpec)

## 游戏事件接收信号
## 收到游戏事件时触发
signal gameplay_event_received(event_tag: StringName, payload: Variant)

## 活跃效果添加信号
## 持续或无限效果成功应用时触发
## UI 使用此信号开始冷却动画或显示 Buff/Debuff 图标
signal active_effect_added(active_effect: ActiveGameplayEffect)

## 活跃效果移除信号
## 效果自然过期或被强制清除时触发
## UI 使用此信号提前清除冷却或移除 Buff/Debuff 图标
signal active_effect_removed(active_effect: ActiveGameplayEffect)

## 技能激活失败信号
## 尝试激活技能物理失败时触发
## payload 字典包含上下文（如 {"tags": [阻止的标签数组]}）
signal ability_activation_failed(ability: GameplayAbility, reason: ActivationError, payload: Dictionary)

## 效果接收信号
## 当 ASC 从他人接收效果时触发
## UI 监听此信号生成伤害数字、"Miss!"或"Blocked!"文本
signal effect_received(source_asc: AbilitySystemComponent, spec: GameplayEffectSpec)

@export_category("State Management")
## ============================================================================
## 状态管理参数
## ============================================================================

## 属性集数组
## 存储角色的所有属性（生命值、魔法值、攻击力等）
@export var attribute_sets: Array[AttributeSet] = []

## 是否共享属性
## 如果为 false，ASC 启动时创建属性集的独特深拷贝
## 如果为 true，与其他实体共享精确的资源内存（Unreal 默认值为 false）
@export var share_attributes: bool = false

@export_category("Networking")
## ============================================================================
## 网络参数
## ============================================================================

## 是否网络化
## 如果为 true，ASC 将自动生成同步器处理属性和标签
## 同时拦截并通过 RPC 路由输入/效果以实现服务器授权
@export var is_networked: bool = false

@export_category("Debugging")
## ============================================================================
## 调试参数
## ============================================================================

## 是否启用信号日志调试
## 启用后将打印所有信号的详细日志
@export var debug_signal_log: bool = false

## ============================================================================
## 内部状态变量
## ============================================================================

## 当前按下的输入 ID 数组
var _active_inputs: Array[int] = []

## 已授予和管理的技能数组
var _active_abilities: Array[GameplayAbility] = []

## 当前活跃标签及其引用计数的字典
var _active_tags: Dictionary = {}

## 当前应用到此组件的活跃游戏效果数组
var _active_effects: Array[ActiveGameplayEffect] = []

## ============================================================================
## 枚举定义
## ============================================================================

## 激活错误 - 定义技能激活失败的确切原因
enum ActivationError {
	ALREADY_ACTIVE,          ## 技能已在执行
	ON_COOLDOWN,            ## 技能在冷却中
	BLOCKED_TAG,             ## 被标签阻止
	MISSING_TAG,             ## 缺少必需标签
	INSUFFICIENT_RESOURCES,  ## 资源不足
	INTERNAL_ERROR           ## 内部错误
}


#region Core Virtuals
## ============================================================================
## 核心虚函数
## ============================================================================

func _ready() -> void:
	## 强制内存隔离（Unreal GAS 标准）
	## 如果不共享属性，创建属性集的深拷贝
	if not share_attributes:
		for i in range(attribute_sets.size()):
			if attribute_sets[i]:
				## duplicate(true) 确保内部的 AttributeData 节点也被克隆
				attribute_sets[i] = attribute_sets[i].duplicate(true)

	## 自动网络同步设置
	if is_networked:
		var sync = MultiplayerSynchronizer.new()
		sync.name = "GASSynchronizer"
		var rep_config = SceneReplicationConfig.new()

		## 1. 同步活跃标签数组
		rep_config.add_property(NodePath(".:_active_tags"))

		## 2. 动态映射和同步所有实例化的属性！
		for i in range(attribute_sets.size()):
			if attribute_sets[i]:
				var set_path = ".:attribute_sets:" + str(i)
				for prop in attribute_sets[i].get_property_list():
					if prop.class_name == &"AttributeData":
						rep_config.add_property(NodePath(set_path + ":" + prop.name + ":current_value"))
						rep_config.add_property(NodePath(set_path + ":" + prop.name + ":base_value"))

		sync.replication_config = rep_config
		add_child(sync)

	## 调试绑定
	if debug_signal_log:
		tag_added.connect(_debug_tag_added)
		tag_count_changed.connect(_debug_tag_count_changed)
		tag_removed.connect(_debug_tag_removed)
		attribute_changed.connect(_debug_attribute_changed)
		effect_applied_to_target.connect(_debug_effect_applied_to_target)
		gameplay_event_received.connect(_debug_gameplay_event_received)
		active_effect_added.connect(_debug_active_effect_added)
		active_effect_removed.connect(_debug_active_effect_removed)


## 每帧处理
## 处理持续效果的周期性触发和过期
func _process(delta: float) -> void:
	for i in range(_active_effects.size() - 1, -1, -1):
		var active_effect = _active_effects[i]

		## 处理周期性触发（回合制除外）
		if active_effect.spec.period > 0.0 and active_effect.spec.effect_def.policy != GameplayEffect.DurationPolicy.TURN_BASED:
			active_effect.time_until_next_tick -= delta
			if active_effect.time_until_next_tick <= 0.0:

				## 1. 触发周期性 Cue
				for cue_tag in active_effect.spec.effect_def.periodic_cue_tags:
					execute_cue(cue_tag, {"target": get_parent()})

				## 2. 广播周期性事件（唤醒被动技能！）
				_trigger_effect_events(active_effect.spec)

				## 3. 重新评估并应用数学计算
				## 每 tick 执行允许 DoT 在攻击者属性变化时动态更新！
				_evaluate_spec(active_effect.spec)
				_commit_spec_math(active_effect.spec)

				## 重置下一次触发的计时器
				active_effect.time_until_next_tick += active_effect.spec.period

		## 处理过期
		if active_effect.spec.effect_def.policy == GameplayEffect.DurationPolicy.DURATION:
			active_effect.time_remaining -= delta

			if active_effect.time_remaining <= 0.0:
				remove_active_effect(active_effect)


## 推进回合
## 由外部回合管理器调用以处理回合制效果
func advance_turn() -> void:
	for i in range(_active_effects.size() - 1, -1, -1):
		var active_effect = _active_effects[i]
		var spec = active_effect.spec

		if spec.effect_def.policy == GameplayEffect.DurationPolicy.TURN_BASED:

			## 1. 处理回合制周期性触发（DoT/HoT）
			if spec.period > 0.0 and spec.effect_def.tick_on_turn_start:
				## 1a. 触发 Cue
				for cue_tag in spec.effect_def.periodic_cue_tags:
					execute_cue(cue_tag, {"target": get_parent()})

				## 1b. 广播事件
				_trigger_effect_events(spec)

				## 1c. 重新评估并应用计算
				_evaluate_spec(spec)
				_commit_spec_math(spec)

			## 2. 减少回合计数器
			spec.remaining_turns -= 1

			## 3. 检查过期
			if spec.remaining_turns <= 0:
				remove_active_effect(active_effect)


## 清理
## 安全停止所有技能，移除所有活跃效果，并清除内部状态
## 在拥有实体调用 queue_free() 前立即调用此方法以防止内存泄漏和孤立的 Cue
func cleanup() -> void:
	## 1. 强制中止所有授予的技能
	for ability in _active_abilities:
		if ability.is_active:
			ability.abort_ability()

	## 2. 反向计算数学并移除标签，但跳过昂贵的数组擦除
	for i in range(_active_effects.size() - 1, -1, -1):
		remove_active_effect(_active_effects[i], true)

	## 3. 原子化清除所有跟踪数组（O(1)时间）
	_active_inputs.clear()
	_active_abilities.clear()
	_active_tags.clear()
	_active_effects.clear()
#endregion


#region General Networking
## ============================================================================
## 通用网络
## ============================================================================

## 服务端接收客户端输入按下
@rpc("any_peer", "call_remote", "reliable")
func _server_receive_input_pressed(input_id: int) -> void:
	if is_multiplayer_authority():
		_ability_local_input_pressed(input_id)

## 服务端接收客户端输入释放
@rpc("any_peer", "call_remote", "reliable")
func _server_receive_input_released(input_id: int) -> void:
	if is_multiplayer_authority():
		_ability_local_input_released(input_id)

## 客户端执行由服务端广播的 Cue
@rpc("authority", "call_remote", "reliable")
func _client_execute_cue(tag: StringName, payload: Dictionary = {}) -> void:
	_execute_local_cue(tag, payload)
#endregion


#region Cues
## ============================================================================
## Cue 视觉/音效系统
## ============================================================================

## 执行 Cue
## 通过将请求转发到全局管理器来触发视觉/音频 Cue
## 如果在服务端上运行，拦截并向客户端广播请求
func execute_cue(tag: StringName, payload: Dictionary = {}) -> void:
	if is_networked and multiplayer.has_multiplayer_peer() and is_multiplayer_authority():
		rpc("_client_execute_cue", tag, payload)

	_execute_local_cue(tag, payload)


## 本地执行 Cue
func _execute_local_cue(tag: StringName, payload: Dictionary = {}) -> void:
	## 我们传递 get_parent() 作为目标
	## 这确保视觉 Cue 附加到角色/敌人，而非 ASC 节点本身
	GameplayCueManager.execute_cue(tag, get_parent(), payload)
#endregion


#region Ability Management
## ============================================================================
## 技能管理
## ============================================================================

## 授予技能
##
## 将技能节点添加为 ASC 的子节点并注册到技能列表中
## 被授予的技能将能够通过 ASC 进行激活和管理
##
## @param ability_node - 要授予的技能节点
func grant_ability(ability_node: GameplayAbility) -> void:
	if not ability_node.is_inside_tree():
		add_child(ability_node)
	
	ability_node.owner_asc = self
	_add_active_ability(ability_node)


## 移除技能
##
## 从 ASC 中移除指定的技能
## 会从技能列表中移除并销毁技能节点
##
## @param ability - 要移除的技能
func remove_ability(ability: GameplayAbility) -> void:
	_remove_active_ability(ability)
	ability.queue_free()


## 门神检查 - 验证技能是否可以激活
##
## ASC 的核心验证方法，检查技能是否满足所有激活条件
## 这是技能激活流程的第一道门槛，确保只有符合条件的技能才能执行
##
## 检查项目：
## 1. 技能是否为空
## 2. 技能是否已在执行
## 3. 激活阻止标签（Status.Stunned 等）
## 4. 冷却（个人冷却 + 共享冷却）
## 5. 激活必需标签（Stance.Stealth 等）
## 6. 资源消耗是否足够
##
## @param ability - 要检查的技能
## @param emit_failure - 是否在失败时发出信号
## @return - 允许激活返回 true
func can_activate_ability(ability: GameplayAbility, emit_failure: bool = false) -> bool:
	if ability == null:
		if emit_failure:
			ability_activation_failed.emit(ability, ActivationError.INTERNAL_ERROR, {"message": "Null Ability"})
		return false
	
	if ability.is_active:
		if emit_failure:
			ability_activation_failed.emit(ability, ActivationError.ALREADY_ACTIVE, {})
		return false
	
	# 1. Check Blocked Tags (e.g., Status.Stunned)
	if has_any_tags(ability.activation_blocked_tags):
		if emit_failure: 
			ability_activation_failed.emit(ability, ActivationError.BLOCKED_TAG, {"tags": ability.activation_blocked_tags})
		return false
	
	# 2. Check Cooldowns (Personal + Shared)
	if ability.has_method("get_cooldown_tags"):
		var cooldown_tags = ability.get_cooldown_tags()
		if has_any_tags(cooldown_tags):
			if emit_failure: 
				ability_activation_failed.emit(ability, ActivationError.ON_COOLDOWN, {"tags": cooldown_tags})
			return false
	
	# 3. Check Required Tags (e.g., Stance.Stealth)
	if not ability.activation_required_tags.is_empty() and not has_all_tags(ability.activation_required_tags):
		if emit_failure: 
			ability_activation_failed.emit(ability, ActivationError.MISSING_TAG, {"tags": ability.activation_required_tags})
		return false
	
	# 4. Check Resource Costs, Fully supports ExecCalcs predicting math
	if ability.cost_effect and not can_afford_cost(ability.cost_effect, ability.ability_level):
		if emit_failure: 
			ability_activation_failed.emit(ability, ActivationError.INSUFFICIENT_RESOURCES, {"effect": ability.cost_effect})
		return false
		
	return true


## 添加活跃技能
##
## 内部方法，将技能添加到活跃技能列表中
## 用于跟踪当前已授予的技能，支持取消引导中的技能等功能
##
## @param ability - 要添加的技能
func _add_active_ability(ability: GameplayAbility) -> void:
	if not _active_abilities.has(ability):
		_active_abilities.append(ability)


## 移除活跃技能引用
##
## 内部方法，从活跃技能列表中移除技能引用
## 注意：此方法只是移除引用，不会销毁技能节点
##
## @param ability - 要移除的技能
func _remove_active_ability(ability: GameplayAbility) -> void:
	_active_abilities.erase(ability)


## 检查是否可以支付资源消耗
##
## 检查实体是否有足够的资源来支付技能消耗
## 创建临时的效果规格来模拟计算，支持预测性数学计算
##
## 流程：
## 1. 创建模拟规格用于计算
## 2. 评估规格（运行 ExecCalcs 进行数学计算）
## 3. 验证预测数学与实际属性的对比
##
## @param effect - 消耗效果
## @param effect_level - 效果等级
## @return - 资源足够返回 true
func can_afford_cost(effect: GameplayEffect, effect_level: float = 1.0) -> bool:
	if not effect:
		return true
		
	# 1. Generate a mock spec to hold the context for our calculations
	var context = GameplayEffectContext.new(get_parent())
	var spec = GameplayEffectSpec.new(effect, context, effect_level)
	
	# 2. Evaluate the Spec (This runs the ExecCalcs to mutate magnitudes safely!)
	_evaluate_spec(spec)
	
	# 3. Verify the predicted math against our actual attributes
	for attr_name in spec.calculated_deltas:
		var attr_data = get_attribute(attr_name)
		var current_val = attr_data.current_value if attr_data else 0.0
		
		# If any resource drops below 0 after dynamic math, we cannot afford it!
		if current_val + spec.calculated_deltas[attr_name] < 0.0:
			return false
			
	return true


## 取消具有指定标签的技能
##
## 中止所有正在执行的、拥有给定标签或被给定标签阻止的技能
## 用于：当获得眩晕标签时，取消所有正在引导的技能
##
## @param tags - 要检查的标签数组
func cancel_abilities_with_tags(tags: Array[StringName]) -> void:
	for ability in _active_abilities:
		if not ability.is_active:
			continue
			
		for tag in tags:
			if ability.ability_tag == tag or tag in ability.activation_blocked_tags:
				ability.abort_ability()
				break 
#endregion


#region Attributes
## 获取属性数据
##
## 通过属性名称字符串获取 AttributeData 资源
## 在所有属性集中搜索匹配的属性
##
## @param attribute_name - 属性名称（如 "Health"）
## @return - 找到的 AttributeData 或 null
func get_attribute(attribute_name: String) -> AttributeData:
	for set in attribute_sets:
		if attribute_name in set: 
			var found_attr = set.get(attribute_name)
			if found_attr is AttributeData:
				return found_attr
				
	return null


## 检查属性是否存在
##
## 判断 ASC 是否拥有指定名称的属性
## @param attribute_name - 属性名称
## @return - 存在返回 true
func has_attribute(attribute_name: String) -> bool:
	for set in attribute_sets:
		if attribute_name in set:
			if set.get(attribute_name) is AttributeData:
				return true
	return false


## 应用属性变化（内部方法）
##
## 安全地修改属性的 current_value
## 此方法不应该在类外部直接调用，应该通过效果系统来修改属性
##
## 处理流程：
## 1. 获取旧的属性值
## 2. 计算建议值（旧值 + 变化量）
## 3. 调用 pre_attribute_change 允许属性集进行预处理（如 Clamp）
## 4. 实际修改属性值
## 5. 发出 attribute_changed 信号
## 6. 调用 post_attribute_change 允许属性集进行后处理
##
## @param attribute_name - 属性名称
## @param amount - 变化量（可以为负数）
## @param spec - 关联的效果规格（用于事件传递）
## @return - 实际应用的变化量
func _apply_attribute_change(attribute_name: String, amount: float, spec: GameplayEffectSpec = null) -> float:
	for set in attribute_sets:
		if attribute_name in set: 
			var attr = set.get(attribute_name)
			if attr is AttributeData:
				var old_value = attr.current_value 
				var proposed_value = old_value + amount
				
				var final_value = set.pre_attribute_change(attribute_name, proposed_value)
				var actual_delta = final_value - old_value
				
				if final_value != old_value:
					attr.current_value = final_value
					attribute_changed.emit(attribute_name, old_value, final_value, spec)
					
					set.post_attribute_change(self, attribute_name, old_value, final_value)
					
				return actual_delta
				
	push_warning("GodotGAS: Attempted to modify '%s', but the ASC does not possess that attribute." % attribute_name)
	return 0.0


## 初始化属性覆盖
##
## 接收强类型字典 {"attribute_name": override_value}
## 动态生成一个即时效果来通过 GAS 管道安全地应用属性值
##
## 用途：初始化角色属性、设置初始属性值
## 优势：通过效果系统应用，确保触发信号和 Clamp
##
## @param overrides - 属性名称到覆盖值的字典
func initialize_attribute_overrides(overrides: Dictionary[String, float]) -> void:
	if overrides.is_empty():
		return
		
	# Dynamically generate an Instant Effect
	var init_effect: GameplayEffect = GameplayEffect.new()
	init_effect.policy = GameplayEffect.DurationPolicy.INSTANT
	
	# Build the OVERRIDE modifiers based on the user's dictionary
	for attr_name: String in overrides.keys():
		var modifier: GameplayEffectModifier = GameplayEffectModifier.new()
		modifier.attribute_name = attr_name
		modifier.operation = GameplayEffectModifier.Operation.OVERRIDE
		modifier.magnitude = overrides[attr_name]
		init_effect.modifiers.append(modifier)
		
	# Create Context and Spec (Passing the instigator directly into the constructor)
	var context: GameplayEffectContext = GameplayEffectContext.new(self.get_parent())
	var spec: GameplayEffectSpec = GameplayEffectSpec.new(init_effect, context)
	
	# Apply to self (This routes through the clamps and fires UI signals!)
	apply_effect_spec(spec)
#endregion


#region Gameplay Effects Execution
## 应用效果到目标 ASC
##
## 将效果应用到目标 ASC，并广播成功信号到本地 UI 和被动技能
## 这是攻击者视角的应用方法，会触发 effect_applied_to_target 信号
##
## 流程：
## 1. 调用目标 ASC 的 apply_effect_spec
## 2. 如果目标成功接收效果，发出 effect_applied_to_target 信号
##
## @param spec - 效果规格
## @param target_asc - 目标 ASC
## @return - 成功返回 ActiveGameplayEffect，失败返回 null
func apply_effect_spec_to_target(spec: GameplayEffectSpec, target_asc: AbilitySystemComponent) -> ActiveGameplayEffect:
	if target_asc == null:
		return null
		
	# 1. We shove the payload onto the Enemy's ASC
	var resulting_effect = target_asc.apply_effect_spec(spec)
	
	# 2. If the enemy successfully received the effect (resulting_effect evaluates to true if not null)...
	if resulting_effect:
		# 3. WE (The Attacker's ASC) emit the signal to our own UI and Passives!
		effect_applied_to_target.emit(target_asc, spec)
		
	return resulting_effect


## 应用游戏效果（便捷包装器）
##
## 自动将原始 GameplayEffect 打包为规格进行执行
## 开发者无需手动创建 Context 和 Spec
##
## 流程：
## 1. 获取引发者（instigator）
## 2. 创建 GameplayEffectContext
## 3. 创建 GameplayEffectSpec
## 4. 调用 apply_effect_spec 执行
##
## @param effect - 游戏效果资源
## @param source_asc - 源 ASC（默认为 self）
## @param effect_level - 效果等级
## @return - 成功返回 ActiveGameplayEffect，失败返回 null
func apply_gameplay_effect(effect: GameplayEffect, source_asc: AbilitySystemComponent = self, effect_level: float = 1.0) -> ActiveGameplayEffect:
	if not effect:
		return null
	
	# Create a basic context and spec so the developer doesn't have to do it manually every time
	var instigator = source_asc.get_parent() if source_asc else get_parent()
	var context = GameplayEffectContext.new(instigator)
	var spec = GameplayEffectSpec.new(effect, context, effect_level)
	
	return apply_effect_spec(spec)


## 应用效果规格（主入口点）
##
## 技能应用即时效果到 ASC 的主要引擎入口点
## 如果是网络客户端且不是服务器授权，则拦截并拒绝数学计算
##
## 网络逻辑：
## - 如果启用了网络且存在多人对等端
## - 如果不是多人授权（服务器），返回 null
## - 否则调用内部方法 _apply_effect_spec
##
## @param spec - 效果规格
## @return - 成功返回 ActiveGameplayEffect，失败返回 null
func apply_effect_spec(spec: GameplayEffectSpec) -> ActiveGameplayEffect:
	if is_networked and multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		return null
		
	return _apply_effect_spec(spec)


## 内部方法 - 处理实际的数学应用和状态变化
##
## 实际执行效果规格的内部方法
## 处理免疫检查、条件检查、清除、堆叠、数学计算等
##
## 处理流程：
## 1. 检查免疫标签（忽略标签）
## 2. 检查应用条件（必需标签）
## 3. 清除模式（移除带有特定标签的效果）
## 4. 评估规格（执行计算）
## 5. 处理堆叠和刷新
## 6. 根据策略执行即时或持续效果
## 7. 触发事件唤醒被动技能
##
## @param spec - 效果规格
## @return - 成功返回 ActiveGameplayEffect，失败返回 null
func _apply_effect_spec(spec: GameplayEffectSpec) -> ActiveGameplayEffect:
	if not spec or not spec.effect_def:
		return null
		
	var effect = spec.effect_def
	
	# 1. Check for Immunities (Ignored Tags)
	for tag in effect.application_ignore_tags:
		if has_tag(tag):
			return null
	
	# 2. Check for Conditions (Required Tags)
	for tag in effect.application_required_tags:
		if not has_tag(tag):
			return null
	
	# 3. The Cleanser Pattern (Purge targeted effects BEFORE evaluating new math)
	for purge_tag in effect.remove_effects_with_tags:
		remove_effects_with_tag(purge_tag)
	
	_evaluate_spec(spec)
	
	# 4. Handle Stacking & Refreshing
	if effect.policy == GameplayEffect.DurationPolicy.DURATION or effect.policy == GameplayEffect.DurationPolicy.TURN_BASED:
		if effect.stacking_policy == GameplayEffect.StackingPolicy.REFRESH_DURATION:
			# Search to see if we already have this exact effect definition running
			for active_effect in _active_effects:
				if active_effect.spec.effect_def == effect:
					# We found it! Reset its clock back to full based on the dynamically altered Spec!
					if effect.policy == GameplayEffect.DurationPolicy.DURATION:
						active_effect.time_remaining = spec.duration 
					elif effect.policy == GameplayEffect.DurationPolicy.TURN_BASED:
						active_effect.spec.remaining_turns = spec.remaining_turns
					
					# Re-trigger application cues so the player knows it refreshed!
					for cue_tag in effect.application_cue_tags:
						execute_cue(cue_tag, {"target": get_parent()})
					
					# Determine the source for the UI signals
					var source_asc = null
					if spec.context and spec.context.instigator:
						source_asc = spec.context.instigator.get_node_or_null("AbilitySystemComponent")
						
					# Notify the Defender's UI that it was "received" again
					effect_received.emit(source_asc, spec)
					
					# Wake up any passives for the refresh!
					_trigger_effect_events(spec)
					
					# EXIT EARLY: We refreshed the old one, do not add the new one!
					# Return the refreshed effect reference
					return active_effect
	
	# 5. Create a variable to hold the newly generated effect
	var resulting_effect: ActiveGameplayEffect = null
	
	match effect.policy:
		GameplayEffect.DurationPolicy.INSTANT:
			resulting_effect = _execute_instant_spec(spec)
		GameplayEffect.DurationPolicy.DURATION, GameplayEffect.DurationPolicy.INFINITE, GameplayEffect.DurationPolicy.TURN_BASED:
			resulting_effect = _execute_active_spec(spec)
	
	# 6. Notify the Defender's UI that an effect was fully processed
	var source_asc = null
	if spec.context and spec.context.instigator:
		source_asc = spec.context.instigator.get_node_or_null("AbilitySystemComponent") # Adjust based on your node path
		
	effect_received.emit(source_asc, spec)
	
	# 7. Wake up any passives listening for this application!
	_trigger_effect_events(spec)
	
	# 8. Return the finalized effect reference
	return resulting_effect


## 执行即时效果
##
## 处理立即发生且永久的效果（如受到伤害）
## 返回临时的 ActiveGameplayEffect 以便框架注册成功（truthy）
## 但不会保存到内存中
##
## 处理流程：
## 1. 触发应用 Cue
## 2. 创建临时容器
## 3. 实际应用数学伤害/治疗
##
## @param spec - 效果规格
## @return - 临时的 ActiveGameplayEffect
func _execute_instant_spec(spec: GameplayEffectSpec) -> ActiveGameplayEffect:
	# 1. Trigger Application Cues
	for cue_tag in spec.effect_def.application_cue_tags:
		execute_cue(cue_tag, {"target": get_parent()})
		
	# 2. Create a temporary container to return
	var active_effect = ActiveGameplayEffect.new(spec)
	
	# 3. Actually apply the mathematical damage/healing!
	active_effect.applied_deltas = _commit_spec_math(spec)
	
	# We return it so the caller knows it succeeded, but we DO NOT add it to _active_effects
	return active_effect


## 执行持续效果
##
## 处理在角色身上持续存在的效果（如 Buff/Debuff）
## 返回保存在内存中的持久 ActiveGameplayEffect
##
## 处理流程：
## 1. 使用动态 spec 变量初始化（不是静态 effect_def）
## 2. 触发应用 Cue
## 3. 授予标签
## 4. 应用数学计算（仅非周期性效果）
## 5. 添加到活跃效果数组
## 6. 广播到 UI 和被动监听器
##
## @param spec - 效果规格
## @return - 持久的 ActiveGameplayEffect
func _execute_active_spec(spec: GameplayEffectSpec) -> ActiveGameplayEffect:
	# Note: Initializes using the dynamic 'spec' variable, not the static 'effect_def' variable!
	var active_effect = ActiveGameplayEffect.new(spec) 
	var effect = spec.effect_def
	
	# 1. Trigger Application Cues
	for cue_tag in effect.application_cue_tags:
		execute_cue(cue_tag, {"target": get_parent()})
	
	# 2. Grant Tags
	for tag in effect.granted_tags:
		add_tag(tag)
		
	# 3. Apply Math and record it to reverse later (ONLY if not periodic)
	if spec.period <= 0.0:
		active_effect.applied_deltas = _commit_spec_math(spec)
			
	_active_effects.append(active_effect)
	
	# Broadcast to the UI and passive listeners
	active_effect_added.emit(active_effect)
	
	# Return the persistent effect so the inventory/ability can store the reference!
	return active_effect


## 移除活跃效果
##
## 完全撤销活跃效果的数学变化和标签，并从内存中清除
## 用于效果过期、被打断或被驱散
##
## 处理流程：
## 1. 移除效果授予的所有标签
## 2. 撤销所有属性变化（取反）
## 3. 从活跃效果数组中移除（除非 skip_array_erase）
## 4. 发出 active_effect_removed 信号
##
## @param active_effect - 要移除的活跃效果
## @param skip_array_erase - 是否跳过数组擦除（用于批量清除）
func remove_active_effect(active_effect: ActiveGameplayEffect, skip_array_erase: bool = false) -> void:
	for tag in active_effect.get_effect_def().granted_tags:
		remove_tag(tag)
		
	for attr_name in active_effect.applied_deltas.keys():
		var reverse_delta = -active_effect.applied_deltas[attr_name]
		_apply_attribute_change(attr_name, reverse_delta)
		
	if not skip_array_erase and _active_effects.has(active_effect):
		active_effect_removed.emit(active_effect)
		_active_effects.erase(active_effect)
	elif skip_array_erase:
		# Still emit the signal for UI cleanup during a bulk wipe
		active_effect_removed.emit(active_effect)


## 移除具有指定标签的所有活跃效果
##
## 查找所有授予指定标签的活跃效果并移除它们
## 常用于驱散效果：如驱散所有毒液效果
##
## @param tag - 要检查的标签
func remove_effects_with_tag(tag: StringName) -> void:
	for i in range(_active_effects.size() - 1, -1, -1):
		var active_effect = _active_effects[i]
		if tag in active_effect.get_effect_def().granted_tags:
			remove_active_effect(active_effect)


## 移除来自特定来源的所有活跃效果
##
## 移除所有由指定引发者（源节点）应用的效果
## 常用于：当敌人死亡时，移除其施加的所有效果
##
## @param source_node - 源节点（引发者）
func remove_effects_from_source(source_node: Node) -> void:
	if not source_node:
		return
		
	# Iterate backwards since we are removing items from the array
	for i in range(_active_effects.size() - 1, -1, -1):
		var active_effect = _active_effects[i]
		
		# Safely check if the effect has a spec, a context, and an instigator that matches our query
		if active_effect.spec and active_effect.spec.context and active_effect.spec.context.instigator == source_node:
			remove_active_effect(active_effect)
#endregion


#region Math & Modifiers

## STEP 1: Evaluates all Executions and Modifiers to predict the final mathematical changes.
## This populates `spec.calculated_deltas` and allows ExecCalcs to mutate duration/magnitudes safely.
func _evaluate_spec(spec: GameplayEffectSpec) -> void:
	var projected_deltas: Dictionary = {}
	
	if not spec or not spec.effect_def:
		return
		
	var effect = spec.effect_def
	
	# 1. Process Execution Calculations (Dynamic Math & Spec Mutation)
	for execution in effect.executions:
		if execution:
			# Executions can edit spec.duration, spec.period, spec.mutated_magnitudes, OR return flat deltas
			var exec_deltas = execution.execute(spec, self)
			
			for attr_name in exec_deltas:
				projected_deltas[attr_name] = projected_deltas.get(attr_name, 0.0) + exec_deltas[attr_name]

	# 2. Process Standard Modifiers
	for mod in effect.modifiers:
		if not mod or mod.attribute_name == "":
			continue
			
		var attr_name = mod.attribute_name
		# IMPORTANT: Pull magnitude from the mutated dictionary, NOT the base definition!
		var magnitude = spec.mutated_magnitudes.get(attr_name, 0.0) 
		
		var current_val = 0.0
		var attr_data = get_attribute(attr_name)
		if attr_data:
			current_val = attr_data.current_value
			
		var delta = 0.0
		match mod.operation:
			GameplayEffectModifier.Operation.ADD:
				delta = magnitude
			GameplayEffectModifier.Operation.MULTIPLY:
				delta = (current_val * magnitude) - current_val
			GameplayEffectModifier.Operation.DIVIDE:
				if magnitude != 0:
					delta = (current_val / magnitude) - current_val
			GameplayEffectModifier.Operation.OVERRIDE:
				delta = magnitude - current_val
				
		projected_deltas[attr_name] = projected_deltas.get(attr_name, 0.0) + delta
			
	# Save the final projections directly into the spec
	spec.calculated_deltas = projected_deltas


## STEP 2: Actually applies the pre-calculated deltas to the ASC's attributes.
func _commit_spec_math(spec: GameplayEffectSpec) -> Dictionary:
	var final_clamped_deltas: Dictionary = {}
	
	if not spec or spec.calculated_deltas.is_empty():
		return final_clamped_deltas
	
	# Physically modify the stats
	for attr_name in spec.calculated_deltas:
		var actual_change = _apply_attribute_change(attr_name, spec.calculated_deltas[attr_name], spec)
		if actual_change != 0.0:
			final_clamped_deltas[attr_name] = actual_change
	
	# Update the spec to reflect the true reality of what happened (after stats clamped)
	spec.calculated_deltas = final_clamped_deltas
	return final_clamped_deltas

#endregion


#region Tag Management
## 添加标签
##
## 增加给定标签的引用计数
## 如果标签不存在，则创建新标签并发出 tag_added 信号
## 总是发出 tag_count_changed 信号
##
## @param tag - 要添加的标签
func add_tag(tag: StringName) -> void:
	if _active_tags.has(tag):
		_active_tags[tag] += 1
	else:
		_active_tags[tag] = 1
		tag_added.emit(tag)
	
	tag_count_changed.emit(tag, _active_tags[tag])


## 移除标签
##
## 减少给定标签的引用计数
## 如果引用计数降为 0，则完全移除标签并发出 tag_removed 信号
## 否则发出 tag_count_changed 信号
##
## @param tag - 要移除的标签
func remove_tag(tag: StringName) -> void:
	if not _active_tags.has(tag): 
		return
		
	_active_tags[tag] -= 1
	
	if _active_tags[tag] <= 0:
		_active_tags.erase(tag)
		tag_removed.emit(tag)
	else:
		tag_count_changed.emit(tag, _active_tags[tag])


## 强制清除标签
##
## 强制移除标签，无视当前的引用计数
## 用于需要立即清除标签的紧急情况
##
## @param tag - 要清除的标签
func clear_tag(tag: StringName) -> void:
	if _active_tags.has(tag):
		_active_tags.erase(tag)
		tag_removed.emit(tag)
#endregion


#region Tag Queries
## 获取标签剩余持续时间
##
## 返回授予此标签的任何活跃效果的最大剩余持续时间
## 用于 UI 显示 Debuff 剩余时间
##
## @param tag - 要查询的标签
## @return - 最大剩余持续时间（秒）
func get_tag_duration_remaining(tag: StringName) -> float:
	var max_time: float = 0.0
	for active_effect in _active_effects:
		if tag in active_effect.get_effect_def().granted_tags:
			if active_effect.time_remaining > max_time:
				max_time = active_effect.time_remaining
	return max_time


## 检查是否存在精确标签
##
## 检查 ASC 是否拥有完全匹配的标签（不检查子标签）
##
## @param tag - 要检查的标签
## @return - 存在返回 true
func has_tag_exact(tag: StringName) -> bool:
	return _active_tags.has(tag)


## 检查标签是否存在（包含子标签）
##
## 检查 ASC 是否拥有给定标签或其任何子标签
## 例如：has_tag("Status") 对 "Status.Stunned" 也返回 true
##
## @param tag - 要检查的标签
## @return - 存在返回 true
func has_tag(tag: StringName) -> bool:
	if _active_tags.has(tag):
		return true
		
	var tag_str = String(tag)
	for active_tag in _active_tags.keys():
		var active_str = String(active_tag)
		if active_str.begins_with(tag_str + "."):
			return true
			
	return false


## 检查是否有任意标签
##
## 检查 ASC 是否拥有数组中至少一个标签
## 用于检查是否被任意一种状态阻止
##
## @param tags - 要检查的标签数组
## @return - 至少有一个返回 true
func has_any_tags(tags: Array[StringName]) -> bool:
	for t in tags:
		if has_tag(t):
			return true
	return false


## 检查是否拥有所有标签
##
## 检查 ASC 是否拥有数组中的每一个标签
## 用于检查是否满足所有激活条件
##
## @param tags - 要检查的标签数组
## @return - 全部拥有返回 true
func has_all_tags(tags: Array[StringName]) -> bool:
	if tags.is_empty():
		return false
	for t in tags:
		if not has_tag(t):
			return false
	return true
#endregion


#region Input Routing
## 绑定技能到输入
##
## 将活跃技能安全绑定到输入槽
## 如果 unbind_others 为 true，则解除其他使用相同 ID 的技能的绑定
##
## @param ability - 要绑定的技能
## @param new_input_id - 新的输入 ID
## @param unbind_others - 是否解除其他技能的绑定
func bind_ability_to_input(ability: GameplayAbility, new_input_id: int, unbind_others: bool = true) -> void:
	if not _active_abilities.has(ability):
		push_error("GodotGAS: Cannot bind ability to input. It has not been granted to this ASC.")
		return
		
	if unbind_others:
		for active_ability in _active_abilities:
			if active_ability.input_id == new_input_id and active_ability != ability:
				active_ability.input_id = -1 # Unbind the old ability
				
	ability.input_id = new_input_id


## 本地输入按下
##
## 由玩家控制器在输入按下时调用
## 路由到匹配的技能
## 如果玩家是网络客户端，则转发到服务器
##
## @param input_id - 按下的输入 ID
func ability_local_input_pressed(input_id: int) -> void:
	if is_networked and multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		rpc_id(1, "_server_receive_input_pressed", input_id)
		return
		
	_ability_local_input_pressed(input_id)


## 内部方法 - 本地输入按下处理
##
## 实际处理输入按下的内部方法
## 将输入 ID 添加到活动输入列表，然后路由到匹配的技能
##
## @param input_id - 按下的输入 ID
func _ability_local_input_pressed(input_id: int) -> void:
	if not _active_inputs.has(input_id):
		_active_inputs.append(input_id)
		
	for ability in _active_abilities:
		if ability.input_id == input_id:
			ability._input_pressed(self)


## 本地输入释放
##
## 由玩家控制器在输入释放时调用
## 路由到匹配的技能
## 如果玩家是网络客户端，则转发到服务器
##
## @param input_id - 释放的输入 ID
func ability_local_input_released(input_id: int) -> void:
	if is_networked and multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		rpc_id(1, "_server_receive_input_released", input_id)
		return
		
	_ability_local_input_released(input_id)


## 内部方法 - 本地输入释放处理
##
## 实际处理输入释放的内部方法
## 将输入 ID 从活动输入列表中移除，然后路由到匹配的技能
##
## @param input_id - 释放的输入 ID
func _ability_local_input_released(input_id: int) -> void:
	if _active_inputs.has(input_id):
		_active_inputs.erase(input_id)
		
	for ability in _active_abilities:
		if ability.input_id == input_id:
			ability._input_released(self)
#endregion


#region Gameplay Events
## 触发效果事件
##
## 扫描效果规格并触发所有静态和动态事件
## 1. 触发设计师在检视器中定义的静态事件标签
## 2. 触发执行计算注入的动态事件标签
##
## @param spec - 效果规格
func _trigger_effect_events(spec: GameplayEffectSpec) -> void:
	# 1. Trigger static events defined by the designer in the Inspector
	for event_tag in spec.effect_def.event_tags:
		send_gameplay_event(event_tag, spec)
		
	# 2. Trigger dynamic events injected by Execution Calculations!
	for dynamic_tag in spec.dynamic_tags:
		send_gameplay_event(dynamic_tag, spec)


## 发送游戏事件
##
## 向此 ASC 发送全局事件
## 如果任何已授予的技能正在监听此标签，它们将尝试激活并接收负载
## 用于：被动技能响应游戏事件自动触发
##
## 处理流程：
## 1. 发出 gameplay_event_received 信号通知外部世界
## 2. 遍历已授予的技能，检查触发事件标签
## 3. 如果匹配，尝试激活技能并传递负载
##
## @param event_tag - 事件标签
## @param payload - 可选的负载数据
func send_gameplay_event(event_tag: StringName, payload: Variant = null) -> void:
	if event_tag == "":
		return
	
	# Announce event to outside world
	gameplay_event_received.emit(event_tag, payload)
	
	# Loop through granted abilities and check their triggers
	for ability in _active_abilities:
		if ability.trigger_event_tag == event_tag:
			# The ability was listening for this! Try to activate it and pass the data.
			if payload is GameplayEffectSpec:
				ability.try_activate(payload.context)
			else:
				# If `payload` is `GameplayEffectContext` or else.
				ability.try_activate(payload)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# The node is being destroyed in memory. Clean up timers, orphaned effects, and array references!
		cleanup()
#endregion


#region 调试信号日志函数
## ============================================================================
## 调试信号日志
## ============================================================================

## 调试：标签添加
## 当 debug_signal_log 启用时，记录标签添加事件
func _debug_tag_added(tag: StringName) -> void:
	print_rich("[color=gray]> (DEBUG)[/color] [color=cyan]<%s>[/color] signal [color=orange][tag_added][/color] added [color=green]'%s'[/color] Tag to %s's ASC" % [self.get_parent().name, tag, self.get_parent().name])


## 调试：标签计数变化
## 当 debug_signal_log 启用时，记录标签计数变化事件
func _debug_tag_count_changed(tag: StringName, new_count: int) -> void:
	print_rich("[color=gray]> (DEBUG)[/color] [color=cyan]<%s>[/color] signal [color=orange][tag_count_changed][/color] changed [color=green]'%s'[/color] stack count to [color=yellow]%d[/color] on %s's ASC" % [self.get_parent().name, tag, new_count, self.get_parent().name])


## 调试：标签移除
## 当 debug_signal_log 启用时，记录标签移除事件
func _debug_tag_removed(tag: StringName) -> void:
	print_rich("[color=gray]> (DEBUG)[/color] [color=cyan]<%s>[/color] signal [color=orange][tag_removed][/color] removed [color=green]'%s'[/color] Tag from %s's ASC" % [self.get_parent().name, tag, self.get_parent().name])


## 调试：属性变化
## 当 debug_signal_log 启用时，记录属性变化事件
func _debug_attribute_changed(attribute_name: String, old_value: float, new_value: float, effect_spec: GameplayEffectSpec) -> void:
	var effect_name = _get_debug_spec_name(effect_spec)
	print_rich("[color=gray]> (DEBUG)[/color] [color=cyan]<%s>[/color] signal [color=orange][attribute_changed][/color] changed attribute [color=green]'%s'[/color] from [color=yellow]%s[/color] to [color=yellow]%s[/color] via [color=green]'%s'[/color]" % [self.get_parent().name, attribute_name, old_value, new_value, effect_name])


## 调试：效果应用到目标
## 当 debug_signal_log 启用时，记录效果应用到目标事件
func _debug_effect_applied_to_target(target_asc: AbilitySystemComponent, spec: GameplayEffectSpec) -> void:
	var effect_name = _get_debug_spec_name(spec)
	print_rich("[color=gray]> (DEBUG)[/color] [color=cyan]<%s>[/color] signal [color=orange][effect_applied_to_target][/color] %s's ASC applied [color=green]'%s'[/color] to [color=cyan]%s's[/color] ASC" % [self.get_parent().name, self.get_parent().name, effect_name, target_asc.get_parent().name])


## 调试：接收游戏事件
## 当 debug_signal_log 启用时，记录接收游戏事件
func _debug_gameplay_event_received(event_tag: StringName, payload: Variant) -> void:
	var payload_desc = "[color=red]Null Payload[/color]"

	var instigator = null
	if payload is GameplayEffectContext:
		instigator = payload.instigator
	elif payload is GameplayEffectSpec and payload.context:
		instigator = payload.context.instigator

	if instigator:
		payload_desc = "Payload(From: [color=cyan]%s[/color])" % instigator.name
	elif payload != null:
		payload_desc = "Payload([color=purple]%s[/color])" % payload

	print_rich("[color=gray]> (DEBUG)[/color] [color=cyan]<%s>[/color] signal [color=orange][gameplay_event_received][/color] %s's ASC received [color=green]'%s'[/color] event with %s" % [self.get_parent().name, self.get_parent().name, event_tag, payload_desc])


## 调试：活跃效果添加
## 当 debug_signal_log 启用时，记录活跃效果添加事件
func _debug_active_effect_added(active_effect: ActiveGameplayEffect) -> void:
	var effect_name = _get_debug_spec_name(active_effect.spec)
	var duration = active_effect.spec.duration if active_effect.spec.duration > 0.0 else "Infinite"
	print_rich("[color=gray]> (DEBUG)[/color] [color=cyan]<%s>[/color] signal [color=orange][active_effect_added][/color] added [color=green]'%s'[/color] with duration [color=yellow]%s[/color]s" % [self.get_parent().name, effect_name, duration])

## 调试：活跃效果移除
## 当 debug_signal_log 启用时，记录活跃效果移除事件
func _debug_active_effect_removed(active_effect: ActiveGameplayEffect) -> void:
	var effect_name = _get_debug_spec_name(active_effect.spec)
	print_rich("[color=gray]> (DEBUG)[/color] [color=cyan]<%s>[/color] signal [color=orange][active_effect_removed][/color] removed [color=green]'%s'[/color]" % [self.get_parent().name, effect_name])


## --- 内部调试辅助函数 ---
## 获取效果规格的调试名称
## 用于调试日志中显示效果名称
func _get_debug_spec_name(spec: GameplayEffectSpec) -> String:
	if spec == null or spec.effect_def == null:
		return "[color=red]Manual/Unknown Effect[/color]"
		
	if spec.effect_def.resource_name != "":
		return spec.effect_def.resource_name
		
	if spec.effect_def.resource_path != "":
		return spec.effect_def.resource_path.get_file().get_basename()
		
	return "[color=gray]Unnamed Effect Resource[/color]"
#endregion

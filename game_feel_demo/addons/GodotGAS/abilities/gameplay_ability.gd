## GameplayAbility - 游戏技能基类
##
## 功能说明：
## GodotGAS 框架中所有游戏技能的基类
## 定义技能的核心执行逻辑、输入路由和效果应用流程
## 供具体的技能脚本继承使用
##
## 使用场景：
## - 定义火球术、治疗术、冲锋等技能
## - 管理技能激活流程
## - 处理资源消耗和冷却
## - 应用效果到目标
##
## 数据流：
## try_activate() → _activate_ability() → commit_ability() → apply_effect_to_targets()
##
## @meta_addon: GodotGAS Version 1 (See plugin version for exact version)
## @meta_author: YulRun (https://YulRun.Dev)
## @meta_license: MIT

@abstract
@icon("res://addons/GodotGAS/icons/godot_gas_asc.svg")
class_name GameplayAbility extends Node

## ============================================================================
## 信号
## ============================================================================

## 技能结束信号
## 技能结束时触发，UI 或动画系统可以监听此信号以了解施法是否成功或被打断
signal ability_ended(was_cancelled: bool)

@export_category("Ability Rules")
## ============================================================================
## 技能规则
## ============================================================================

## 技能名称
## 用于日志或 UI 显示的简单名称
@export var ability_name: String = ""

## 技能标签
## 唯一标识此技能的标签
@export var ability_tag: StringName = "Ability.None"

## 技能等级
## 技能的当前等级，用于缩放数值和效果
@export var ability_level: float = 1.0

## 激活阻止标签
## 如果 ASC 上存在这些标签，将阻止技能激活
## 例如：Status.Stunned（眩晕）阻止大多数技能
@export var activation_blocked_tags: Array[StringName] = []

## 激活必需标签
## 如果 ASC 上不存在这些标签，将阻止技能激活
## 例如：Stance.Stealth（潜行）才能使用某些技能
@export var activation_required_tags: Array[StringName] = []

@export_category("Ability Mechanics")
## ============================================================================
## 技能机制
## ============================================================================

## 消耗效果
## 提交时应用到拥有者的游戏效果，用于扣除资源（如魔法值）
@export var cost_effect: GameplayEffect

## 冷却效果
## 提交时应用到拥有者的游戏效果，用于触发冷却
@export var cooldown_effect: GameplayEffect

## 共享冷却效果
## 施放时应附加的任何额外共享效果（如全局冷却 GCD）
@export var shared_cooldown_effects: Array[GameplayEffect] = []

## 共享冷却标签
## 显式列出此技能应遵守的任何共享冷却（如 GCD）
@export var shared_cooldown_tags: Array[StringName] = []

@export_category("Ability Triggers")
## ============================================================================
## 技能触发
## ============================================================================

## 触发事件标签
## 如果设置，当 ASC 收到此精确事件标签时，将自动尝试激活此技能
## 用于被动技能：技能响应游戏事件自动触发
@export var trigger_event_tag: StringName = ""

@export_category("Input Routing")
## ============================================================================
## 输入路由
## ============================================================================

## 输入 ID
## 技能当前绑定的整数输入 ID，-1 表示未绑定
## 通常由 UI 操作栏调用 ASC.bind_ability_to_input() 自动处理
@export var input_id: int = -1

## ============================================================================
## 状态变量
## ============================================================================

## 当前事件负载
## 如果技能通过事件触发，临时保存负载
## 可以是 GameplayEffectSpec、Dictionary 或 Godot Node！
var current_event_payload: Variant

## 拥有者 ASC
## 拥有此技能的 AbilitySystemComponent 引用
var owner_asc: AbilitySystemComponent

## 是否激活
## 跟踪技能是否正在执行
var is_active: bool = false


#region Initialization
## ============================================================================
## 初始化
## ============================================================================

## 节点首次进入场景树时调用
## 自动将技能注册到父节点 ASC
func _ready() -> void:
	if not owner_asc:
		var parent = get_parent()
		if parent is AbilitySystemComponent:
			parent.grant_ability(self)
#endregion


#region Execution & State
## ============================================================================
## 执行与状态
## ============================================================================

## 尝试激活技能
##
## 公开入口点，如果通过事件触发则接受可选负载
##
## 流程：
## 1. 检查是否可激活（门神检查）
## 2. 设置 is_active = true
## 3. 执行 _activate_ability()
## 4. 保证调用 end_ability()
##
## @param event_payload - 可选的事件负载
## @return - 激活成功返回 true
func try_activate(event_payload: Variant = null) -> bool:
	## 检查技能是否已在执行或没有拥有者
	if is_active or not owner_asc:
		return false

	## 门神检查：ASC 验证激活条件
	if not owner_asc.can_activate_ability(self, true):
		return false

	## 设置状态
	is_active = true
	current_event_payload = event_payload # 保存负载供逻辑使用

	## 逻辑执行
	var success = await _activate_ability()

	## 保证清理
	if is_active:
		end_ability(not success)

	current_event_payload = null # 清除以防止内存泄漏
	return success


## 提交技能
##
## 安全的辅助方法，同时精确扣除资源并应用冷却
## 开发者在 _activate_ability() 中应尽快手动调用此方法
func commit_ability() -> void:
	## 应用消耗效果
	if cost_effect:
		owner_asc.apply_gameplay_effect(cost_effect, owner_asc, ability_level)

	## 应用冷却效果
	if cooldown_effect:
		owner_asc.apply_gameplay_effect(cooldown_effect, owner_asc, ability_level)

	## 应用共享冷却效果
	for shared_effect in shared_cooldown_effects:
		if shared_effect:
			owner_asc.apply_gameplay_effect(shared_effect, owner_asc, ability_level)


## 激活技能（虚函数）
##
## 内部虚方法，在具体技能脚本中重写
## 实现具体的技能逻辑
##
## 示例流程：
## commit_ability()
## await play_animation()
## apply_effect_to_targets(...)
func _activate_ability() -> bool:
	return true


## 中止技能
##
## 强制中断正在施放的技能
## 用于：被眩晕、打断等
func abort_ability() -> void:
	if is_active:
		print("GAS: Ability %s was forcefully aborted." % ability_tag)
		end_ability(true)


## 结束技能
##
## 清理技能状态
## 注意：不会从 ASC 移除技能，否则技能将被永久取消授予
##
## @param was_cancelled - 是否因取消而结束
func end_ability(was_cancelled: bool = false) -> void:
	is_active = false
	## 故意不从 ASC 移除技能，否则它将被永久取消授予

	ability_ended.emit(was_cancelled)
#endregion


#region Helper Methods
## ============================================================================
## 辅助方法
## ============================================================================

## 执行 Cue
##
## 通过 ASC 触发多个视觉/音频 Cue
## @param tag - Cue 标签
func execute_cue(tag: StringName) -> void:
	if owner_asc:
		owner_asc.execute_cue(tag)


## 应用效果到目标
##
## 重要的便捷辅助方法：接收目标数据，创建 Context，将效果包装为 Spec，
## 然后应用到每个目标的 ASC
##
## 自动化处理：
## 1. 创建 GameplayEffectContext
## 2. 创建 GameplayEffectSpec
## 3. 遍历目标应用效果
##
## @param effect_res - 游戏效果资源
## @param target_data - 目标数据
func apply_effect_to_targets(effect_res: GameplayEffect, target_data: GameplayAbilityTargetData) -> void:
	if not effect_res or not target_data:
		return

	## 发起者和施加者都默认为持久的父实体（如玩家）
	## 不要传递 self（瞬态技能）作为施加者
	var persistent_avatar = owner_asc.get_parent()
	var context = GameplayEffectContext.new(persistent_avatar, persistent_avatar)

	context.target_data = target_data
	var spec = GameplayEffectSpec.new(effect_res, context, ability_level)

	var targets = target_data.get_target_nodes()
	for target in targets:
		var target_asc = _find_asc_on_node(target)
		if target_asc:
			owner_asc.apply_effect_spec_to_target(spec, target_asc)


## 查找 ASC
##
## 在给定节点或其直接子节点上搜索 ASC
## @param node - 要搜索的节点
## @return - 找到的 ASC 或 null
func _find_asc_on_node(node: Node) -> AbilitySystemComponent:
	if node is AbilitySystemComponent:
		return node

	for child in node.get_children():
		if child is AbilitySystemComponent:
			return child

	return null


## 获取冷却标签
##
## 返回代表此技能所有冷却的标签
## 包括：个人冷却 + 设计师显式分配的共享冷却
##
## @return - 冷却标签数组
func get_cooldown_tags() -> Array[StringName]:
	var cooldown_tags: Array[StringName] = []

	## 1. 从分配的冷却资源直接获取授予的标签
	if cooldown_effect != null:
		cooldown_tags.append_array(cooldown_effect.granted_tags)

	## 2. 自动从应用的共享效果中获取标签（如 GCD）
	for effect in shared_cooldown_effects:
		if effect != null:
			cooldown_tags.append_array(effect.granted_tags)

	## 3. 获取显式共享冷却标签
	cooldown_tags.append_array(shared_cooldown_tags)

	return cooldown_tags
#endregion


#region Input Routing
## ============================================================================
## 输入路由
## ============================================================================

## 输入按下
##
## 当分配的 input_id 被按下时由 ASC 触发的虚函数
## @param asc - ASC 实例
func _input_pressed(asc: AbilitySystemComponent) -> void:
	if is_active:
		## 如果已在施放/引导中，路由到活跃输入处理
		_active_input_pressed(asc)
		return

	## 启动强大的激活流程（try_activate 处理门神、状态和清理）
	try_activate()


## 输入释放
##
## 当分配的 input_id 被释放时由 ASC 触发的虚函数
## @param asc - ASC 实例
func _input_released(asc: AbilitySystemComponent) -> void:
	if is_active:
		_active_input_released(asc)


## 技能激活时按下输入
##
## 技能的输入被按下，但技能已经处于激活状态
## 重写此方法实现如'再次按下取消'或'再次按下引爆'的机制
## @param asc - ASC 实例
func _active_input_pressed(asc: AbilitySystemComponent) -> void:
	pass


## 技能激活时释放输入
##
## 技能的输入被释放，但技能已经处于激活状态
## 重写此方法实现'按住蓄力，松手发射'的机制
## @param asc - ASC 实例
func _active_input_released(asc: AbilitySystemComponent) -> void:
	pass
#endregion

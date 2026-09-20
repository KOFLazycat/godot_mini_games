## GameplayAbilityTargetData - 技能目标数据
##
## 功能说明：
## 封装技能执行过程中收集的目标信息
## 存储命中结果和唯一的目标节点，提供标准化的数据负载
## 可以安全地传递给 GameplayEffects
##
## 数据结构：
## - _target_nodes: 去重后的唯一目标节点数组
## - _hit_results: 原始命中字典数组（支持多段命中）
##
## 使用场景：
## - 射线检测命中目标
## - 区域检测（AOE技能）
## - 自动瞄准
## - 多段伤害计算
##
## @meta_addon: GodotGAS Version 1 (See plugin version for exact version)
## @meta_author: YulRun (https://YulRun.Dev)
## @meta_license: MIT

@icon("res://addons/GodotGAS/icons/godot_gas_asc.svg")
class_name GameplayAbilityTargetData extends RefCounted

## ============================================================================
## 核心属性
## ============================================================================

## 唯一目标节点数组
## 存储技能命中的所有唯一目标节点（自动去重）
## 同一个节点多次命中只保留一次
## 用于：应用效果到每个目标
var _target_nodes: Array[Node] = []

## 原始命中结果数组
## 存储所有原始物理碰撞字典
## 允许追踪多段命中（如多发子弹连续命中同一目标）
## 用于：精确伤害计算、多段伤害
var _hit_results: Array[Dictionary] = []


#region Appenders
## ============================================================================
## 添加方法
## ============================================================================

## 添加物理碰撞结果
##
## 用途：添加射线检测或形状检测的物理碰撞结果
## 自动从碰撞字典中提取目标节点并去重
##
## @param hit_dict - Godot 物理查询返回的字典（包含 collider, position, normal 等）
func append_physics_hit(hit_dict: Dictionary) -> void:
	## 添加原始命中结果
	_hit_results.append(hit_dict)

	## 提取碰撞体并去重
	var collider: Node = hit_dict.get("collider")
	if collider and not _target_nodes.has(collider):
		_target_nodes.append(collider)


## 添加目标节点
##
## 用途：直接添加目标节点（适合 ShapeCast、自动瞄准、UI 选择等场景）
## 自动生成模拟的命中字典以保持数据结构一致
##
## @param node - 目标节点
## @param hit_position - 命中位置（可选，默认使用节点的 global_position）
func append_node(node: Node, hit_position: Variant = null) -> void:
	if not node:
		return

	## 添加到去重数组
	if not _target_nodes.has(node):
		_target_nodes.append(node)

	## 确定使用的位置
	var pos_to_use: Variant = hit_position
	if pos_to_use == null and "global_position" in node:
		## 使用节点的全局位置
		pos_to_use = node.global_position
	elif pos_to_use == null:
		## 对于非空间节点，使用零向量作为后备
		pos_to_use = Vector3.ZERO

	## 生成模拟的命中字典以保持数据结构一致
	var mock_hit: Dictionary = {
		"collider": node,
		"position": pos_to_use,
		"normal": Vector3.ZERO
	}
	_hit_results.append(mock_hit)


## 添加重叠区域节点
##
## 用途：批量添加 Area2D/Area3D 检测到的重叠节点
## 便利方法，自动处理数组遍历
##
## @param nodes - 节点数组（通常来自 Area.get_overlapping_bodies()）
func append_overlap(nodes: Array) -> void:
	for node in nodes:
		append_node(node)
#endregion


#region Getters
## ============================================================================
## 获取方法
## ============================================================================

## 获取唯一目标节点列表
##
## 用途：获取所有去重后的目标节点
## @return - 目标节点数组
func get_target_nodes() -> Array[Node]:
	return _target_nodes


## 获取所有命中结果
##
## 用途：获取所有原始命中字典（支持AOE多段伤害）
## @return - 命中字典数组
func get_all_hits() -> Array[Dictionary]:
	return _hit_results


## 获取指定节点的所有命中
##
## 用途：获取与特定节点相关的所有命中字典
## 用于精确计算（如：判断子弹是否击中头部形状）
##
## @param node - 目标节点
## @return - 该节点的所有命中字典数组
func get_hits_for_node(node: Node) -> Array[Dictionary]:
	var specific_hits: Array[Dictionary] = []
	for hit in _hit_results:
		if hit.get("collider") == node:
			specific_hits.append(hit)

	return specific_hits


## 强制移除目标
##
## 用途：强制从负载追踪中移除指定节点
## 非常适合引导技能/Area技能 - 当目标离开检测区域时调用
##
## 实现逻辑：
## 1. 从唯一目标数组中移除
## 2. 从原始命中数组中逆向迭代移除（防止索引偏移）
##
## @param node - 要移除的目标节点
func force_remove_target(node: Node) -> void:
	## 1. 清除唯一目标追踪
	_target_nodes.erase(node)

	## 2. 清除原始命中字典（逆向迭代防止索引偏移）
	for i in range(_hit_results.size() - 1, -1, -1):
		if _hit_results[i].get("collider") == node:
			_hit_results.remove_at(i)


## 清空所有数据
##
## 用途：清除所有目标数据和命中结果
func clear() -> void:
	_target_nodes.clear()
	_hit_results.clear()
#endregion

## GameplayTagRegistry - 游戏标签注册表
##
## 功能说明：
## 项目中所有已注册游戏标签的主列表
## 存储为序列化的 StringName 数组以优化内存和比较
## 入口时自动格式化和验证标签
##
## 使用场景：
## - 管理所有游戏标签（如 Status.Stunned、Ability.Fireball）
## - 标签分类：Status、Ability、Event、Combat 等
## - 标签验证和自动格式化
##
## 标签格式：
## - 必须使用字母数字字符和点号分隔
## - 自动格式化：test.test → Test.Test
## - 示例：Status.Stunned、Ability.Fireball、Event.Damage.Taken
##
## @meta_addon: GodotGAS Version 1 (See plugin version for exact version)
## @meta_author: YulRun (https://YulRun.Dev)
## @meta_license: MIT

@tool
@icon("res://addons/GodotGAS/icons/godot_gas_asc.svg")
class_name GameplayTagRegistry extends Resource

## ============================================================================
## 核心属性
## ============================================================================

## 标签列表
## 项目中所有已注册标签的主列表
## 存储为 StringName 数组以优化内存和比较
@export var tags: Array[StringName] = []


#region Tag Management
## ============================================================================
## 标签管理
## ============================================================================

## 添加标签
##
## 尝试添加新标签，自动格式化大小写后检查有效性
## 成功返回格式化的标签，失败返回以 "Error:" 开头的字符串
##
## 格式化规则：
## 1. 自动格式化：test.test → Test.Test
## 2. 正则验证：必须使用字母数字字符和点号
## 3. 重复检查：不允许重复标签
##
## @param tag_string - 要添加的标签字符串
## @return - 格式化后的标签，或错误信息
func add_tag(tag_string: String) -> String:
	## 去除首尾空白
	var clean_tag = tag_string.strip_edges()

	## 检查是否为空
	if clean_tag.is_empty():
		return "Error: Cannot add an empty tag."

	## 1. 自动格式化（如 test.test → Test.Test）
	var parts = clean_tag.split(".")
	var formatted_parts: Array[String] = []

	for part in parts:
		if part.is_empty():
			formatted_parts.append("") # 让正则表达式捕获双点号
		else:
			var p = part.to_lower()
			## 只将第一个字母大写，其余小写
			var formatted_part = p.substr(0, 1).to_upper() + p.substr(1)
			formatted_parts.append(formatted_part)

	var formatted_tag = ".".join(formatted_parts)

	## 2. 正则验证
	var regex = RegEx.new()
	regex.compile("^([A-Z][a-zA-Z0-9]*)(\\.[A-Z][a-zA-Z0-9]*)*$")

	if not regex.search(formatted_tag):
		return "Error: Invalid format '%s'. Must use alphanumeric characters and dots." % formatted_tag

	var new_tag := StringName(formatted_tag)

	## 3. 重复检查（使用新格式化的字符串）
	if has_tag(new_tag):
		return "Error: Tag '%s' already exists." % formatted_tag

	tags.append(new_tag)
	## 按字母顺序排序
	tags.sort_custom(func(a, b): return String(a) < String(b))

	emit_changed()
	## 生成标签文件
	GameplayTagGenerator.generate_tags_file(tags)

	if not resource_path.is_empty():
		ResourceSaver.save(self, resource_path)

	return formatted_tag


## 移除标签
##
## 从注册表中移除精确匹配的标签
##
## @param tag_name - 要移除的标签名称
func remove_tag(tag_name: StringName) -> void:
	if has_tag(tag_name):
		tags.erase(tag_name)
		emit_changed()
		GameplayTagGenerator.generate_tags_file(tags)

		if not resource_path.is_empty():
			ResourceSaver.save(self, resource_path)
#endregion


#region Tag Queries
## ============================================================================
## 标签查询
## ============================================================================

## 检查标签是否存在
##
## 检查精确标签是否存在于注册表中
## @param tag_name - 要检查的标签名称
## @return - 存在返回 true
func has_tag(tag_name: StringName) -> bool:
	return tags.has(tag_name)


## 获取子标签
##
## 返回特定父标签下的所有子标签
## 例如：get_child_tags("Status") 可能返回 ["Status.Stunned", "Status.Burning"]
##
## @param parent_tag - 父标签
## @return - 子标签数组
func get_child_tags(parent_tag: StringName) -> Array[StringName]:
	var children: Array[StringName] = []
	var prefix = String(parent_tag) + "."

	for tag in tags:
		if String(tag).begins_with(prefix):
			children.append(tag)

	return children
#endregion

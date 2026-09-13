## 投射物蓝图资源 (ProjectileBlueprint2D)
##
## 概述：
## 这是一个 Godot Resource 类型的资源文件，用于在编辑器中配置投射物（Projectile）的各种属性。
## 投射物是游戏中常见的弹射物实体，如箭矢、子弹、魔法弹等。
## 该蓝图定义了投射物的外观、行为、伤害、碰撞等所有相关属性。
##
## 代码架构：
## 1. 继承关系：extends Resource（Godot资源系统）
## 2. 核心逻辑：
##    - 使用 @export 导出的属性，供编辑器配置
##    - _init() 构造函数设置默认值
##    - _validate_property() 验证属性，根据条件隐藏/显示编辑器中的属性
## 3. 属性分类（通过 @export_category 和 @export_group 组织）：
##    - Main Attributes：主要属性（名称、类型、纹理等）
##    - Collisions：碰撞层配置
##    - Projectile2D Type Properties：投射物类型特定属性
##    - Offensive Attributes：攻击属性（伤害、穿透）
##    - Behaviour Attributes：行为属性（朝向、追踪）
##    - Pierce Properties：穿透属性
##    - Instances：实例配置
##    - Spread：散射配置
##    - Deviation：偏差配置
##    - Custom Properties：自定义属性
##    - Secondary Projectiles：次级投射物

@tool
@icon("res://addons/all_projectiles/icons/projectile_resource_2d.svg")

class_name ProjectileBlueprint2D
extends Resource


@export_category("Main Attributes")
## [主属性] 唯一标识符
## 用于在全球数据库中区分不同的投射物
@export var name: StringName

## [主属性] 投射物子类型
## 指定该投射物将使用的具体类型（AREA 或 INSTANTIATED）
## - AREA：使用代码生成的简单投射物（如圆形精灵）
## - INSTANTIATED：从场景实例化的高级投射物
@export var proj_type: Projectile2D.ProjectileType:
	set(value):
		proj_type = value
		notify_property_list_changed()


@export_category("AREA 类型属性")
## [AREA类型] 投射物的主纹理/图形
## 投射物显示的精灵纹理（仅 AREA 类型使用）
@export var texture: Texture2D

## [AREA类型] 投射物缩放
## 应用到投射物的统一缩放值
@export var size: float = 1.0

## [AREA类型] 存活时长
## 投射物存在的时间（秒），超过后自动销毁
@export var lifetime: float = 1.0

## [AREA类型] 线性速度
## 投射物每秒移动的像素距离
@export var linear_speed: float = 1000.0

## [AREA类型] 碰撞半径
## 投射物圆形碰撞检测的半径（像素）
## 注意：实际碰撞半径会受 size 属性影响
@export var radius: int = 50


@export_group("Collisions")
## [碰撞层] 投射物所在的物理层
## 定义投射物存在于哪些物理层（用于物理碰撞检测）
## 使用 Godot 的 2D 物理层标志系统
@export_flags_2d_physics var collision_layer: int

## [碰撞层] 投射物可以交互的物理层
## 定义投射物可以与哪些物理层的对象进行碰撞检测
@export_flags_2d_physics var collision_mask: int
@export_group("")


@export_category("Projectile2D 类型属性")
## [类型属性] 碰撞时调用的方法名
## 投射物击中目标后尝试调用的目标方法
## 默认调用 "damage" 方法（如造成伤害）
@export var on_hit_call: String = "damage"

## [类型属性] 是否可被区域监控
## 如果为 true，投射物可以被其他 Area2D 监控检测
@export var area_monitoreable: bool = true


@export_group("INSTANTIATED 类型属性")
## [INSTANTIATED类型] 碰撞组件路径
## 实例化投射物场景中必需的 Area2D 子节点的路径
## 用于获取碰撞检测组件
@export var collision_path: String = "Collision"

## [INSTANTIATED类型] 实例化场景
## 作为 INSTANTIATED 类型实例化的场景资源
@export var instance: PackedScene
@export_group("")


@export_category("攻击属性")
## [攻击属性] 伤害值
## 投射物击中目标时扣除的生命值总和
@export var damage: int = 1

## [攻击属性] 穿透数量
## 投射物在过期前可以击中的不同目标数量
## 1 = 击中一个目标后消失
## >1 = 可以穿透多个目标
@export var pierce: int = 1


@export_category("行为属性")
## [行为属性] 是否朝向移动方向
## 如果为 true，投射物会主动旋转以面向它移动的方向
@export var look_at: bool = true


@export_group("追踪行为")
## [追踪行为] 是否启用追踪
## 如果为 true，投射物会主动追踪指定的目标
@export var seeking: bool = false

## [追踪行为] 追踪目标的物理层
## 投射物可以追踪的目标所在的物理层
## 用于避免追踪墙壁等障碍物
@export_flags_2d_physics var seeking_mask: int

## [追踪行为] 角速度
## 追踪时每秒允许的最大旋转角度（度）
## 控制投射物转向的灵活度
@export var angular_speed: float = 100

## [追踪行为] 命中后角速度
## 第一次命中后使用的角速度
## 用于实现反弹行为等
@export var after_hit_angular_speed: float = 100

## [追踪行为] 搜索半径
## 追踪投射物搜索次级目标的圆形搜索半径
@export var cast_radius: float = 200.0
@export_group("")


@export_group("穿透属性")
## [穿透属性] 锁定目标
## 如果为 true，投射物会忽略路径上的所有潜在碰撞，只击中指定目标
@export var lock_to_target: bool

## [穿透属性] 允许重复击中
## 如果为 true，投射物可以击中已击中的目标
@export var allow_rehit: bool

## [穿透属性] 重复击中冷却
## 同一目标被连续击中之间的最小时间间隔（秒）
## 防止投射物在单次碰撞中造成过多伤害
@export var rehit_cooldown: float = 0.1
@export_group("")


@export_category("实例配置")
## [实例] 投射物实例数量
## 创建时生成的数量（用于散射/多发投射）
@export var instances: int = 1:
	set(value):
		instances = value
		notify_property_list_changed()

## [实例] 生成间隔
## 每个实例生成之间的时间间隔（秒）
## 用于实现连续发射效果
@export var spawn_interval: float

## [实例] 方向类型
## 投射物实例化后的方向模式
## - FIXED：固定方向
## - MODIFIABLE：可修改方向
## - TOWARD_SOURCE：朝向发射源
@export var proj_directionality: Projectile2D.ProjectileDirectionality = Projectile2D.ProjectileDirectionality.MODIFIABLE


@export_group("散射配置")
## [散射] 散射类型
## 投射物实例的散射分布方式
## - NONE：无散射
## - ANGULAR：角度散射（扇形分布）
## - LINEAR：线性散射（直线分布）
## - CIRCULAR：圆形散射（环形分布）
@export var proj_spread: Projectile2D.ProjectileSpread = Projectile2D.ProjectileSpread.NONE :
	set(value):
		proj_spread = value
		notify_property_list_changed()

## [散射] 角度散射范围
## 角度散射时均匀分布的角度范围（度）
@export var angular_spread: float

## [散射] 线性散射范围
## 线性散射时均匀分布的距离（像素）
@export var vertical_spread: float

## [散射] 随机化位置
## 如果为 true，线性/角度散射的位置将随机分布
@export var randomize_positions: bool

## [散射] 随机化散射边界
## 如果为 true，角度和圆形散射将仅在边缘之间随机化
@export var randomize_spread: bool
@export_group("")


@export_group("偏差配置")
## [偏差] 线性偏差
## 投射物速度向量随机偏差量（像素）
## 为投射物添加��机性
@export var linear_deviation: float
@export_group("")


@export_category("自定义属性")
## [自定义] 全局属性字典
## 所有由此蓝图创建的投射物共享此字典
## 修改任何一个投射物的值会影响所有其他投射物
@export var global_properties: Dictionary[StringName, Variant]

## [自定义] 个体属性字典
## 每个投射物独立的属性字典
## 修改只影响目标投射物
@export var individual_properties: Dictionary[StringName, Variant]


@export_category("次级投射物")
## [次级投射物] 过期投射物ID
## 主投射物用完穿透次数或过期时生成次级投射物的全局数据库ID
## 用于实现箭矢碎片、爆炸效果等
@export var on_expired_projectile_id: StringName




## ============================================================
## 构造函数和验证方法
## ============================================================


func _init() -> void:
	"""
	构造函数
	初始化所有属性的默认值
	"""
	# 主属性默认值
	proj_type = Projectile2D.ProjectileType.AREA
	texture = null
	size = 1.0
	lifetime = 1.0
	linear_speed = 1000
	radius = 20

	# 碰撞默认值
	collision_layer = 0
	collision_mask = 0

	# 类型属性默认值
	area_monitoreable = true
	collision_path = "Collision"
	on_hit_call = "damage"

	# 攻击属性默认值
	damage = 1
	pierce = 1

	# 行为属性默认值
	look_at = true

	# 追踪行为默认值
	seeking = false
	seeking_mask = 0
	angular_speed = 100
	after_hit_angular_speed = 100
	cast_radius = 200

	# 穿透属性默认值
	lock_to_target = false
	allow_rehit = false
	rehit_cooldown = 0.1

	# 实例配置默认值
	instances = 1
	spawn_interval = 0
	proj_directionality = Projectile2D.ProjectileDirectionality.MODIFIABLE
	proj_spread = Projectile2D.ProjectileSpread.NONE

	# 散射配置默认值
	angular_spread = 0
	vertical_spread = 0
	randomize_positions = false
	randomize_spread = false
	linear_deviation = 0

	# 自定义属性默认值
	global_properties = {}
	individual_properties = {}

	# 次级投射物默认值
	on_expired_projectile_id = ""


func _validate_property(property: Dictionary) -> void:
	"""
	属性验证器
	根据当前配置条件，隐藏不适用的编辑器属性
	使编辑器界面更清晰，只显示相关属性
	"""
	# 如果实例数 < 2，隐藏与多实例相关的属性
	if property.name in ["spawn_interval", "proj_spread", "angular_spread", "vertical_spread", "randomize_positions", "randomize_spread"] && (instances < 2):
		property.usage = PROPERTY_USAGE_NO_EDITOR

	# 如果不是角度散射，隐藏角度散射属性
	if (property.name == "angular_spread") && (proj_spread != Projectile2D.ProjectileSpread.ANGULAR):
		property.usage = PROPERTY_USAGE_NO_EDITOR

	# 如果不是角度/圆形散射，隐藏随机化散射属性
	if (property.name == "randomize_spread") && (proj_spread != Projectile2D.ProjectileSpread.ANGULAR && proj_spread != Projectile2D.ProjectileSpread.CIRCULAR):
		property.usage = PROPERTY_USAGE_NO_EDITOR

	# 如果不是角度/线性散射，隐藏线性散射相关属性
	if property.name in ["vertical_spread", "randomize_positions"] && (proj_spread != Projectile2D.ProjectileSpread.ANGULAR && proj_spread != Projectile2D.ProjectileSpread.LINEAR):
		property.usage = PROPERTY_USAGE_NO_EDITOR

	# 如果是实例化类型，隐藏 AREA 类型专用属性
	if property.name in ["texture", "size", "radius"] && (proj_type == Projectile2D.ProjectileType.INSTANTIATED):
		property.usage = PROPERTY_USAGE_NO_EDITOR

	# 如果不是实例化类���，���藏实例化专用属性
	if property.name in ["instance", "collision_path"] && (proj_type != Projectile2D.ProjectileType.INSTANTIATED):
		property.usage = PROPERTY_USAGE_NO_EDITOR

# ==============================================================================
# 脚本名称：SmoothFollowTrail.gd
# 继承节点：Line2D（Godot4 内置2D线段绘制节点）
# 核心功能：实现平滑跟随指定2D节点的拖尾效果（如弹道轨迹、角色残影、技能轨迹等）
# 优化亮点：提升健壮性、性能、可配置性，添加完整注释，避免无效报错
# ==============================================================================
class_name SmoothFollowTrail
extends Line2D

# ==============================================================================
# 导出变量（编辑器可配置，无需修改代码）
# ==============================================================================
## 拖尾需要跟随的目标节点（支持Sprite2D/CharacterBody2D等所有Node2D子类）
@export var followNode: Node2D = null
## 拖尾分段点总数（分段越多拖尾越平滑，最小值限制为2，默认16）
@export var pointsCount: int = 16 : set = setPointsCount
## 插值平滑速度（系数越大，拖尾越紧凑；系数越小，拖尾越松散/残影越明显，默认40.0）
@export var interpolationSpeed: float = 40.0
## 拖尾启用开关（可快速暂停/启用拖尾效果，默认启用）
@export var debugMode: bool = false
## 拖尾启用开关（可快速暂停/启用拖尾效果，默认启用）
@export var isEnabled: bool = true

# ==============================================================================
# 成员变量（内部缓存/逻辑变量，不暴露给编辑器）
# ==============================================================================
## 局部点缓存数组（高效存储拖尾所有分段点的全局位置，优于普通Array<Vector2>）
var pointsLocal: PackedVector2Array = []
## 上一帧目标节点位置（用于判断目标是否移动，避免无效计算，优化性能）
var lastTargetPos: Vector2 = Vector2.ZERO

# ==============================================================================
# 自定义Setter函数：同步更新分段点总数与缓存数组
# 触发时机：编辑器修改pointsCount / 代码直接赋值pointsCount时自动调用
# ==============================================================================
func setPointsCount(value: int) -> void:
	# 安全校验：确保分段点总数不小于2（至少2个点才能形成线段，避免无效值）
	var safeValue: int = max(value, 2)
	# 更新分段点总数
	pointsCount = safeValue
	# 调整缓存数组长度，与分段点总数一致
	pointsLocal.resize(safeValue)
	# 初始化数组所有元素为原点坐标，避免无效未定义值
	if followNode:
		pointsLocal.fill(followNode.global_position)

# ==============================================================================
# 生命周期函数：节点首次进入场景树时执行（仅执行一次，初始化逻辑）
# ==============================================================================
func _ready() -> void:
	# 兜底逻辑：若未在编辑器指定跟随目标，自动绑定到当前节点的父节点
	if followNode == null:
		followNode = owner
		if debugMode:
			Debug.printWarning("%s: 未指定跟随目标，自动绑定到父节点: %s" % [self.name, owner.name], self)
	
	# 初始化分段点缓存数组（确保与配置的pointsCount一致）
	setPointsCount(pointsCount)
	
	# 设置节点为顶级节点：全局位置不受父节点的位置/旋转/缩放变换影响，跟随更稳定
	top_level = true
	
	# 初始化上一帧目标位置
	if is_instance_valid(followNode):
		lastTargetPos = followNode.global_position

# ==============================================================================
# 物理帧更新函数：按物理帧率执行（默认60fps，与游戏物理逻辑同步）
# delta：上一帧到当前帧的时间间隔（秒），用于实现帧率无关计算
# ==============================================================================
func _physics_process(delta: float) -> void:
	# 若拖尾未启用，直接返回，减少无效计算
	if not isEnabled:
		return
	
	# 安全校验：判断跟随目标是否有效（避免目标节点被销毁后报错）
	if not is_instance_valid(followNode):
		if debugMode:
			Debug.printWarning("%s: 跟随目标节点无效（已销毁或未绑定），拖尾停止更新" % [self.name], self)
		isEnabled = false
		return
	
	# 获取目标节点当前全局位置
	var currentTargetPos: Vector2 = followNode.global_position
	
	# 性能优化：若目标节点未移动，跳过后续插值计算，直接返回
	if currentTargetPos == lastTargetPos:
		return
	
	# 1. 更新拖尾起点（第0个点）：始终紧贴目标节点当前位置
	pointsLocal[0] = currentTargetPos
	
	# 2. 遍历更新后续所有分段点：通过线性插值实现平滑跟随（链式反应）
	for index: int in range(1, pointsCount):
		# 获取前一个点的当前位置（作为插值起点）
		var prev_point: Vector2 = pointsLocal[index - 1]
		# 获取当前点的上一帧位置（作为插值终点）
		var current_point: Vector2 = pointsLocal[index]
		# 计算插值权重：帧率无关（插值速度 * 时间间隔）
		var lerp_weight: float = clamp(interpolationSpeed * delta, 0.0, 1.0)
		# 线性插值：让当前点向其前一个点平滑移动，形成自然拖尾
		pointsLocal[index] = lerp(prev_point, current_point, lerp_weight)
	
	# 3. 更新Line2D的绘制点数组：触发线段重绘，显示最新拖尾效果
	points = pointsLocal
	
	# 4. 更新上一帧目标位置：用于下一帧判断目标是否移动
	lastTargetPos = currentTargetPos

## 处理跳跃功能。当 [InputComponent] 接收到跳跃事件时应用速度。
## 跳跃方向由 [member CharacterBody2D.up_direction] 决定（仅 Y 轴）。
## 注意：空中重力和摩擦力由 [PlatformerPhysicsComponent] 处理。
## 提示：修改各时间持续时长，启用 "Editable Children" 并编辑 [Timers] 节点。
## 提示：对于"反转重力"跳跃，修改 [CharacterBodyComponent] 上的 [member CharacterBody2D.up_direction]。
## 提示：对于攀爬梯子/绳索等，使用 [ClimbComponent]
## 提示：对于动画，参见 [PlatformerAnimationComponent]
## 依赖：必须在 [PlatformerPhysicsComponent]、[CharacterBodyComponent] 和 [InputComponent] 之前

class_name PlatformerJumpComponent
extends CharacterBodyDependentComponentBase

# 感谢：https://github.com/uheartbeast — https://github.com/uheartbeast/Heart-Platformer-Godot-4 — https://youtu.be/M8-JVjtJlIQ
# 待定：是否也应尊重 CharacterBody2D.up_direction.x 轴？
# 待定：更可靠的短按跳跃处理方式？使用计时器？

# 速度与反转重力说明
# 屏幕上下落：velocity.y = +正数
# 屏幕上跳跃上升：velocity.y = -负数
# 反转重力：屏幕上向上落：velocity.y = -正数
# 反转重力：屏幕向下跳：velocity.y = +正数


#region Parameters 参数区域

## 跳跃参数配置，包含跳跃速度、最大跳跃次数等
@export var parameters: PlatformerJumpParameters = PlatformerJumpParameters.new()

## 是否启用跳跃功能
@export var isEnabled:  bool = true

#endregion


#region State 状态区域

## 输入缓冲计时器 - 允许玩家在落地前几毫秒按下跳跃键
## 用于改善游戏手感，补偿视觉/反应延迟
## 玩家可以在落地前提前按下跳跃，当落地时自动起跳
@onready var inputBufferTimer:	Timer = $InputBufferTimer

## 土狼时间计时器 - 玩家走出平台后仍可跳跃的宽限期
## 用于改善游戏手感，玩家刚走出平台边缘时仍可起跳
## 这是一种游戏设计技巧，让平台跳跃手感更好
@onready var coyoteJumpTimer:	Timer = $CoyoteJumpTimer

## 墙壁跳跃计时器 - 玩家离开墙壁后的可跳跃时间窗口
## 玩家从墙壁跳开后，在一段时间内仍可再次起跳
@onready var wallJumpTimer:		Timer = $WallJumpTimer

## 跳跃状态枚举
enum State { idle, jump }

## 当前状态
var currentState: State

## 缓存跳跃输入状态，避免每帧重复查询 Input
## 使用 setter 自动计算 justPressed 和 justReleased
var jumpInput:				bool:
	set(newValue):
		if newValue != jumpInput:
			if debugMode: Debug.printChange("jumpInput", jumpInput, newValue)
			# 从 jumpInput 派生出相关标志，允许 AI/脚本输入
			# 因为 Input.is_action_just_pressed()/released() 不受 InputComponent.generateEvent() 影响
			jumpInputJustPressed  = not jumpInput and newValue # false → true?
			jumpInputJustReleased = jumpInput and not newValue # true → false?
			jumpInput = newValue

## 跳跃键刚刚按下（按下的一瞬间为 true）
var jumpInputJustPressed:	bool:
	set(newValue):
		if newValue != jumpInputJustPressed:
			if debugMode: Debug.printChange("jumpInputJustPressed", jumpInputJustPressed, newValue)
			jumpInputJustPressed = newValue

## 跳跃键刚刚释放（释放的一瞬间为 true）
var jumpInputJustReleased:	bool:
	set(newValue):
		if newValue != jumpInputJustReleased:
			if debugMode: Debug.printChange("jumpInputJustReleased", jumpInputJustReleased, newValue)
			jumpInputJustReleased = newValue

## 当前已跳跃次数（用于多段跳计数）
var currentNumberOfJumps:	int:
	set(newValue):
		if newValue != currentNumberOfJumps:
			if debugMode: Debug.printChange("currentNumberOfJumps", currentNumberOfJumps, newValue)
			currentNumberOfJumps = newValue

# 检查：性能：这些计算属性和函数调用是否会影响性能？与直接在实际处理/更新方法中进行检查相比是否会变慢？

## 是否应该缓冲输入（在落地前提前按下跳跃）
## 条件：允许输入缓冲 且 未跳跃 且 不在地面 且 缓冲计时器未运行
## 允许玩家在落地前几毫秒按下跳跃，落地时自动起跳，改善手感
var shouldBufferInput: bool:
	get: return parameters.allowInputBuffer \
		and currentNumberOfJumps < 1 \
		and not characterBodyComponent.isOnFloor \
		and is_zero_approx(inputBufferTimer.time_left) \
		and not is_zero_approx(inputBufferTimer.wait_time)

## 是否可以进行地面跳跃（从地面起跳 或 通过土狼时间）
## 跳跃高度使用 jumpVelocity1stJump 或 jumpVelocity1stJumpShort
## 注意：不检查 isEnabled 或 maxNumberOfJumps > 0
var canFloorJump:	bool:
	get: return currentNumberOfJumps < 1 \
			and (characterBodyComponent.isOnFloor or canCoyoteJump)

## 是否可以执行缓冲跳跃（在空中按下跳跃，落地时自动起跳）
## 条件：允许输入缓冲 且 未跳跃 且 在地面 且 缓冲计时器正在运行
## 跳跃高度使用 jumpVelocity1stJump 或 jumpVelocity1stJumpShort
## 注意：不检查 isEnabled 或 maxNumberOfJumps > 0
var canBufferedJump: bool:
	get: return parameters.allowInputBuffer \
		and currentNumberOfJumps < 1 \
		and characterBodyComponent.isOnFloor \
		and not is_zero_approx(inputBufferTimer.time_left)

## 土狼时间是否激活（刚走出平台边缘时）
## 重要：使用前必须先检查 canFloorJump！
## 注意：不检查 isEnabled 或 canFloorJump
var canCoyoteJump:	bool:
	get: return parameters.allowCoyoteJump \
			and not is_zero_approx(coyoteJumpTimer.time_left)

## 是否可以执行空中下落跳跃（未从地面起跳，在下落过程中起跳）
## 条件：允许下落跳跃 且 未跳跃 且 不在地面 且 非土狼时间 且 正在向重力方向下落
## 跳跃高度使用 jumpVelocity1stJump 或 jumpVelocity1stJumpShort
## 注意：不检查 isEnabled 或 maxNumberOfJumps > 0
var canFallJump:		bool:
	get: return parameters.allowFallJump \
			and currentNumberOfJumps < 1 \
			and not characterBodyComponent.isOnFloor \
			and not canCoyoteJump \
			and characterBodyComponent.isFallingTowardsGravity

## 是否可以执行多段跳/二段跳（在地面起跳后在空中再次起跳）
## 条件：最大跳跃次数 > 1 且 已跳跃且 < 最大次数
## 跳跃高度使用 jumpVelocity2ndJump
## 注意：不检查 isEnabled
var canMultiJump:	bool:
	get: return parameters.maxNumberOfJumps > 1 \
			and currentNumberOfJumps > 0 \
			and currentNumberOfJumps < parameters.maxNumberOfJumps

## 是否可以进行墙壁跳跃
## 重要：还需检查 getWallJumpNormal() 确保有可用方向
## 注意：不检查 isEnabled 或 getWallJumpNormal() 或 maxNumberOfJumps > 0
var canWallJump:	bool:
	# 1: 是否允许墙壁跳跃?
	# 2: 是否还有跳跃次数?
	# 3: 是否在墙壁上且不在地面?
	# 4: 是否刚离开墙壁但仍在宽限计时器内?
	get: return parameters.allowWallJump \
			and currentNumberOfJumps < parameters.maxNumberOfJumps \
			and not body.is_on_floor() \
			and (body.is_on_wall() or not is_zero_approx(wallJumpTimer.time_left))

## 是否刚刚执行了墙壁跳跃
var didWallJump:	bool

## 跳跃类型枚举
enum JumpType {
	floorJump,    # 地面跳跃
	coyoteJump,   # 土狼时间跳跃
	fallJump,     # 空中下落跳跃
	multiJump,    # 多段跳/二段跳
	wallJump      # 墙壁跳跃
}

#endregion


#region Signals 信号区域

## 跳跃开始时触发
## 参数：jumpNumber - 当前跳跃次数（从1开始）
## 参数：jumpType - 跳跃类型，参见 [JumpType] 枚举
signal didJump(jumpNumber: int, jumpType: JumpType)

## 跳跃结束（落地）时触发
## 参数：totalJumps - 本次跳跃链的总跳跃次数
signal didLand(totalJumps: int)

## 土狼时间开始时触发
signal didEnterCoyoteJump

## 土狼时间结束时触发（未跳跃）
signal didExitCoyoteJump

## 墙壁跳跃开始时触发
signal didWallJumpStart(wallNormal: Vector2)

## 缓冲跳跃被执行时触发
signal didBufferedJump

#endregion


#region Dependencies 依赖区域

## 输入组件依赖
@onready var inputComponent: InputComponent = getCoComponent(InputComponent, true)

## 物理组件依赖（可选）
@onready var platformerPhysicsComponent: PlatformerPhysicsComponent = coComponents.get(&"PlatformerPhysicsComponent")

## 返回所需依赖组件列表
func getRequiredComponents() -> Array[Script]:
	return [CharacterBodyComponent, InputComponent]

#endregion


func _ready() -> void:
	# 初始持续时间应在场景文件中为每个 Timer 设置
	if debugMode:
		printDebug("PlatformerJumpComponent 初始化")

	# 设置初始状态为空闲
	self.currentState = State.idle

	# 连接 CharacterBodyComponent 的移动完成信号
	if characterBodyComponent:
		characterBodyComponent.didMove.connect(self.characterBodyComponent_didMove)
	else:
		printWarning("缺少 CharacterBodyComponent")

	# 连接输入组件信号
	Tools.connectSignal(inputComponent.didUpdateInputActionsList,	self.onInputComponent_didUpdateInputActionsList)
	Tools.connectSignal(inputComponent.didResyncAllInputs,			self.resyncInput)
	Tools.connectSignal(inputComponent.didClearAllInputs,			self.resyncInput)

	# 仅在调试模式下启用物理进程调试
	self.set_physics_process(debugMode)


#region Update Cycle 更新周期

## 当输入组件更新输入动作列表时调用
## 处理跳跃输入的核心逻辑
func onInputComponent_didUpdateInputActionsList(event: InputEvent) -> void:
	# 检查是否启用、是否是跳跃动作、是否允许跳跃
	if not isEnabled \
	or not event.is_action(GlobalInput.Actions.jump) \
	or parameters.maxNumberOfJumps < 1:
		return

	# 缓存输入状态，防止处理过程中状态变化
	# AI 组件和演示脚本可能生成合成 InputEvent
	self.jumpInput = inputComponent.inputActionsPressed.has(GlobalInput.Actions.jump)

	# jumpInputJustPressed 和 jumpInputJustReleased 由 jumpInput 的 setter 自动设置
	# 这允许通过 InputComponent.generateEvent() 进行 AI/脚本输入

	if debugMode:
		printDebug(str("跳跃输入: ", jumpInput, \
			", 刚按下: ", jumpInputJustPressed, \
			", 刚释放: ", jumpInputJustReleased, \
			", 应缓冲: ", shouldBufferInput, \
			", 速度Y: ", body.velocity.y))

	# 处理墙壁跳跃（优先）
	processWallJump()

	# 如果没有执行墙壁跳跃，处理普通跳跃
	if not didWallJump:
		processJump()
		# 如果没有跳跃且允许输入缓冲，则缓冲输入
		if jumpInputJustPressed and shouldBufferInput:
			inputBufferTimer.start()


## 当输入组件清除或重新同步所有输入时重置输入状态
func resyncInput() -> void:
	self.jumpInput = isEnabled and parameters.maxNumberOfJumps >= 1 and inputComponent.inputActionsPressed.has(GlobalInput.Actions.jump)
	clearInput()


## 在 CharacterBody2D.move_and_slide 位置更新后执行
## 处理落地后的状态更新和缓冲跳跃
func characterBodyComponent_didMove(_delta: float) -> void:
	printDebug("characterBodyComponent_didMove()")

	# 记录是否刚刚落地（用于发射落地信号）
	var justLanded: bool = false
	var previousJumpCount: int = currentNumberOfJumps

	# 如果曾在墙壁上，停止墙壁跳跃计时器
	if characterBodyComponent.wasOnWall:
		wallJumpTimer.stop()

	# 检测是否刚刚落地（从跳跃状态变为在地面）
	if currentNumberOfJumps > 0 and characterBodyComponent.isOnFloor:
		justLanded = true

	# 重置状态
	resetState()
	# 更新土狼时间状态
	updateCoyoteJumpState()
	# 更新墙壁跳跃状态
	updateWallJumpState()

	# 如果可以执行缓冲跳跃，则执行跳跃
	if canBufferedJump:
		didBufferedJump.emit()
		jump(JumpType.floorJump)

	# 发射落地信号
	if justLanded and previousJumpCount > 0:
		didLand.emit(previousJumpCount)

	if debugMode:
		showDebugInfo()

	# 清除输入状态
	clearInput()


## 重置跳跃状态
## 当角色在地面时，重置跳跃次数计数器和土狼时间计时器
## 注意：必须在处理输入和 move_and_slide 之后调用
func resetState() -> void:
	if currentNumberOfJumps != 0 and characterBodyComponent.isOnFloor:
		currentNumberOfJumps = 0
		coyoteJumpTimer.stop()
		currentState = State.idle
		printDebug("跳跃次数已重置")


## 清除输入状态
func clearInput() -> void:
	jumpInputJustPressed  = false
	jumpInputJustReleased = false

#endregion


#region Normal & Mid-Air Jump 普通和空中跳跃

## 处理普通跳跃逻辑
## 包含：普通跳跃、短按跳跃（释放按键降低跳跃高度）
## 注意：不检查 isEnabled 或 maxNumberOfJumps > 0
func processJump() -> void:
	# 这些守卫条件可能在跳跃过程中禁用此函数时阻止"短跳"
	var shouldJump: bool = false
	var jumpType: JumpType = JumpType.floorJump

	# 初始跳跃或空中跳跃
	if self.jumpInputJustPressed:
		# 可以从地面跳、空中下落跳、或多段跳
		shouldJump = canFloorJump or canFallJump or canMultiJump

		# 确定跳跃类型
		if canFloorJump:
			if canCoyoteJump:
				jumpType = JumpType.coyoteJump
			else:
				jumpType = JumpType.floorJump
		elif canFallJump:
			jumpType = JumpType.fallJump
		elif canMultiJump:
			jumpType = JumpType.multiJump

		if debugMode:
			printDebug(str("尝试跳跃: shouldJump=", shouldJump, \
				", jumpType=", jumpType, \
				", canFloorJump=", canFloorJump, \
				", canFallJump=", canFallJump, \
				", canMultiJump=", canMultiJump))

	# 短按跳跃：如果在跳跃过程中释放按键，降低跳跃高度
	elif self.jumpInputJustReleased \
	and not characterBodyComponent.isOnFloor \
	and currentNumberOfJumps == 1:

		# 如果当前速度比短跳速度快，限制到短跳跃速度
		# 重要：避免在下落时触发短跳！
		# 示例：普通跳跃 -100，短跳 -50，下落时 velocity.y 为正
		# 比较时应考虑 up_direction

		if debugMode:
			Debug.printVariables([entity.name, body.velocity.y, parameters.jumpVelocity1stJumpShort * body.up_direction.y, body.up_direction.y])

		# 验证理解是否正确
		if (body.up_direction.y < 0 and body.velocity.y < parameters.jumpVelocity1stJumpShort * body.up_direction.y) \
		or (body.up_direction.y > 0 and body.velocity.y > parameters.jumpVelocity1stJumpShort * body.up_direction.y):
			# 反重力情况
			printDebug(str("短跳! 速度Y: ", body.velocity.y, " → ", parameters.jumpVelocity1stJumpShort * body.up_direction.y))
			body.velocity.y = parameters.jumpVelocity1stJumpShort * body.up_direction.y
			characterBodyComponent.shouldMoveThisFrame = true

	if shouldJump:
		jump(jumpType)


## 执行实际跳跃动作
## 在所有输入处理、计时器检查和状态验证通过后调用
## 参数：jumpType - 跳跃类型，参见 [JumpType] 枚举
func jump(jumpType: JumpType) -> void:
	var jumpNumber: int = currentNumberOfJumps + 1

	if debugMode:
		Debug.printDebug(str("执行跳跃! 跳跃次数: ", jumpNumber, ", 类型: ", jumpType))

	# 尊重 up_direction 以支持反转重力情况
	if currentNumberOfJumps <= 0:
		# 第一次跳跃
		body.velocity.y = parameters.jumpVelocity1stJump * body.up_direction.y
		printDebug(str("第一次跳跃，速度Y: ", body.velocity.y))
	else:
		# 多段跳（第二段及以后）
		body.velocity.y = parameters.jumpVelocity2ndJump * body.up_direction.y
		printDebug(str("多段跳 #", currentNumberOfJumps, "，速度Y: ", body.velocity.y))

	# 停止输入缓冲计时器（已跳跃，无需缓冲）
	inputBufferTimer.stop()
	# 停止土狼时间计时器（已起跳，土狼时间不再需要）
	coyoteJumpTimer.stop()

	# 增加跳跃次数
	currentNumberOfJumps += 1
	currentState = State.jump

	# 标记本帧需要移动
	characterBodyComponent.shouldMoveThisFrame = true

	# 发射跳跃信号
	didJump.emit(jumpNumber, jumpType)

	if debugMode:
		printDebug(str("跳跃后速度Y → ", body.velocity.y))


## 更新土狼时间状态
## 当玩家刚走出平台边缘时启动计时器，允许在一定时间内仍可起跳
## 这是一种改善游戏手感的技巧
## 注意：不检查 isEnabled 或 maxNumberOfJumps > 0
func updateCoyoteJumpState() -> void:
	# 感谢 uHeartbeast 的实现思路
	if not parameters.allowCoyoteJump:
		return

	# 是否正在下落？
	# 反重力：body.up_direction.y = +1
	# 向上下落：velocity.y = -negative * +1 = -negative
	# 向下跳跃：velocity.y = +positive * +1 = +positive
	var fallVelocity: float = body.velocity.y * body.up_direction.y

	# 检测土狼时间结束（计时器从有值变为0且没有跳跃）
	var wasInCoyoteJump: bool = not is_zero_approx(coyoteJumpTimer.time_left) or coyoteJumpTimer.is_stopped() == false

	# 条件：曾在地面、现在不在地面、正在下落或静止
	if characterBodyComponent.wasOnFloor \
		and not body.is_on_floor() \
		and (fallVelocity < 0.0 or is_zero_approx(fallVelocity)):
			if not wasInCoyoteJump:
				didEnterCoyoteJump.emit()
			coyoteJumpTimer.start()
			printDebug("土狼时间已启动")
	elif wasInCoyoteJump and currentNumberOfJumps == 0:
		# 土狼时间结束且没有跳跃
		didExitCoyoteJump.emit()

#endregion


#region Wall Jumping 墙壁跳跃

## 处理墙壁跳跃
## 在墙上时允许玩家跳离墙壁
## 注意：不检查 isEnabled
func processWallJump() -> void:
	# 感谢 uHeartbeast 的实现思路
	# isEnabled 在此处很少为 false，因为调用者应该已检查
	# 所以先检查更常变化的条件
	didWallJump = false
	if not canWallJump:
		return

	# 获取当前或最近墙壁碰撞的法线方向（如果在宽限计时器内）
	var wallNormal: Vector2 = getWallJumpNormal()
	if wallNormal.is_zero_approx():
		return

	# 执行墙壁跳跃
	if self.jumpInputJustPressed:
		# 尊重 up_direction 以支持反转重力
		body.velocity.x = wallNormal.x * parameters.wallJumpVelocityX
		body.velocity.y = parameters.wallJumpVelocity * body.up_direction.y

		printDebug(str("墙壁跳跃! 法线: ", wallNormal, ", 速度: ", body.velocity))

		# 墙壁跳跃是否消耗跳跃次数
		if parameters.decreaseJumpCountOnWallJump and currentNumberOfJumps > 0:
			currentNumberOfJumps -= 1

		# 跳过正常加速度/摩擦力一帧，保持推离墙壁的感觉
		if platformerPhysicsComponent:
			platformerPhysicsComponent.shouldSkipVelocity = true
			platformerPhysicsComponent.shouldSkipFriction = true

		# 落地后不再跳跃
		inputBufferTimer.stop()
		characterBodyComponent.shouldMoveThisFrame = true
		didWallJump = true

		# 增加跳跃次数并发射信号
		currentNumberOfJumps += 1

		# 发射墙壁跳跃信号
		didWallJumpStart.emit(wallNormal)
		# 发射通用跳跃信号
		didJump.emit(currentNumberOfJumps, JumpType.wallJump)


## 获取墙壁跳跃法线
## 返回当前墙壁碰撞的法线向量，或离开墙壁后仍在宽限期内时返回上一墙壁法线
func getWallJumpNormal() -> Vector2:
	if body.is_on_wall():
		return body.get_wall_normal()

	# 不要检查 characterBodyComponent.wasOnWall，因为该标志仅持续一帧（仅保持一帧）
	elif not is_zero_approx(wallJumpTimer.time_left):
		return characterBodyComponent.previousWallNormal

	else:
		return Vector2.ZERO


## 更新墙壁跳跃状态
## 当玩家离开墙壁时启动计时器
func updateWallJumpState() -> void:
	if not isEnabled or not parameters.allowWallJump:
		return

	var didLeaveWall: bool = characterBodyComponent.wasOnWall \
		and not body.is_on_wall() \
		and not body.is_on_floor()

	if didLeaveWall:
		wallJumpTimer.start()
		printDebug("墙壁跳跃计时器已启动")

#endregion


#region Debugging 调试区域

func _physics_process(_delta: float) -> void:
	showDebugInfo()


func showDebugInfo() -> void:
	if not debugMode:
		return

	Debug.addComponentWatchList(self, {
		state		= currentState,
		jumps		= currentNumberOfJumps,
		jumpInput	= jumpInput,
		canFloor	= canFloorJump,
		canFallJump	= canFallJump,
		canMulti	= canMultiJump,
		shouldBuffer= shouldBufferInput,
		inputBufferTimer = inputBufferTimer.time_left,
		bufferedJump= canBufferedJump,
		canCoyote	= canCoyoteJump,
		coyoteTimer	= coyoteJumpTimer.time_left,
		canWall		= canWallJump,
		wallTimer	= wallJumpTimer.time_left,
		})

#endregion

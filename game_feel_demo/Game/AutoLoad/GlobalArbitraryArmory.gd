extends Node2D

# ============================================================================
## GlobalArbitraryArmory.gd - 全局投射物管理器
# ============================================================================
## 全局投射物管理系统 - 管理投射物策略和发射
##
## 职责：
## - 策略注册与管理
## - 投射物发射请求
## - 回调方法实现
##
## 设计说明：
## - 作为 AutoLoad 使用
## - 通过策略的 strategyName 索引策略
## ============================================================================

## 设置为 false 时会禁用 _process 和 _input 处理
@export var isEnabled: bool = true:
	set(newValue):
		isEnabled = newValue
		# 根据启用状态设置进程处理
		self.set_process(isEnabled)
		self.set_process_input(isEnabled)
		if debugMode: Debug.printDebug(str("isEnabled 设置为: ", newValue), self)

@export var debugMode: bool = false

## 投射物管理器引用
## 从子节点获取 ProjectileManager2D 实例
@onready var projectileManager: ProjectileManager2D = $ProjectileManager2D


# ============================================================================
# 生命周期方法
# ============================================================================

## 初始化方法
## 设置进程处理和注册所有回调函数
func _ready() -> void:
	isEnabled = isEnabled
	_registerCallbacks()

	if debugMode:
		Debug.printDebug("GlobalArbitraryArmory 初始化完成", self)


# ============================================================================
# 投射物发射 - Projectile Casting
# ============================================================================

## 通过策略发射投射物
## 由 ProjectileSpellStrategy.execute() 调用
##
## @param strategy - 投射物策略
## @param context - 施法上下文
## @return - 发射成功返回 true
func requestExecutionByProjectileSpellStrategy(attackIndex: int,
	projIndex: int,
	startPosition: Vector2,
	targetPosition: Vector2,
	target: Node2D = null,
	moveMethod: Callable = Callable(),
	startMethod: Callable = Callable(),
	collisionMethod: Callable = Callable(),
	expiredMethod: Callable = Callable(),
	chargeEnterMethod: Callable = Callable(),
	chargeExitMethod: Callable = Callable(),
	anticipateEnterMethod: Callable = Callable(),
	mainEnterMethod: Callable = Callable(),
	recoveryEnterMethod: Callable = Callable(),
	completedMethod: Callable = Callable()) -> bool:

	var _moveMethod: Callable = moveMethod if moveMethod != Callable() else onMove
	var _startMethod: Callable = startMethod if startMethod != Callable() else onStart
	var _collisionMethod: Callable = collisionMethod if collisionMethod != Callable() else onCollision
	var _expiredMethod: Callable = expiredMethod if expiredMethod != Callable() else onExpired
	var _chargeEnterMethod: Callable = chargeEnterMethod if chargeEnterMethod != Callable() else onChargeEnter
	var _chargeExitMethod: Callable = chargeExitMethod if chargeExitMethod != Callable() else onChargeExit
	var _anticipateEnterMethod: Callable = anticipateEnterMethod if anticipateEnterMethod != Callable() else onAnticipateEnter
	var _mainEnterMethod: Callable = mainEnterMethod if mainEnterMethod != Callable() else onMainEnter
	var _recoveryEnterMethod: Callable = recoveryEnterMethod if recoveryEnterMethod != Callable() else onRecoveryEnter
	var _completedMethod: Callable = completedMethod if completedMethod != Callable() else onCompleted

	# 设置攻击阶段回调
	_setAttackCallbacks(attackIndex, _chargeEnterMethod, _chargeExitMethod, _anticipateEnterMethod, _mainEnterMethod, _recoveryEnterMethod, _completedMethod)

	# 发射投射物
	var result: bool = projectileManager.request_execution(
		attackIndex,
		projIndex,
		startPosition,
		targetPosition,
		target,
		_moveMethod,
		_startMethod,
		_collisionMethod,
		_expiredMethod
	)

	return result


## 设置攻击阶段回调
##
## @param attackIndex - 攻击索引
## @param chargeEnterMethod - 蓄力进入回调
## @param chargeExitMethod - 蓄力退出回调
## @param anticipateEnterMethod - 预兆进入回调
## @param mainEnterMethod - 主攻击进入回调
## @param recoveryEnterMethod - 恢复进入回调
## @param completedMethod - 攻击完成回调
func _setAttackCallbacks(attackIndex: int, chargeEnterMethod: Callable, chargeExitMethod: Callable, anticipateEnterMethod: Callable, mainEnterMethod: Callable, recoveryEnterMethod: Callable, completedMethod: Callable) -> void:
	if attackIndex >= projectileManager.attacks.size():
		return

	var attack: Attack2D = projectileManager.attacks[attackIndex]
	attack.set_on_charge_enter(chargeEnterMethod)
	attack.set_on_charge_exit(chargeExitMethod)
	attack.set_on_anticipate_enter(anticipateEnterMethod)
	attack.set_on_main_enter(mainEnterMethod)
	attack.set_on_recovery_enter(recoveryEnterMethod)
	attack.set_on_completed(completedMethod)


# ============================================================================
# 内部方法 - Internal Methods
# ============================================================================

## 注册默认回调
func _registerCallbacks() -> void:
	# 为所有已存在的投射物设置回调函数
	## set_on_start: 投射物发射时调用
	## set_on_move: 投射物每帧移动时调用
	## set_on_expired: 投射物过期时调用
	for proj: Projectile2D in projectileManager.projectiles:
		## 设置默认回调
		proj.set_on_start(onStart).set_on_move(onMove).set_on_expired(onExpired)

	## 为所有已存在的攻击设置回调函数
	## set_on_charge_enter: 蓄力开始时调用
	## set_on_anticipate_enter: 预兆开始时调用
	## set_on_main_enter: 主攻击开始时调用
	## set_on_recovery_enter: 恢复开始时调用
	## set_on_completed: 攻击完成时调用
	for attack: Attack2D in projectileManager.attacks:
		## 设置默认回调
		attack.set_on_charge_enter(onChargeEnter).set_on_charge_exit(onChargeExit)
		attack.set_on_anticipate_enter(onAnticipateEnter)
		attack.set_on_main_enter(onMainEnter)
		attack.set_on_recovery_enter(onRecoveryEnter)
		attack.set_on_completed(onCompleted)


# ============================================================================
# 现存的回调方法（保持兼容）
# ============================================================================
@warning_ignore_start("unused_parameter")

## 投射物发射回调
func onStart(proj: Projectile2D) -> void:
	pass


## 投射物移动回调
func onMove(proj: Projectile2D, delta: float, exeption: bool = false) -> Vector2:
	return proj.direction


## 投射物碰撞回调
func onCollision(proj: Projectile2D, areaRid: RID, areaNode: Node2D, targetNode: Node2D, areaShapeIndex: int, localShapeIndex: int) -> void:
	if !proj.validate_collision(areaRid, targetNode):
		return

	if targetNode.has_method(proj.on_hit_call):
		targetNode.call(proj.on_hit_call, proj)
	proj.on_pierced(areaRid)


## 投射物过期回调
func onExpired(proj: Projectile2D) -> void:
	pass


## 攻击蓄力回调
func onChargeEnter(attack: Attack2D) -> void:
	attack.charge_enter()


## 攻击蓄力退出回调
func onChargeExit(attack: Attack2D) -> void:
	attack.charge_exit()


## 攻击预兆回调
func onAnticipateEnter(attack: Attack2D) -> void:
	attack.anticipate_enter()


## 主攻击回调
func onMainEnter(attack: Attack2D) -> void:
	attack.pi.position += attack.attack_offset
	attackBase(attack)


## 基础攻击执行方法
func attackBase(attack: Attack2D) -> void:
	attack.current_state_lifetime = attack.attack_duration_time
	attack.request_projectile()


## 攻击恢复回调
func onRecoveryEnter(attack: Attack2D) -> void:
	attack.recovery_enter()


## 攻击完成回调
func onCompleted(attack: Attack2D) -> void:
	pass

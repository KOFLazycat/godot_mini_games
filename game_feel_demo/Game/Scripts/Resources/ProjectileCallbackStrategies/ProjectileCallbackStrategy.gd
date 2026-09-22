## ProjectileCallbackStrategy
## 投射物回调策略基类
##
## 使用方法：
## 1. 创建子类继承此类
## 2. 重写需要的回调函数
## 3. 在 ProjectileComponent 中导出此资源
## 4. 发射时会自动使用此策略的回调函数
##
## 回调执行顺序：
## 攻击阶段：Charge(蓄力) → Anticipate(预兆) → Main(主攻击) → Recovery(恢复) → Completed(完成)
## 投射物阶段：Start(发射) → Move(每帧移动) → [Collision(碰撞) × N] / Expired(过期)
##
## 全局属性键（用于在投射物/攻击上存储配置）：
## - SPEED_CURVE: 速度曲线（Curve），控制投射物速度随时间变化
## - COLLISION_AUDIO: 碰撞音效（ListSoundResource）
## - DAMAGE_AUDIO: 伤害音效
## - CRIT_AUDIO: 暴击音效
## - DODGE_AUDIO: 闪避音效
## - EXPIRED_AUDIO: 过期音效
## - RELEASE_AUDIO: 释放音效
## - CHARGE_AUDIO: 蓄力音效
##
## @example
## class_name FireballCallbackStrategy
## extends ProjectileCallbackStrategy
##
## func onStart(proj: Projectile2D) -> void:
##     # 播放发射特效
##     pass
##
## func onCollision(proj, areaRid, areaNode, targetNode, areaShapeIndex, localShapeIndex):
##     # 造成伤害
##     pass
@icon("res://addons/at-icons/node/arrow_projectile.svg")

class_name ProjectileCallbackStrategy
extends Resource


#region const
## ============================================================================
## 常量定义 - 全局属性键
## 用于在投射物/攻击的 global_properties 中存储配置
## ============================================================================

## 发射开始场景键 - 投射物运动过程中的轨迹粒子场景
const GLOBAL_PROPERTIES_KEY_START_TIMED_PARTICLE_TRAIL = "START_TIMED_PARTICLE_TRAIL"
## 过期场景键 - 投射物过期时显示的场景
const GLOBAL_PROPERTIES_KEY_EXPIRED_PACKED_SCENE = "EXPIRED_PACKED_SCENE"
## 速度曲线键 - 控制投射物速度随时间变化（Curve 资源）
const GLOBAL_PROPERTIES_KEY_SPEED_CURVE = "SPEED_CURVE"
## 碰撞音效键 - 投射物击中目标时播放的音效
const GLOBAL_PROPERTIES_KEY_COLLISION_AUDIO: String = "COLLISION_AUDIO"
## 伤害音效键 - 造成伤害时播放的音效
const GLOBAL_PROPERTIES_KEY_DAMAGE_AUDIO: String = "DAMAGE_AUDIO"
## 暴击音效键 - 暴击时播放的音效
const GLOBAL_PROPERTIES_KEY_CRIT_AUDIO: String = "CRIT_AUDIO"
## 闪避音效键 - 闪避时播放的音效
const GLOBAL_PROPERTIES_KEY_DODGE_AUDIO: String = "DODGE_AUDIO"
## 过期音效键 - 投射物过期消失时播放的音效
const GLOBAL_PROPERTIES_KEY_EXPIRED_AUDIO: String = "EXPIRED_AUDIO"
## 释放音效键 - 攻击释放/发射时播放的音效
const GLOBAL_PROPERTIES_KEY_RELEASE_AUDIO: String = "RELEASE_AUDIO"
## 蓄力音效键 - 攻击蓄力时播放的音效
const GLOBAL_PROPERTIES_KEY_CHARGE_AUDIO: String = "CHARGE_AUDIO"

## ============================================================================
## 常量定义 - 私有属性键
## 用于在投射物/攻击的 individual_properties 中存储配置
## ============================================================================

## 投射物关联的能力
const INDIVIDUAL_PROPERTIES_KEY_GABILITY = "GABILITY"
## 投射物对目标施加的效果
const INDIVIDUAL_PROPERTIES_KEY_GEFFECTS = "GEFFECTS"
## 目标数据
const INDIVIDUAL_PROPERTIES_KEY_TARGETDATA = "TARGETDATA"

#endregion


#region State
var gability: GameplayAbility
var geffects: Array[GameplayEffect]
#endregion


@warning_ignore_start("unused_parameter")
#region Projectile Callbacks
## ============================================================================
## 投射物回调 - 与投射物生命周期相关的回调
## ============================================================================

## 投射物发射时回调
##
## 调用时机：投射物刚刚被创建并开始移动时
## 典型用途：播放发射特效、播放音效、设置初始状态
##
## @param proj - 投射物实例
func onStart(proj: Projectile2D) -> void:
	proj.individual_properties.set(INDIVIDUAL_PROPERTIES_KEY_GABILITY, gability)
	proj.individual_properties.set(INDIVIDUAL_PROPERTIES_KEY_GEFFECTS, geffects)
	
	var instancedProj: InstancedProjectile2D = proj as InstancedProjectile2D
	if instancedProj:
		## 从全局属性获取粒子拖尾场景
		var trailScene: PackedScene = instancedProj.global_properties.get(GLOBAL_PROPERTIES_KEY_START_TIMED_PARTICLE_TRAIL)
		if (trailScene != null):
			## 实例化粒子节点
			var trail: TimedParticleBase = trailScene.instantiate()
			## 设置初始位置为投射物位置
			trail.global_position = instancedProj.position
			trail.timeToFree = 1.0
			instancedProj.current_scene.add_child(trail)
			## 如果有等待时间（在发射前等待），隐藏粒子
			if (proj.wait_time <= 0):
				trail.showParticles()
			## 保存粒子引用以便后续更新
			proj.individual_properties[GLOBAL_PROPERTIES_KEY_START_TIMED_PARTICLE_TRAIL] = trail


## 投射物每帧移动回调
##
## 调用时机：投射物每帧移动时（每帧调用）
## 典型用途：追踪目标、曲线弹道、动态调整方向、添加重力效果
##
## 速度曲线逻辑：
## 如果 global_properties 中存在 SPEED_CURVE，则根据投射物剩余寿命百分比采样曲线，
## 动态调整投射物速度。实现如：初始快速 → 中段减速（弹道末端）、或初始慢 → 后段加速（追踪弹）等效果。
##
## @param proj - 投射物实例
## @param delta - 上一帧到当前帧的时间间隔（秒）
## @param ex - 扩展参数，用于特殊处理
## @return - 返回投射物的新方向向量
func onMove(proj: Projectile2D, delta: float, ex: bool = false) -> Vector2:
	## 获取粒子引用
	var trail: TimedParticleBase = proj.individual_properties.get(GLOBAL_PROPERTIES_KEY_START_TIMED_PARTICLE_TRAIL)
	if (trail != null):
		## 同步变换
		trail.transform = proj.transform
		## 粒子位置：在投射物位置前方
		trail.global_position = proj.position + (proj.direction * delta * proj.speed)
		## 如果需要旋转（火焰效果），旋转粒子
		if (ex):
			trail.rotate(proj.direction.angle())
		## 等待时间结束后显示粒子
		if (proj.wait_time <= 0):
			trail.startParticles()
	
	## 获取速度曲线配置
	var curve: Curve = proj.global_properties.get(GLOBAL_PROPERTIES_KEY_SPEED_CURVE)
	if curve != null:
		## 根据剩余寿命百分比采样速度曲线
		## timeLeftPercent = 1.0 表示刚发射，0.0 表示即将过期
		var timeLeftPercent: float = (proj.resource.lifetime - proj.lifetime) / proj.resource.lifetime
		proj.speed = proj.resource.linear_speed * curve.sample(timeLeftPercent)
	return proj.direction


## 投射物碰撞回调
##
## 调用时机：投射物与碰撞体发生碰撞时
## 典型用途：造成伤害、触发特效、播放音效、处理穿透逻辑
##
## 碰撞音效逻辑：
## 从 global_properties 获取 COLLISION_AUDIO 音效资源并播放。
## 伤害、暴击、闪避等音效在 DamageCalculatorComponent 中单独实现。
##
## @param proj - 投射物实例
## @param areaRid - 碰撞区域的 RID
## @param areaNode - 碰撞的区域节点
## @param targetNode - 碰撞的目标节点
## @param areaShapeIndex - 碰撞区域的形状索引
## @param localShapeIndex - 投射物本地的形状索引
func onCollision(proj: Projectile2D, areaRid: RID, areaNode: Node2D, targetNode: Node2D, areaShapeIndex: int, localShapeIndex: int) -> void:
	## 验证碰撞是否有效
	if not proj.validate_collision(areaRid, targetNode):
		return
	
	## 查询碰撞结果
	## 方案2：射线起点向外偏移，确保在碰撞体外部
	## 当投射物在目标碰撞体内部时，原方案(起点 -direction * 10)可能仍在碰撞体内部，导致射线查询返回null
	var toTarget: Vector2 = targetNode.global_position - proj.position
	var distance: float = toTarget.length()
	## 起点向外偏移，确保在碰撞体外部（至少偏移50单位）
	var fromPos: Vector2 = proj.position - toTarget.normalized() * max(distance + 50, 50)

	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(fromPos, targetNode.global_position, proj.collision_mask)
	query.collide_with_areas = true
	var result: Dictionary = proj.current_space.intersect_ray(query)
	if not result.is_empty():
		var collider: HurtBoxComponent = result["collider"] as HurtBoxComponent
		if collider:
			var colliderEntity: Entity = collider.entity
			if colliderEntity:
				# 找到真正的collider实体
				result["collider"] = colliderEntity
				var targetData: GameplayAbilityTargetData = GameplayAbilityTargetData.new()
				targetData.append_physics_hit(result)
				proj.individual_properties.set(INDIVIDUAL_PROPERTIES_KEY_TARGETDATA, targetData)
		## 弹射逻辑
		#var prev: float = proj.direction.angle()
		#proj.direction = proj.direction.bounce(result.normal)
		#if (proj.look_at):
			#proj.transform = proj.transform.rotated(proj.direction.angle() - prev)

	## 调用目标的受击方法
	if targetNode.has_method(proj.on_hit_call):
		targetNode.call(proj.on_hit_call, proj)

	## 处理穿透逻辑
	proj.on_pierced(areaRid)
	
	var instancedProj: InstancedProjectile2D = proj as InstancedProjectile2D
	if instancedProj:
		## 获取爆炸场景并实例化
		var blastScene: PackedScene = proj.global_properties.get(GLOBAL_PROPERTIES_KEY_EXPIRED_PACKED_SCENE)
		if (blastScene != null):
			var blast: TimedParticleBase = blastScene.instantiate()
			blast.transform = proj.transform
			blast.timeToFree = 0.5
			instancedProj.current_scene.add_child(blast)
			## 自动释放爆炸效果
			blast.startParticles()

	## 播放碰撞音效
	var collisionAudio: ListSoundResource = proj.global_properties.get(GLOBAL_PROPERTIES_KEY_COLLISION_AUDIO, null)
	if collisionAudio:
		collisionAudio.play_managed()


## 投射物过期回调
##
## 调用时机：投射物超出最大距离或存活时间结束时
## 典型用途：播放消失特效、回收对象、记录命中信息
##
## 过期音效逻辑：
## 从 global_properties 获取 EXPIRED_AUDIO 音效资源并播放。
##
## @param proj - 投射物实例
func onExpired(proj: Projectile2D) -> void:
	## 获取粒子引用
	var trail: TimedParticleBase = proj.individual_properties.get(GLOBAL_PROPERTIES_KEY_START_TIMED_PARTICLE_TRAIL)
	if trail:
		trail.stopParticles()
	
	## 播放过期音效
	var expiredAudio: ListSoundResource = proj.global_properties.get(GLOBAL_PROPERTIES_KEY_EXPIRED_AUDIO, null)
	if expiredAudio:
		expiredAudio.play_managed()

#endregion


#region Attack Callbacks
## ============================================================================
## 攻击回调 - 与攻击阶段（蓄力→预兆→主攻击→恢复→完成）相关的回调
## ============================================================================

## 攻击蓄力阶段进入回调
##
## 调用时机：攻击开始蓄力时
## 典型用途：播放蓄力动画、显示蓄力特效、锁定目标
##
## 蓄力音效逻辑：
## 从 global_properties 获取 CHARGE_AUDIO 音效资源并播放。
##
## @param attack - 攻击实例
func onChargeEnter(attack: Attack2D) -> void:
	attack.charge_enter()
	## 播放蓄力音效
	var chargeAudio: ListSoundResource = attack.global_properties.get(GLOBAL_PROPERTIES_KEY_CHARGE_AUDIO, null)
	if chargeAudio:
		chargeAudio.play_managed()


## 攻击蓄力阶段退出回调
##
## 调用时机：玩家释放按键或蓄力时间结束时
## 典型用途：播放释放动画、计算最终伤害/效果
##
## @param attack - 攻击实例
func onChargeExit(attack: Attack2D) -> void:
	attack.charge_exit()


## 攻击预兆阶段进入回调
##
## 调用时机：蓄力完成后，发射投射物之前
## 典型用途：播放预警特效、显示攻击范围、震屏效果
##
## @param attack - 攻击实例
func onAnticipateEnter(attack: Attack2D) -> void:
	attack.anticipate_enter()


## 攻击主攻击阶段进入回调
##
## 调用时机：预兆阶段结束，投射物正式发射时
## 典型用途：创建投射物、播放发射动画、触发主攻击特效
##
## 释放音效逻辑：
## 从 global_properties 获取 RELEASE_AUDIO 音效资源并播放。
##
## @param attack - 攻击实例
func onMainEnter(attack: Attack2D) -> void:
	## 应用攻击偏移并设置持续时间
	attack.pi.position += attack.attack_offset
	attack.current_state_lifetime = attack.attack_duration_time
	attack.request_projectile()

	## 播放释放音效
	var releaseAudio: ListSoundResource = attack.global_properties.get(GLOBAL_PROPERTIES_KEY_RELEASE_AUDIO, null)
	if releaseAudio:
		releaseAudio.play_managed()


## 攻击恢复阶段进入回调
##
## 调用时机：主攻击阶段完成，进入冷却恢复时
## 典型用途：播放恢复动画、减少攻速计数、重置状态
##
## @param attack - 攻击实例
func onRecoveryEnter(attack: Attack2D) -> void:
	attack.recovery_enter()


## 攻击完成回调
##
## 调用时机：整个攻击流程完全结束后
## 典型用途：清理临时数据、触发连击计数、检查成就
##
## @param attack - 攻击实例
func onCompleted(attack: Attack2D) -> void:
	pass

#endregion

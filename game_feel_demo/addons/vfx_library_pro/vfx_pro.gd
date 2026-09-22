extends Node
## VFX Library Pro - 商业版特效管理器
## 包含高级UI特效、战斗特效和专业工具
## 🔒 本文件为商业版独占内容

# ===== UI 特效场景 =====
const PAGE_TRANSITION_SCENE = preload("res://addons/vfx_library_pro/effects_pro/page_transition.tscn")
# TODO: 待实现的UI特效
# const LOADING_SPINNER_SCENE = preload("res://addons/vfx_library_pro/effects_pro/loading_spinner.tscn")
# const NOTIFICATION_POPUP_SCENE = preload("res://addons/vfx_library_pro/effects_pro/notification_popup.tscn")
# const ACHIEVEMENT_UNLOCK_SCENE = preload("res://addons/vfx_library_pro/effects_pro/achievement_unlock.tscn")
# const HP_BAR_EFFECT_SCENE = preload("res://addons/vfx_library_pro/effects_pro/hp_bar_effect.tscn")
# const SKILL_COOLDOWN_SCENE = preload("res://addons/vfx_library_pro/effects_pro/skill_cooldown.tscn")
# const CURRENCY_COLLECT_SCENE = preload("res://addons/vfx_library_pro/effects_pro/currency_collect.tscn")
# const LEVEL_UP_SCENE = preload("res://addons/vfx_library_pro/effects_pro/level_up.tscn")
# const COMBO_COUNTER_SCENE = preload("res://addons/vfx_library_pro/effects_pro/combo_counter.tscn")

# ===== 高级战斗特效场景 =====
const SWORD_SLASH_SCENE = preload("res://addons/vfx_library_pro/effects_pro/sword_slash.tscn")
const EXPLOSION_WAVE_SCENE = preload("res://addons/vfx_library_pro/effects_pro/explosion_wave.tscn")
const ENERGY_SHIELD_SCENE = preload("res://addons/vfx_library_pro/effects_pro/energy_shield.tscn")
const CHARGING_EFFECT_SCENE = preload("res://addons/vfx_library_pro/effects_pro/charging_effect.tscn")
const CRITICAL_HIT_SCENE = preload("res://addons/vfx_library_pro/effects_pro/critical_hit.tscn")

# ===== 常量定义 =====
const DEFAULT_RIPPLE_DURATION = 0.6
const DEFAULT_TRANSITION_TIME = 0.5
const DEFAULT_NOTIFICATION_DURATION = 2.0

# ===== 辅助函数 =====

## 获取UI层（Canvas Layer）
func _get_ui_layer() -> CanvasLayer:
    # 尝试获取现有的UI层
    if get_tree().current_scene.has_node("UILayer"):
        return get_tree().current_scene.get_node("UILayer")
    
    # 如果不存在，创建一个新的
    var ui_layer = CanvasLayer.new()
    ui_layer.name = "UILayer"
    ui_layer.layer = 100  # 确保在最上层
    get_tree().current_scene.add_child(ui_layer)
    return ui_layer


## 获取场景根节点
func _get_scene_root() -> Node:
    var scene_root = get_tree().current_scene
    if not scene_root:
        push_error("VFXPro: No current scene found")
        return null
    return scene_root


## 延迟清理节点
func _cleanup_delayed(node: Node, delay: float) -> void:
    await get_tree().create_timer(delay).timeout
    if is_instance_valid(node):
        node.queue_free()


## 页面转场效果
## type: "fade", "slide_left", "slide_right", "zoom", "pixelate"
func spawn_page_transition(type: String = "fade", duration: float = DEFAULT_TRANSITION_TIME) -> void:
    var ui_layer = _get_ui_layer()
    if not ui_layer:
        return
    
    var transition = PAGE_TRANSITION_SCENE.instantiate()
    ui_layer.add_child(transition)
    
    # 设置转场类型和时长
    if transition.has_method("play_transition"):
        transition.play_transition(type, duration)
    
    # 转场完成后清理
    _cleanup_delayed(transition, duration + 0.1)


## 加载动画
## style: "spinner", "dots", "progress", "circular"
## TODO: 待实现
func spawn_loading_animation(style: String = "spinner") -> Node:
    push_warning("VFXPro: spawn_loading_animation not implemented yet")
    return null
    # var ui_layer = _get_ui_layer()
    # if not ui_layer:
    # 	return null
    # 
    # var loading = LOADING_SPINNER_SCENE.instantiate()
    # ui_layer.add_child(loading)
    # 
    # # 设置加载样式
    # if loading.has_method("set_style"):
    # 	loading.set_style(style)
    # 
    # # 返回节点引用，以便调用者手动控制停止
    # return loading


## 通知弹窗
## TODO: 待实现
func spawn_notification_popup(message: String, icon: Texture2D = null, color: Color = Color.WHITE) -> void:
    push_warning("VFXPro: spawn_notification_popup not implemented yet")
    # var ui_layer = _get_ui_layer()
    # if not ui_layer:
    # 	return
    # 
    # var notification = NOTIFICATION_POPUP_SCENE.instantiate()
    # ui_layer.add_child(notification)
    # 
    # # 设置通知内容
    # if notification.has_method("set_content"):
    # 	notification.set_content(message, icon, color)
    # 
    # # 自动清理
    # _cleanup_delayed(notification, DEFAULT_NOTIFICATION_DURATION)


## 成就解锁特效
## TODO: 待实现
func spawn_achievement_unlock(achievement_name: String, icon: Texture2D = null) -> void:
    push_warning("VFXPro: spawn_achievement_unlock not implemented yet")
    # var ui_layer = _get_ui_layer()
    # if not ui_layer:
    # 	return
    # 
    # var achievement = ACHIEVEMENT_UNLOCK_SCENE.instantiate()
    # ui_layer.add_child(achievement)
    # 
    # # 设置成就信息
    # if achievement.has_method("set_achievement"):
    # 	achievement.set_achievement(achievement_name, icon)
    # 
    # # 自动清理（成就显示通常较长）
    # _cleanup_delayed(achievement, 3.0)


## 血条变化特效
## 在血条值变化时产生视觉反馈
## TODO: 待实现
func spawn_hp_bar_effect(hp_bar: Control, damage_type: String = "damage") -> void:
    push_warning("VFXPro: spawn_hp_bar_effect not implemented yet")
    # if not is_instance_valid(hp_bar):
    # 	push_error("VFXPro: spawn_hp_bar_effect called with invalid hp_bar")
    # 	return
    # 
    # var effect = HP_BAR_EFFECT_SCENE.instantiate()
    # hp_bar.add_child(effect)
    # 
    # # 设置效果类型（damage, heal, shield）
    # if effect.has_method("play_effect"):
    # 	effect.play_effect(damage_type)
    # 
    # _cleanup_delayed(effect, 1.0)


## 技能冷却动画
## 在技能按钮上显示冷却进度
## TODO: 待实现
func spawn_skill_cooldown(skill_button: Control, cooldown_time: float) -> Node:
    push_warning("VFXPro: spawn_skill_cooldown not implemented yet")
    return null
    # if not is_instance_valid(skill_button):
    # 	push_error("VFXPro: spawn_skill_cooldown called with invalid skill_button")
    # 	return null
    # 
    # var cooldown = SKILL_COOLDOWN_SCENE.instantiate()
    # skill_button.add_child(cooldown)
    # 
    # # 开始冷却动画
    # if cooldown.has_method("start_cooldown"):
    # 	cooldown.start_cooldown(cooldown_time)
    # 
    # # 冷却完成后自动清理
    # _cleanup_delayed(cooldown, cooldown_time)
    # 
    # return cooldown


## 货币收集动画
## 从起点飞向终点的货币图标
## TODO: 待实现
func spawn_currency_collect(start_pos: Vector2, end_pos: Vector2, amount: int = 1, icon: Texture2D = null) -> void:
    push_warning("VFXPro: spawn_currency_collect not implemented yet")
    # var ui_layer = _get_ui_layer()
    # if not ui_layer:
    # 	return
    # 
    # var currency = CURRENCY_COLLECT_SCENE.instantiate()
    # ui_layer.add_child(currency)
    # 
    # # 设置动画参数
    # if currency.has_method("animate_collection"):
    # 	currency.animate_collection(start_pos, end_pos, amount, icon)
    # 
    # _cleanup_delayed(currency, 1.5)


## 升级特效
## 在角色升级时的华丽特效
## TODO: 待实现
func spawn_level_up(target: Node2D, new_level: int = 0) -> void:
    push_warning("VFXPro: spawn_level_up not implemented yet")
    # if not is_instance_valid(target):
    # 	push_error("VFXPro: spawn_level_up called with invalid target")
    # 	return
    # 
    # var level_up = LEVEL_UP_SCENE.instantiate()
    # target.add_child(level_up)
    # 
    # # 设置等级信息
    # if level_up.has_method("play_level_up"):
    # 	level_up.play_level_up(new_level)
    # 
    # _cleanup_delayed(level_up, 2.5)


## 连击计数器
## 显示当前连击数的动态UI
## TODO: 待实现
func spawn_combo_counter(combo_number: int, position: Vector2 = Vector2.ZERO) -> Node:
    push_warning("VFXPro: spawn_combo_counter not implemented yet")
    return null
    # var ui_layer = _get_ui_layer()
    # if not ui_layer:
    # 	return null
    # 
    # var combo = COMBO_COUNTER_SCENE.instantiate()
    # ui_layer.add_child(combo)
    # 
    # # 设置连击数和位置
    # if combo.has_method("show_combo"):
    # 	combo.show_combo(combo_number, position)
    # 
    # # 返回引用，以便更新连击数
    # return combo


# ===== 高级战斗特效功能 =====

## 剑气斩击
## 从起点到终点的剑气特效
func spawn_sword_slash(start_pos: Vector2, end_pos: Vector2, color: Color = Color.CYAN) -> void:
    var scene_root = _get_scene_root()
    if not scene_root:
        return
    
    var slash = SWORD_SLASH_SCENE.instantiate()
    scene_root.add_child(slash)
    
    # 设置斩击路径和颜色
    if slash.has_method("create_slash"):
        slash.create_slash(start_pos, end_pos, color)
    
    # 特效会自动清理


## 爆炸冲击波
## 从中心向外扩散的冲击波效果
func spawn_explosion_wave(position: Vector2, radius: float = 300.0, color: Color = Color(1, 0.5, 0.2)) -> void:
    var scene_root = _get_scene_root()
    if not scene_root:
        return
    
    var wave = EXPLOSION_WAVE_SCENE.instantiate()
    scene_root.add_child(wave)
    wave.global_position = position
    
    # 设置冲击波参数
    if wave.has_method("create_explosion"):
        wave.create_explosion(radius, color)
    
    # 特效会自动清理


## 能量护盾
## 角色周围的防护罩效果
func spawn_energy_shield(character: Node2D, duration: float = 3.0, color: Color = Color(0.3, 0.7, 1)) -> Node:
    if not is_instance_valid(character):
        push_error("VFXPro: spawn_energy_shield called with invalid character")
        return null
    
    var shield = ENERGY_SHIELD_SCENE.instantiate()
    character.add_child(shield)
    
    # 设置护盾颜色并激活
    if shield.has_method("set_shield_color"):
        shield.set_shield_color(color)
    if shield.has_method("activate"):
        shield.activate(duration)
    
    # 返回引用，让调用者可以控制护盾
    return shield


## 技能充能效果
## 角色周围的能量聚集动画
func spawn_charging_effect(character: Node2D, charge_time: float = 2.0, color: Color = Color(0.5, 0.8, 1)) -> Node:
    if not is_instance_valid(character):
        push_error("VFXPro: spawn_charging_effect called with invalid character")
        return null
    
    var charging = CHARGING_EFFECT_SCENE.instantiate()
    character.add_child(charging)
    
    # 设置充能参数并开始
    if charging.has_method("start_charging"):
        charging.start_charging(charge_time, color)
    
    # 返回引用，让调用者可以检测充能完成
    return charging


## 暴击特效
## 更华丽的伤害数字和粒子效果
func spawn_critical_hit(position: Vector2, damage_multiplier: float = 2.0) -> void:
    var scene_root = _get_scene_root()
    if not scene_root:
        return
    
    var crit = CRITICAL_HIT_SCENE.instantiate()
    scene_root.add_child(crit)
    crit.global_position = position
    
    # 触发暴击特效
    if crit.has_method("trigger_critical"):
        crit.trigger_critical(damage_multiplier)
    
    # 特效会自动清理


# ===== 实用工具函数 =====

## 屏幕闪光（比基础版更强）
func flash_screen(color: Color = Color.WHITE, intensity: float = 0.8, duration: float = 0.1) -> void:
    var ui_layer = _get_ui_layer()
    if not ui_layer:
        return
    
    var flash = ColorRect.new()
    flash.color = Color(color.r, color.g, color.b, 0)
    flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui_layer.add_child(flash)
    
    # 全屏显示
    flash.set_anchors_preset(Control.PRESET_FULL_RECT)
    
    # 淡入淡出动画
    var tween = create_tween()
    tween.tween_property(flash, "color:a", intensity, duration * 0.3)
    tween.tween_property(flash, "color:a", 0.0, duration * 0.7)
    
    _cleanup_delayed(flash, duration)


## 屏幕震动（更精细的控制）
func screen_shake_advanced(duration: float = 0.3, frequency: float = 15.0, amplitude: float = 10.0, decay: bool = true) -> void:
    var camera = get_viewport().get_camera_2d()
    if not camera:
        push_warning("VFXPro: No Camera2D found for advanced screen shake")
        return
    
    var original_offset = camera.offset
    var shake_time = 0.0
    
    while shake_time < duration:
        var progress = shake_time / duration
        var current_amplitude = amplitude * (1.0 - progress if decay else 1.0)
        
        camera.offset = original_offset + Vector2(
            randf_range(-current_amplitude, current_amplitude),
            randf_range(-current_amplitude, current_amplitude)
        )
        
        await get_tree().create_timer(1.0 / frequency).timeout
        shake_time += 1.0 / frequency
    
    camera.offset = original_offset


## 批量生成粒子（性能优化版）
func spawn_particles_batch(positions: Array[Vector2], color: Color = Color.WHITE, count_per_position: int = 10) -> void:
    if not has_node("/root/VFX"):
        push_error("VFXPro: VFX manager not found")
        return
    
    var vfx = get_node("/root/VFX")
    
    for pos in positions:
        vfx.spawn_particles(pos, color, count_per_position)
        # 小延迟避免性能峰值
        await get_tree().create_timer(0.01).timeout


# ===== 调试和工具 =====

## 显示特效边界框（调试用）
var _debug_mode = false

func toggle_debug_mode() -> void:
    _debug_mode = !_debug_mode
    print("VFXPro Debug Mode: ", "ON" if _debug_mode else "OFF")


func is_debug_mode() -> bool:
    return _debug_mode

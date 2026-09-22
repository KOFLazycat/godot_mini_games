extends Node2D
## VFX Library Pro 演示场景
## 展示所有商业版独占特效和着色器

# UI节点引用
@onready var particle_list: ItemList = $UI/ParticlePanel/VBox/ScrollContainer/ParticleList
@onready var shader_list: ItemList = $UI/ShaderPanel/ScrollContainer/ShaderList
@onready var apply_shader_btn: Button = $UI/ShaderPanel/VBox/ShaderButtonContainer/ApplyButton
@onready var remove_shader_btn: Button = $UI/ShaderPanel/VBox/ShaderButtonContainer/RemoveButton
@onready var clear_button: Button = $UI/ControlPanel/VBox/ClearButton
@onready var shader_test_sprite: Sprite2D = $ShaderTestSprite
@onready var info_label: Label = $UI/InfoPanel/InfoLabel

# 特效数据
var particle_effects_data = []
var ui_effects_data = []
var shaders_data = []

var current_particle_index = -1
var current_ui_index = -1
var current_shader_index = -1

# 用于跟踪所有生成的特效节点
var spawned_effects = []

# shader动画时间
var shader_animation_time = 0.0
var current_shader_base_intensity: float = 1.0


func _ready() -> void:
	print("=== VFX Library Pro Demo Started ===")
	
	# 检查VFXPro是否配置
	check_autoloads()
	
	# 初始化列表
	setup_particle_list()
	# setup_ui_list()
	setup_shader_list()
	# 运行完setup后，打印一条调试信息
	print_debug("shader list initialized: %d" % shaders_data.size())
	
	# 连接信号
	particle_list.item_selected.connect(_on_particle_selected)
	# ui_list.item_selected.connect(_on_ui_selected)
	shader_list.item_selected.connect(_on_shader_selected)
	shader_list.item_activated.connect(_on_shader_activated)  # 双击激活
	apply_shader_btn.pressed.connect(_on_apply_shader)
	remove_shader_btn.pressed.connect(_on_remove_shader)
	clear_button.pressed.connect(_on_clear_all)
	
	update_info("准备就绪", "选择特效后右键点击屏幕生成")
	
	# 打印ShaderTestSprite的纹理信息
	if shader_test_sprite and shader_test_sprite.texture:
		print("✓ ShaderTestSprite 纹理已设置: %s" % shader_test_sprite.texture.resource_path)
	else:
		push_warning("⚠ ShaderTestSprite 没有设置纹理")


func setup_particle_list() -> void:
	"""设置粒子特效列表"""
	particle_effects_data = [
		{"name": "⚔️ 剑气斩击", "func": "sword_slash"},
		{"name": "💥 爆炸冲击波", "func": "explosion"},
		{"name": "🛡️ 能量护盾", "func": "shield"},
		{"name": "⚡ 蓄力特效", "func": "charging"},
		{"name": "💫 暴击特效", "func": "critical"},
	]
	
	for effect in particle_effects_data:
		particle_list.add_item(effect["name"])
	
	print("✓ 粒子特效列表: %d 个" % particle_effects_data.size())


#func setup_ui_list() -> void:
	#"""设置UI特效列表"""
	#return
	#ui_effects_data = [
		#{"name": " 淡入淡出", "func": "fade"},
		#{"name": "➡️ 滑动", "func": "slide"},
		#{"name": "🔍 缩放", "func": "zoom"},
	#]
	#return
	#
	#for effect in ui_effects_data:
		#ui_list.add_item(effect["name"])
	#
	#print("✓ UI特效列表: %d 个" % ui_effects_data.size())


func setup_shader_list() -> void:
	"""设置着色器列表"""
	shaders_data = [
		{"name": "⏰ 时间扭曲", "path": "res://addons/vfx_library_pro/shaders_pro/time_warp.gdshader"},
		{"name": "📡 全息投影", "path": "res://addons/vfx_library_pro/shaders_pro/hologram.gdshader"},
		{"name": "📺 故障艺术", "path": "res://addons/vfx_library_pro/shaders_pro/glitch_art.gdshader"},
		{"name": "💠 能量脉冲", "path": "res://addons/vfx_library_pro/shaders_pro/energy_pulse.gdshader"},
		{"name": "🔥 火焰附魔", "path": "res://addons/vfx_library_pro/shaders_pro/elemental_aura.gdshader", "element_type": 0},
		{"name": "❄️ 冰霜附魔", "path": "res://addons/vfx_library_pro/shaders_pro/elemental_aura.gdshader", "element_type": 1},
		{"name": "⚡ 雷电附魔", "path": "res://addons/vfx_library_pro/shaders_pro/elemental_aura.gdshader", "element_type": 2},
		{"name": "☠️ 毒素附魔", "path": "res://addons/vfx_library_pro/shaders_pro/elemental_aura.gdshader", "element_type": 3},
		{"name": "🌑 暗影附魔", "path": "res://addons/vfx_library_pro/shaders_pro/elemental_aura.gdshader", "element_type": 4},
		{"name": "🔥 火焰燃烧", "path": "res://addons/vfx_library_pro/shaders_pro/flame.gdshader"},
		{"name": "🌊 水面波纹", "path": "res://addons/vfx_library_pro/shaders_pro/water_surface.gdshader"},
		{"name": "⚡ 闪电电流", "path": "res://addons/vfx_library_pro/shaders_pro/lightning.gdshader"},
		{"name": "❄️ 冰霜结晶", "path": "res://addons/vfx_library_pro/shaders_pro/frost.gdshader"},
		{"name": "🌀 次元裂缝", "path": "res://addons/vfx_library_pro/shaders_pro/dimensional_rift.gdshader"},
		{"name": "�️ 能量护盾", "path": "res://addons/vfx_library_pro/shaders_pro/energy_shield.gdshader"},
		{"name": "💻 矩阵代码", "path": "res://addons/vfx_library_pro/shaders_pro/matrix_code.gdshader"},
		{"name": "� 赛博扫描", "path": "res://addons/vfx_library_pro/shaders_pro/cyberpunk_scan.gdshader"},
		{"name": "🌈 彩虹光环", "path": "res://addons/vfx_library_pro/shaders_pro/rainbow_aura.gdshader"},
		{"name": "� 水晶化", "path": "res://addons/vfx_library_pro/shaders_pro/crystallize.gdshader"},
		{"name": "🌪️ 漩涡扭曲", "path": "res://addons/vfx_library_pro/shaders_pro/vortex.gdshader"},
		{"name": "⭐ 星光闪烁", "path": "res://addons/vfx_library_pro/shaders_pro/starlight.gdshader"},
	]
	
	for shader in shaders_data:
		shader_list.add_item(shader["name"])
	
	print("✓ Shader列表: %d 个" % shaders_data.size())


func _on_particle_selected(index: int) -> void:
	current_particle_index = index
	# 清除其他列表的选择
	current_ui_index = -1
	current_shader_index = -1
	# ui_list.deselect_all()
	shader_list.deselect_all()
	
	var effect = particle_effects_data[index]
	update_info("粒子: " + effect["name"], "右键点击屏幕生成粒子特效")
	print("选择粒子特效: %s" % effect["name"])


func _on_ui_selected(index: int) -> void:
	current_ui_index = index
	# 清除其他列表的选择
	current_particle_index = -1
	current_shader_index = -1
	particle_list.deselect_all()
	shader_list.deselect_all()
	
	var effect = ui_effects_data[index]
	update_info("UI: " + effect["name"], "右键点击屏幕生成UI特效")
	print("选择UI特效: %s" % effect["name"])


func _on_shader_selected(index: int) -> void:
	current_shader_index = index
	# 清除其他列表的选择
	current_particle_index = -1
	current_ui_index = -1
	particle_list.deselect_all()
	# ui_list.deselect_all()
	
	var shader = shaders_data[index]
	update_info("Shader: " + shader["name"], "双击应用着色器")
	print("选择Shader: %s" % shader["name"])


func _on_shader_activated(index: int) -> void:
	"""双击shader列表项时自动应用shader"""
	current_shader_index = index
	_on_apply_shader()


func _on_apply_shader() -> void:
	if current_shader_index < 0:
		print("请先选择一个shader")
		return
	
	shader_animation_time = 0.0
	var shader_data = shaders_data[current_shader_index]
	
	# 确保shader_test_sprite存在
	if not shader_test_sprite:
		push_error("shader_test_sprite 不存在")
		return
	
	var shader = load(shader_data["path"])
	print_debug("尝试加载shader: %s 资源: %s" % [shader_data["path"], shader])
	
	if not shader:
		push_error("无法加载shader: %s" % shader_data["path"])
		return
	
	# 检查shader是否是有效的Shader对象
	if not shader is Shader:
		push_error("加载的不是有效的Shader: %s" % shader_data["path"])
		return
	
	var shader_mat = ShaderMaterial.new()
	shader_mat.shader = shader

	# 如果shader未正确编译，shader_mat.shader 可能为 null
	if not shader_mat.shader:
		push_error("Shader分配失败（未正确编译）: %s" % shader_data["path"])
		return
	
	# 根据不同shader设置初始参数
	var shader_name = shader_data["name"]
	if "时间扭曲" in shader_name:
		shader_mat.set_shader_parameter("time_scale", 0.3)
		shader_mat.set_shader_parameter("distortion_strength", 0.3)  # 增强扭曲效果
		shader_mat.set_shader_parameter("wave_speed", 2.0)
	elif "全息" in shader_name:
		shader_mat.set_shader_parameter("hologram_alpha", 0.7)
		shader_mat.set_shader_parameter("scan_line_speed", 2.0)
	elif "附魔" in shader_name:
		# 根据选择的元素类型设置参数
		var element_type = shader_data.get("element_type", 0)
		shader_mat.set_shader_parameter("element_type", element_type)
		# 简化版附魔效果参数（不再使用粒子系统）
		match element_type:
			0: # 火焰
				shader_mat.set_shader_parameter("intensity", 0.85)
				shader_mat.set_shader_parameter("flow_speed", 2.0)
			1: # 冰霜
				shader_mat.set_shader_parameter("intensity", 0.75)
				shader_mat.set_shader_parameter("flow_speed", 0.8)
			2: # 雷电
				shader_mat.set_shader_parameter("intensity", 0.95)
				shader_mat.set_shader_parameter("flow_speed", 3.0)
			3: # 毒素
				shader_mat.set_shader_parameter("intensity", 0.8)
				shader_mat.set_shader_parameter("flow_speed", 1.2)
			4: # 暗影
				shader_mat.set_shader_parameter("intensity", 0.85)
				shader_mat.set_shader_parameter("flow_speed", 1.5)
		print("  - 元素类型: %d, intensity: %f, flow_speed: %f" % [element_type, shader_mat.get_shader_parameter("intensity"), shader_mat.get_shader_parameter("flow_speed")])
	elif "故障" in shader_name:
		shader_mat.set_shader_parameter("glitch_amount", 0.8)  # 增强故障效果
		shader_mat.set_shader_parameter("color_offset", 0.05)
	elif "能量脉冲" in shader_name:
		shader_mat.set_shader_parameter("pulse_speed", 2.0)
		shader_mat.set_shader_parameter("pulse_width", 0.3)
	elif "火焰燃烧" in shader_name:
		shader_mat.set_shader_parameter("flame_speed", 2.0)
		shader_mat.set_shader_parameter("flame_intensity", 1.0)
	elif "水面波纹" in shader_name:
		shader_mat.set_shader_parameter("wave_speed", 1.0)
		shader_mat.set_shader_parameter("wave_amplitude", 0.02)
		shader_mat.set_shader_parameter("wave_frequency", 8.0)
		shader_mat.set_shader_parameter("reflection_strength", 0.4)
	elif "闪电电流" in shader_name:
		shader_mat.set_shader_parameter("lightning_speed", 3.0)
		shader_mat.set_shader_parameter("branch_density", 1.0)
		shader_mat.set_shader_parameter("intensity", 1.0)
	elif "冰霜结晶" in shader_name:
		shader_mat.set_shader_parameter("frost_amount", 0.6)
		shader_mat.set_shader_parameter("ice_speed", 0.5)
	elif "次元裂缝" in shader_name:
		shader_mat.set_shader_parameter("intensity", 1.2)
		shader_mat.set_shader_parameter("rift_width", 0.08)
		shader_mat.set_shader_parameter("distortion_strength", 0.15)
	elif "能量护盾" in shader_name:
		shader_mat.set_shader_parameter("intensity", 1.0)
		shader_mat.set_shader_parameter("hex_scale", 20.0)
		shader_mat.set_shader_parameter("pulse_speed", 2.0)
		shader_mat.set_shader_parameter("impact_point", Vector2(0.5, 0.5))
		shader_mat.set_shader_parameter("impact_strength", 0.0)
		# 启动冲击动画
		_animate_shield_impact(shader_mat)
	elif "矩阵代码" in shader_name:
		shader_mat.set_shader_parameter("speed", 2.0)
		shader_mat.set_shader_parameter("density", 0.5)
		shader_mat.set_shader_parameter("overlay_strength", 0.7)
	elif "赛博扫描" in shader_name:
		shader_mat.set_shader_parameter("scan_speed", 2.0)
		shader_mat.set_shader_parameter("line_density", 20.0)
		shader_mat.set_shader_parameter("grid_intensity", 0.3)
	elif "彩虹光环" in shader_name:
		shader_mat.set_shader_parameter("intensity", 1.0)
		shader_mat.set_shader_parameter("speed", 2.0)
		shader_mat.set_shader_parameter("wave_count", 3.0)
		shader_mat.set_shader_parameter("glow_size", 0.3)
	elif "水晶化" in shader_name:
		shader_mat.set_shader_parameter("crystal_amount", 0.5)
		shader_mat.set_shader_parameter("crystal_size", 20.0)
		shader_mat.set_shader_parameter("refraction_strength", 0.03)
		shader_mat.set_shader_parameter("sparkle_intensity", 1.0)
	elif "漩涡扭曲" in shader_name:
		shader_mat.set_shader_parameter("vortex_strength", 1.0)
		shader_mat.set_shader_parameter("rotation_speed", 2.0)
		shader_mat.set_shader_parameter("vortex_center", Vector2(0.5, 0.5))
		shader_mat.set_shader_parameter("vortex_radius", 0.5)
	elif "星光闪烁" in shader_name:
		shader_mat.set_shader_parameter("star_density", 0.5)
		shader_mat.set_shader_parameter("twinkle_speed", 2.0)
		shader_mat.set_shader_parameter("star_size", 3.0)
		shader_mat.set_shader_parameter("glow_intensity", 1.0)
	
	# 先将material设置为null，强制渲染器释放之前的shader
	shader_test_sprite.material = null
	# 等待下一帧再应用新shader，确保渲染器准备好
	await get_tree().process_frame
	
	shader_test_sprite.material = shader_mat
	
	# 调试：验证shader是否真的应用了
	if shader_test_sprite.material and shader_test_sprite.material is ShaderMaterial:
		var mat = shader_test_sprite.material as ShaderMaterial
		if mat.shader:
			print("✓ 已应用shader: %s" % shader_data["name"])
			print("  - Shader路径: %s" % shader_data["path"])
			print("  - Material有效: %s" % (mat != null))
			print("  - Shader有效: %s" % (mat.shader != null))
		else:
			push_error("✗ Shader应用失败 - shader为null")
	else:
		push_error("✗ Material应用失败")


func _on_remove_shader() -> void:
	shader_test_sprite.material = null
	print("✓ 已移除shader")


func _on_clear_all() -> void:
	print("清除所有特效...")
	var cleared_count = 0
	
	for effect_node in spawned_effects:
		if is_instance_valid(effect_node):
			effect_node.queue_free()
			cleared_count += 1
	
	spawned_effects.clear()
	update_info("已清除", "清除了 %d 个特效" % cleared_count)
	print("✓ 已清除 %d 个特效" % cleared_count)


func spawn_particle_effect(pos: Vector2) -> void:
	if current_particle_index < 0:
		return
	
	var effect = particle_effects_data[current_particle_index]
	var func_name = effect["func"]
	
	print("生成粒子特效: %s 于 %v" % [effect["name"], pos])
	
	match func_name:
		"sword_slash":
			var start_pos = pos + Vector2(-100, 0)
			var end_pos = pos + Vector2(100, 0)
			VFXPro.spawn_sword_slash(start_pos, end_pos, Color.CYAN)
		
		"explosion":
			VFXPro.spawn_explosion_wave(pos, 200.0, Color(1, 0.6, 0))
		
		"shield":
			var holder = Node2D.new()
			add_child(holder)
			holder.global_position = pos
			spawned_effects.append(holder)
			var shield_effect = VFXPro.spawn_energy_shield(holder, 3.0, Color(0.3, 0.9, 1))
			if shield_effect:
				spawned_effects.append(shield_effect)
		
		"charging":
			var holder = Node2D.new()
			add_child(holder)
			holder.global_position = pos
			spawned_effects.append(holder)
			var charge_effect = VFXPro.spawn_charging_effect(holder, 2.0, Color(1, 1, 0.3))
			if charge_effect:
				spawned_effects.append(charge_effect)
		
		"critical":
			VFXPro.spawn_critical_hit(pos, 2.0)


# 自动清理粒子的辅助函数
func _auto_cleanup_particles(particles: CPUParticles2D, lifetime: float) -> void:
	await get_tree().create_timer(lifetime + 0.5).timeout
	if is_instance_valid(particles):
		particles.queue_free()


# 能量护盾冲击动画
func _animate_shield_impact(shader_mat: ShaderMaterial) -> void:
	while shader_test_sprite.material == shader_mat:
		# 等待随机时间 (1-3秒)
		await get_tree().create_timer(randf_range(1.5, 3.0)).timeout
		if shader_test_sprite.material != shader_mat:
			break
		
		# 随机冲击点
		var impact_x = randf_range(0.2, 0.8)
		var impact_y = randf_range(0.2, 0.8)
		shader_mat.set_shader_parameter("impact_point", Vector2(impact_x, impact_y))
		
		# 冲击波扩散 (0 -> 1)
		var t = 0.0
		while t <= 1.0 and shader_test_sprite.material == shader_mat:
			shader_mat.set_shader_parameter("impact_strength", t)
			t += 0.03
			await get_tree().create_timer(0.016).timeout
		
		# 重置
		if shader_test_sprite.material == shader_mat:
			shader_mat.set_shader_parameter("impact_strength", 0.0)


func spawn_ui_effect(pos: Vector2) -> void:
	if current_ui_index < 0:
		return
	
	var effect = ui_effects_data[current_ui_index]
	var func_name = effect["func"]
	
	print("生成UI特效: %s 于 %v" % [effect["name"], pos])
	
	match func_name:
		"fade":
			VFXPro.spawn_page_transition("fade", 1.0)
		
		"slide":
			VFXPro.spawn_page_transition("slide_left", 1.0)
		
		"zoom":
			VFXPro.spawn_page_transition("zoom_in", 1.0)


func update_info(title: String, description: String) -> void:
	info_label.text = "当前特效: " + title + "\n" + description


func check_autoloads() -> void:
	"""检查必要的 Autoload 是否配置"""
	print("\n--- 检查 Autoload 配置 ---")
	
	if has_node("/root/VFXPro"):
		print("✓ VFXPro 已配置")
	else:
		push_error("✗ VFXPro 未配置！请在项目设置中添加 Autoload")
	
	print("-------------------------\n")


func _input(event: InputEvent) -> void:
	"""处理输入事件"""
	# 鼠标右键在鼠标位置生成特效
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var global_pos = get_global_mouse_position()
			
			# 根据当前选中的类型生成特效
			if current_particle_index >= 0:
				spawn_particle_effect(global_pos)
			elif current_ui_index >= 0:
				spawn_ui_effect(global_pos)
	
	# ESC 退出
	elif event.is_action_pressed("ui_cancel"):
		get_tree().quit()

	# F12 执行shader诊断
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		diagnose_shaders_async()


func _process(delta: float) -> void:
	"""更新shader动画"""
	if shader_test_sprite.material == null:
		return
	
	shader_animation_time += delta
	
	if current_shader_index < 0:
		return
	
	var shader_name = shaders_data[current_shader_index]["name"]
	var shader_mat = shader_test_sprite.material as ShaderMaterial
	if not shader_mat:
		return
	
	# 关键: 检查ShaderMaterial的shader是否有效
	if not shader_mat.shader:
		return
	
	# 为不同shader添加动画
	if "时间扭曲" in shader_name:
		var distortion = 0.1 + sin(shader_animation_time * 2.0) * 0.05
		shader_mat.set_shader_parameter("distortion_strength", distortion)
	
	elif "全息" in shader_name:
		var alpha = 0.5 + sin(shader_animation_time * 1.5) * 0.2
		shader_mat.set_shader_parameter("hologram_alpha", alpha)
	
	
	elif "故障" in shader_name:
		var glitch = abs(sin(shader_animation_time * 3.0)) * 0.8
		shader_mat.set_shader_parameter("glitch_amount", glitch)
	
	elif "能量脉冲" in shader_name:
		# 脉冲动画已在shader内部处理
		pass
	
	elif "火焰" in shader_name:
		var intensity = 0.8 + sin(shader_animation_time * 2.0) * 0.3
		shader_mat.set_shader_parameter("flame_intensity", intensity)
	
	elif "水面" in shader_name:
		var amplitude = 0.015 + sin(shader_animation_time * 0.5) * 0.005
		shader_mat.set_shader_parameter("wave_amplitude", amplitude)
	
	elif "闪电" in shader_name:
		var intensity = 0.8 + abs(sin(shader_animation_time * 5.0)) * 0.5
		shader_mat.set_shader_parameter("intensity", intensity)
	
	elif "冰霜" in shader_name:
		var coverage = 0.5 + sin(shader_animation_time * 0.3) * 0.2
		shader_mat.set_shader_parameter("frost_coverage", coverage)
	elif "附魔" in shader_name:
		var glow = 0.5 + 0.5 * sin(shader_animation_time * 2.0)
		var intensity = current_shader_base_intensity * glow
		shader_mat.set_shader_parameter("intensity", intensity)


func diagnose_shaders_async() -> void:
	"""Diagnostic: Load every shader, assign to a ShaderMaterial, wait a frame, and print whether assignment succeeded.
    Use this to find which shader might fail to compile on the current machine.
	"""
	print("--- Shader Diagnostic Start ---")
	for shader_data in shaders_data:
		var path = shader_data["path"]
		var shader = load(path)
		if not shader:
			push_error("无法加载shader资源: %s" % path)
			continue
		var m = ShaderMaterial.new()
		m.shader = shader
		await get_tree().process_frame
		if not m.shader:
			push_error("Shader 未成功分配（可能编译失败）: %s" % path)
		else:
			print("✓ Shader OK: %s" % path)
	print("--- Shader Diagnostic End ---")

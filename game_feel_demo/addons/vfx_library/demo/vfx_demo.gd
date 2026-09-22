extends Node2D
## 特效系统测试场景 - 使用列表选择特效

# 常量定义
const DEFAULT_WATER_SPLASH_SIZE = 3.0
const DEFAULT_DUST_CLOUD_SIZE = 3.0
const DEFAULT_POISON_CLOUD_SIZE = 2.0
const DEFAULT_MAGIC_AURA_RADIUS = 60.0
const DEFAULT_LEAVES_WIDTH = 300.0
const DEFAULT_RAIN_AREA_WIDTH = 400.0
const DEFAULT_SUMMON_CIRCLE_RADIUS = 60.0
const DEFAULT_WATERFALL_MIST_WIDTH = 80.0
const DEFAULT_ASH_AREA_SIZE = Vector2(60, 20)
const DEFAULT_PARTICLE_COUNT = 20

# UI 节点引用
@onready var effect_list: ItemList = $UI/Panel/VBox/ScrollContainer/EffectList
@onready var clear_button: Button = $UI/Panel/VBox/ButtonContainer/ClearButton
@onready var shader_list: ItemList = $UI/ShaderPanel/VBox2/ScrollContainer2/ShaderList
@onready var apply_shader_button: Button = $UI/ShaderPanel/VBox2/ShaderButtonContainer/ApplyShaderButton
@onready var remove_shader_button: Button = $UI/ShaderPanel/VBox2/ShaderButtonContainer/RemoveShaderButton
@onready var shader_test_sprite: Sprite2D = $ShaderTestSprite

# 特效配置数据
var effects_data = []
var current_effect_index = 0

# Shader配置数据
var shaders_data = []
var current_shader_index = -1
var shader_animation_time = 0.0  # 用于shader动画

# 用于跟踪所有生成的特效节点
var spawned_effects = []


func _ready():
	print("=== VFX Test Scene Started ===")
	
	# 检查 Autoload 是否配置
	check_autoloads()
	
	# 初始化特效列表
	setup_effects_list()
	
	# 初始化shader列表
	setup_shaders_list()
	
	# 连接信号
	if effect_list:
		effect_list.item_selected.connect(_on_effect_selected)
	if clear_button:
		clear_button.pressed.connect(_on_clear_button_pressed)
	if shader_list:
		shader_list.item_selected.connect(_on_shader_selected)
	if apply_shader_button:
		apply_shader_button.pressed.connect(_on_apply_shader_pressed)
	if remove_shader_button:
		remove_shader_button.pressed.connect(_on_remove_shader_pressed)


func setup_effects_list():
	"""设置特效列表"""
	effects_data = [
		# 基础环境特效
		{"name": "🔥 火焰 (Torch Fire)", "type": "env", "func": "create_torch"},
		{"name": "💧 水花 (Water Splash)", "type": "env", "func": "create_water_splash"},
		{"name": "💨 尘土 (Dust Cloud)", "type": "env", "func": "create_dust_cloud"},
		{"name": "✨ 火花 (Sparks)", "type": "env", "func": "create_sparks"},
		{"name": "☁️ 蒸汽 (Steam)", "type": "env", "func": "create_steam"},
		{"name": "🌟 萤火虫 (Fireflies)", "type": "env", "func": "create_fireflies"},
		{"name": "🔮 魔法光环 (Magic Aura)", "type": "env", "func": "create_magic_aura"},
		{"name": "☠️ 毒雾 (Poison Cloud)", "type": "env", "func": "create_poison_cloud"},
		{"name": "🍂 落叶 (Falling Leaves)", "type": "env", "func": "create_falling_leaves"},
		{"name": "🪵 木屑 (Wood Debris)", "type": "env_oneshot", "func": "create_wood_debris"},
		
		# 战斗粒子（不同颜色）
		{"name": "🔴 火粒子 (Fire Particle)", "type": "combat", "element": "fire"},
		{"name": "🔵 冰粒子 (Ice Particle)", "type": "combat", "element": "ice"},
		{"name": "🟢 毒粒子 (Poison Particle)", "type": "combat", "element": "poison"},
		{"name": "🟡 雷粒子 (Lightning Particle)", "type": "combat", "element": "lightning"},
		{"name": "🟣 暗影粒子 (Shadow Particle)", "type": "combat", "element": "shadow"},
		
		# 新增战斗特效
		{"name": "🩸 血液飞溅 (Blood Splash)", "type": "vfx", "func": "spawn_blood_splash"},
		{"name": "💥 能量爆发 (Energy Burst)", "type": "vfx", "func": "spawn_energy_burst"},
		{"name": "💚 治疗效果 (Heal Effect)", "type": "vfx", "func": "spawn_heal_effect"},
		{"name": "🛡️ 护盾破碎 (Shield Break)", "type": "vfx", "func": "spawn_shield_break"},
		{"name": "🌀 连击特效 (Combo Ring)", "type": "vfx", "func": "spawn_combo_ring"},
		{"name": "💨 跳跃尘土 (Jump Dust)", "type": "vfx", "func": "spawn_jump_dust"},
		{"name": "👻 冲刺残影 (Dash Trail)", "type": "vfx_continuous", "func": "create_dash_trail"},
		{"name": "⚡ 墙壁火花 (Wall Slide Spark)", "type": "vfx_continuous", "func": "create_wall_slide_spark"},
		
		# 法术/技能特效
		{"name": "🌀 传送门漩涡 (Portal Vortex)", "type": "env_continuous", "func": "create_portal"},
		{"name": "⚡ 电流迸发 (Electric Burst)", "type": "env_oneshot", "func": "spawn_lightning_chain"},
		{"name": "❄️ 冰霜 (Ice Frost)", "type": "env_oneshot", "func": "spawn_ice_frost"},
		{"name": "🔥 火球拖尾 (Fireball Trail)", "type": "env_continuous", "func": "create_fireball_trail"},
		{"name": "🔯 召唤阵 (Summon Circle)", "type": "env_continuous", "func": "create_summon_circle"},
		
		# 环境特效
		{"name": "🌧️ 雨滴 (Rain)", "type": "env_continuous", "func": "create_rain"},
		{"name": "❄️ 雪花 (Snow)", "type": "env_continuous", "func": "create_snow"},
		{"name": "💦 瀑布水雾 (Waterfall Mist)", "type": "env_continuous", "func": "create_waterfall_mist"},
		{"name": "🔥 篝火烟雾 (Campfire Smoke)", "type": "env_continuous", "func": "create_campfire_smoke"},
		{"name": "🕯️ 蜡烛火焰 (Candle Flame)", "type": "env_continuous", "func": "create_candle_flame"},
		{"name": "🌫️ 灰烬飘散 (Ash Particles)", "type": "env_continuous", "func": "create_ash_particles"},
	]
	
	# 填充列表
	if effect_list:
		for i in range(effects_data.size()):
			effect_list.add_item(effects_data[i]["name"])
		
		print("✓ 已加载 %d 个特效" % effects_data.size())


func _on_effect_selected(index: int):
	"""选择特效时调用"""
	current_effect_index = index
	print("选择特效: %s" % effects_data[index]["name"])


func _on_clear_button_pressed():
	"""清除所有生成的特效"""
	print("清除所有特效...")
	var cleared_count = 0
	
	for effect_node in spawned_effects:
		if is_instance_valid(effect_node):
			effect_node.queue_free()
			cleared_count += 1
	
	spawned_effects.clear()
	print("✓ 已清除 %d 个特效" % cleared_count)


func spawn_current_effect(pos: Vector2):
	"""在指定位置生成当前选中的特效"""
	if current_effect_index >= effects_data.size():
		return
	
	var effect = effects_data[current_effect_index]
	print("生成特效: %s 于位置 %v" % [effect["name"], pos])
	
	match effect["type"]:
		"env":
			spawn_env_effect(effect, pos)
		"env_oneshot":
			spawn_env_oneshot(effect, pos)
		"combat":
			spawn_combat_particle(effect, pos)
		"vfx":
			spawn_vfx_effect(effect, pos)
		"vfx_continuous":
			spawn_vfx_continuous(effect, pos)  # 异步函数，但这里不需要等待完成
		"env_continuous":
			spawn_env_continuous(effect, pos)  # 异步函数，但这里不需要等待完成


func spawn_env_effect(effect: Dictionary, pos: Vector2):
	"""生成环境特效（持续）"""
	if not has_node("/root/EnvVFX"):
		push_error("EnvVFX 未配置")
		return
	
	var env_vfx = get_node("/root/EnvVFX")
	var func_name = effect["func"]
	
	if env_vfx.has_method(func_name):
		# 根据不同的函数调用方式
		if func_name == "create_water_splash":
			# create_water_splash 是异步的，会自动清理
			# 使用更大的 size 参数让粒子更明显
			env_vfx.call(func_name, pos, DEFAULT_WATER_SPLASH_SIZE)
		elif func_name == "create_dust_cloud":
			# create_dust_cloud 是异步的，会自动清理
			# 使用更大的 size 参数让粒子更明显
			env_vfx.call(func_name, pos, DEFAULT_DUST_CLOUD_SIZE)
		elif func_name == "create_poison_cloud":
			# create_poison_cloud 返回粒子节点，可以手动管理
			var particle = env_vfx.call(func_name, pos, DEFAULT_POISON_CLOUD_SIZE)
			if particle:
				spawned_effects.append(particle)
		else:
			# 需要 holder 的持续特效
			var holder = Node2D.new()
			add_child(holder)
			holder.global_position = pos
			spawned_effects.append(holder)
			
			if func_name == "create_magic_aura":
				# 增大半径让光环更明显
				env_vfx.call(func_name, holder, Color(0.5, 0.3, 1.0), DEFAULT_MAGIC_AURA_RADIUS)
			elif func_name == "create_falling_leaves":
				env_vfx.call(func_name, holder, DEFAULT_LEAVES_WIDTH)
			elif func_name == "create_sparks":
				# 火花需要手动触发发射
				var sparks = env_vfx.call(func_name, holder, Vector2.ZERO, false)
				if sparks:
					sparks.emitting = true
			else:
				env_vfx.call(func_name, holder, Vector2.ZERO)
	else:
		push_error("方法不存在: EnvVFX.%s" % func_name)


func spawn_env_oneshot(effect: Dictionary, pos: Vector2):
	"""生成环境一次性特效"""
	if not has_node("/root/EnvVFX"):
		push_error("EnvVFX 未配置")
		return
	
	var env_vfx = get_node("/root/EnvVFX")
	var func_name = effect["func"]
	
	if env_vfx.has_method(func_name):
		# 调用函数（可能是异步的，但我们不等待）
		# 直接调用，让协程在后台运行
		if func_name == "create_wood_debris":
			env_vfx.call(func_name, pos, Vector2.UP)
		else:
			env_vfx.call(func_name, pos)
		# 注意：这些函数会自动清理，不需要手动管理
	else:
		push_error("方法不存在: EnvVFX.%s" % func_name)


func spawn_combat_particle(effect: Dictionary, pos: Vector2):
	"""生成战斗粒子（不同颜色）"""
	if not has_node("/root/VFX"):
		push_error("VFX 未配置")
		return
	
	var vfx = get_node("/root/VFX")
	var element = effect.get("element", "fire")
	
	# 将元素名称转换为颜色
	var color_map = {
		"fire": Color(0.784, 0.238, 0.0, 1.0),
		"ice": Color(0.5, 0.8, 1.0),
		"poison": Color(0.3, 1.0, 0.3),
		"lightning": Color(1.0, 1.0, 0.3),
		"shadow": Color(0.7, 0.3, 1.0)
	}
	
	var particle_color = color_map.get(element, Color.RED)
	
	if vfx.has_method("spawn_particles"):
		# spawn_particles 是异步的，会自动清理
		vfx.spawn_particles(pos, particle_color, DEFAULT_PARTICLE_COUNT)
	else:
		push_error("方法不存在: VFX.spawn_particles")


func spawn_vfx_effect(effect: Dictionary, pos: Vector2):
	"""生成 VFX 特效（一次性）"""
	if not has_node("/root/VFX"):
		push_error("VFX 未配置")
		return
	
	var vfx = get_node("/root/VFX")
	var func_name = effect["func"]
	
	if vfx.has_method(func_name):
		# 调用函数（可能是异步的，但我们不等待）
		# 直接调用，让协程在后台运行
		if func_name == "spawn_energy_burst":
			vfx.call(func_name, pos, Color.CYAN)
		else:
			vfx.call(func_name, pos)
		# 注意：这些函数会自动清理，不需要手动管理
	else:
		push_error("方法不存在: VFX.%s" % func_name)


func spawn_vfx_continuous(effect: Dictionary, pos: Vector2):
	"""生成 VFX 持续特效"""
	if not has_node("/root/VFX"):
		push_error("VFX 未配置")
		return
	
	var vfx = get_node("/root/VFX")
	var func_name = effect["func"]
	
	if vfx.has_method(func_name):
		# 创建一个容器节点
		var holder = Node2D.new()
		add_child(holder)
		holder.global_position = pos
		spawned_effects.append(holder)
		
		var _result = vfx.call(func_name, holder, Vector2.ZERO)
	else:
		push_error("方法不存在: VFX.%s" % func_name)


func spawn_env_continuous(effect: Dictionary, pos: Vector2):
	"""生成环境持续特效"""
	if not has_node("/root/EnvVFX"):
		push_error("EnvVFX 未配置")
		return
	
	var env_vfx = get_node("/root/EnvVFX")
	var func_name = effect["func"]
	
	if env_vfx.has_method(func_name):
		# 创建一个临时容器节点
		var holder = Node2D.new()
		add_child(holder)
		holder.global_position = pos
		spawned_effects.append(holder)
		
		# 根据不同的函数调用方式
		if func_name in ["create_rain", "create_snow"]:
			var _result = env_vfx.call(func_name, holder, DEFAULT_RAIN_AREA_WIDTH)
		elif func_name == "create_summon_circle":
			var _result = env_vfx.call(func_name, holder, Vector2.ZERO, DEFAULT_SUMMON_CIRCLE_RADIUS)
		elif func_name == "create_waterfall_mist":
			var _result = env_vfx.call(func_name, holder, Vector2.ZERO, DEFAULT_WATERFALL_MIST_WIDTH)
		elif func_name == "create_ash_particles":
			var _result = env_vfx.call(func_name, holder, DEFAULT_ASH_AREA_SIZE)
		else:
			var _result = env_vfx.call(func_name, holder, Vector2.ZERO)
	else:
		push_error("方法不存在: EnvVFX.%s" % func_name)


func check_autoloads():
	"""检查必要的 Autoload 是否配置"""
	print("\n--- 检查 Autoload 配置 ---")
	
	if has_node("/root/EnvVFX"):
		print("✓ EnvVFX 已配置")
	else:
		push_error("✗ EnvVFX 未配置！请在项目设置中添加 Autoload")
	
	if has_node("/root/VFX"):
		print("✓ VFX 已配置")
	else:
		push_error("✗ VFX 未配置！请在项目设置中添加 Autoload")
	
	print("-------------------------\n")


# ===== Shader 相关函数 =====

func setup_shaders_list():
	"""初始化shader列表"""
	shaders_data = [
		{"name": "🔥 燃烧", "path": "res://addons/vfx_library/shaders/burning.gdshader"},
		{"name": "❄️ 冰冻", "path": "res://addons/vfx_library/shaders/frozen.gdshader"},
		{"name": "☠️ 中毒", "path": "res://addons/vfx_library/shaders/poison.gdshader"},
		{"name": "🗿 石化", "path": "res://addons/vfx_library/shaders/petrify.gdshader"},
		{"name": "👻 隐身", "path": "res://addons/vfx_library/shaders/invisibility.gdshader"},
		{"name": "💥 溶解", "path": "res://addons/vfx_library/shaders/dissolve.gdshader"},
		{"name": "⚡ 闪烁", "path": "res://addons/vfx_library/shaders/blink.gdshader"},
		{"name": "🌊 水面", "path": "res://addons/vfx_library/shaders/water_surface.gdshader"},
		{"name": "🔆 闪白", "path": "res://addons/vfx_library/shaders/flash_white.gdshader"},
		{"name": "🎨 变色", "path": "res://addons/vfx_library/shaders/color_change.gdshader"},
		{"name": "🌫️ 雾气", "path": "res://addons/vfx_library/shaders/fog.gdshader"},
		{"name": "🔥 热扭曲", "path": "res://addons/vfx_library/shaders/heat_distortion.gdshader"},
		{"name": "🌀 径向模糊", "path": "res://addons/vfx_library/shaders/radial_blur.gdshader"},
		{"name": "🎭 灰度", "path": "res://addons/vfx_library/shaders/grayscale.gdshader"},
		{"name": "🌈 色差", "path": "res://addons/vfx_library/shaders/chromatic_aberration.gdshader"},
		{"name": "🔲 晕影", "path": "res://addons/vfx_library/shaders/vignette.gdshader"},
		{"name": "✨ 轮廓发光", "path": "res://addons/vfx_library/shaders/outline_glow.gdshader"},
	]
	
	for shader_data in shaders_data:
		shader_list.add_item(shader_data["name"])
	
	print("✓ Shader列表初始化完成，共 %d 个shader" % shaders_data.size())


func _on_shader_selected(index: int):
	"""当shader被选中"""
	current_shader_index = index
	print("选择shader: %s" % shaders_data[index]["name"])


func _on_apply_shader_pressed():
	"""应用选中的shader到测试精灵"""
	if current_shader_index < 0 or current_shader_index >= shaders_data.size():
		print("请先选择一个shader")
		return
	
	# 重置动画时间
	shader_animation_time = 0.0
	
	var shader_data = shaders_data[current_shader_index]
	var shader_path = shader_data["path"]
	
	# 加载shader
	var shader = load(shader_path)
	if not shader:
		push_error("无法加载shader: %s" % shader_path)
		return
	
	# 创建ShaderMaterial并应用
	var shader_mat = ShaderMaterial.new()
	shader_mat.shader = shader
	
	# 根据不同shader设置参数
	var shader_name = shader_data["name"]
	if "燃烧" in shader_name:
		shader_mat.set_shader_parameter("burn_amount", 0.5)
	elif "冰冻" in shader_name:
		shader_mat.set_shader_parameter("freeze_amount", 0.7)
	elif "中毒" in shader_name:
		shader_mat.set_shader_parameter("poison_amount", 0.6)
	elif "石化" in shader_name:
		shader_mat.set_shader_parameter("petrify_amount", 0.8)
	elif "隐身" in shader_name:
		shader_mat.set_shader_parameter("invisibility_amount", 0.6)
		shader_mat.set_shader_parameter("distortion_amount", 0.02)
	elif "溶解" in shader_name:
		shader_mat.set_shader_parameter("dissolve_amount", 0.5)
		# 创建简单的噪声纹理
		var noise_image = Image.create(256, 256, false, Image.FORMAT_L8)
		for x in range(256):
			for y in range(256):
				var noise_val = randf()
				noise_image.set_pixel(x, y, Color(noise_val, noise_val, noise_val))
		var noise_texture = ImageTexture.create_from_image(noise_image)
		shader_mat.set_shader_parameter("dissolve_texture", noise_texture)
	elif "闪烁" in shader_name:
		shader_mat.set_shader_parameter("blink_speed", 10.0)
		shader_mat.set_shader_parameter("min_alpha", 0.3)
	elif "水面" in shader_name:
		shader_mat.set_shader_parameter("wave_speed", 2.0)
		shader_mat.set_shader_parameter("wave_strength", 0.02)
	elif "闪白" in shader_name:
		shader_mat.set_shader_parameter("flash_amount", 0.8)
	elif "变色" in shader_name:
		shader_mat.set_shader_parameter("target_color", Color(1.0, 0.3, 0.3))
		shader_mat.set_shader_parameter("mix_amount", 0.7)
	elif "雾气" in shader_name:
		shader_mat.set_shader_parameter("fog_density", 0.5)
	elif "热扭曲" in shader_name:
		# 增大扭曲强度，并生成噪声纹理
		shader_mat.set_shader_parameter("distortion_amount", 0.05)
		shader_mat.set_shader_parameter("distortion_speed", 3.0)
		# 生成噪声纹理
		var noise_image = Image.create(128, 128, false, Image.FORMAT_RGB8)
		for x in range(128):
			for y in range(128):
				var noise_r = randf()
				var noise_g = randf()
				noise_image.set_pixel(x, y, Color(noise_r, noise_g, 0.5))
		var noise_texture = ImageTexture.create_from_image(noise_image)
		shader_mat.set_shader_parameter("noise_texture", noise_texture)
	elif "径向模糊" in shader_name:
		# 增大模糊强度
		shader_mat.set_shader_parameter("blur_strength", 0.08)
		shader_mat.set_shader_parameter("blur_center", Vector2(0.5, 0.5))
		shader_mat.set_shader_parameter("samples", 20)
	elif "灰度" in shader_name:
		shader_mat.set_shader_parameter("grayscale_amount", 0.8)
	elif "色差" in shader_name:
		# 增大色差偏移量
		shader_mat.set_shader_parameter("aberration_amount", 0.015)
		shader_mat.set_shader_parameter("aberration_direction", Vector2(1.0, 0.0))
	elif "晕影" in shader_name:
		shader_mat.set_shader_parameter("vignette_intensity", 0.5)
	elif "轮廓发光" in shader_name:
		shader_mat.set_shader_parameter("outline_color", Color(0.3, 0.8, 1.0))
		shader_mat.set_shader_parameter("outline_width", 2.0)
	
	shader_test_sprite.material = shader_mat
	
	print("✓ 已应用shader: %s" % shader_data["name"])


func _on_remove_shader_pressed():
	"""移除测试精灵的shader"""
	shader_test_sprite.material = null
	print("✓ 已移除shader")


func _input(event: InputEvent):
	"""处理输入事件"""
	# 鼠标右键在鼠标位置生成特效
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# 将屏幕坐标转换为全局坐标
			var global_pos = get_global_mouse_position()
			spawn_current_effect(global_pos)
	
	# ESC 退出
	elif event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _process(delta: float):
	"""更新shader动画"""
	if shader_test_sprite.material == null:
		return
	
	shader_animation_time += delta
	
	# 根据当前shader类型更新参数
	if current_shader_index < 0 or current_shader_index >= shaders_data.size():
		return
	
	var shader_name = shaders_data[current_shader_index]["name"]
	var shader_mat = shader_test_sprite.material as ShaderMaterial
	if not shader_mat:
		return
	
	# 为不同shader添加动画
	if "燃烧" in shader_name:
		# 燃烧：从下往上烧
		var burn = (sin(shader_animation_time * 0.5) + 1.0) * 0.5
		shader_mat.set_shader_parameter("burn_amount", burn)
	
	elif "冰冻" in shader_name:
		# 冰冻：渐进冰冻效果
		var freeze = (sin(shader_animation_time * 0.8) + 1.0) * 0.5
		shader_mat.set_shader_parameter("freeze_amount", freeze)
	
	elif "中毒" in shader_name:
		# 中毒：脉动效果
		var poison = 0.4 + sin(shader_animation_time * 3.0) * 0.3
		shader_mat.set_shader_parameter("poison_amount", poison)
	
	elif "石化" in shader_name:
		# 石化：从下往上石化
		var petrify = (sin(shader_animation_time * 0.6) + 1.0) * 0.5
		shader_mat.set_shader_parameter("petrify_amount", petrify)
	
	elif "隐身" in shader_name:
		# 隐身：淡入淡出
		var invis = (sin(shader_animation_time * 1.0) + 1.0) * 0.5
		shader_mat.set_shader_parameter("invisibility_amount", invis)
	
	elif "溶解" in shader_name:
		# 溶解：循环溶解
		var dissolve = (sin(shader_animation_time * 0.7) + 1.0) * 0.5
		shader_mat.set_shader_parameter("dissolve_amount", dissolve)
	
	elif "闪白" in shader_name:
		# 闪白：快速闪烁
		var flash = max(0.0, sin(shader_animation_time * 5.0))
		shader_mat.set_shader_parameter("flash_amount", flash)
	
	elif "变色" in shader_name:
		# 变色：在不同颜色之间切换
		var hue = shader_animation_time * 0.3
		var color = Color.from_hsv(fmod(hue, 1.0), 0.8, 1.0)
		shader_mat.set_shader_parameter("target_color", color)
	
	elif "雾气" in shader_name:
		# 雾气：浓度变化
		var fog = 0.3 + sin(shader_animation_time * 1.5) * 0.2
		shader_mat.set_shader_parameter("fog_density", fog)
	
	elif "热扭曲" in shader_name:
		# 热扭曲：强度波动（扭曲效果更明显）
		var distortion = 0.03 + sin(shader_animation_time * 2.0) * 0.03
		shader_mat.set_shader_parameter("distortion_amount", distortion)
	
	elif "径向模糊" in shader_name:
		# 径向模糊：脉冲效果（从中心向外）
		var blur = 0.04 + abs(sin(shader_animation_time * 1.5)) * 0.06
		shader_mat.set_shader_parameter("blur_strength", blur)
	
	elif "灰度" in shader_name:
		# 灰度：渐变
		var grayscale = (sin(shader_animation_time * 1.0) + 1.0) * 0.5
		shader_mat.set_shader_parameter("grayscale_amount", grayscale)
	
	elif "色差" in shader_name:
		# 色差：RGB分离波动，并改变方向
		var aberration = 0.008 + abs(sin(shader_animation_time * 2.0)) * 0.015
		var angle = shader_animation_time * 0.5
		var direction = Vector2(cos(angle), sin(angle))
		shader_mat.set_shader_parameter("aberration_amount", aberration)
		shader_mat.set_shader_parameter("aberration_direction", direction)
	
	elif "晕影" in shader_name:
		# 晕影：呼吸效果
		var vignette = 0.3 + sin(shader_animation_time * 1.5) * 0.3
		shader_mat.set_shader_parameter("vignette_intensity", vignette)
	
	elif "轮廓发光" in shader_name:
		# 轮廓发光：颜色循环
		var hue = shader_animation_time * 0.5
		var outline_color = Color.from_hsv(fmod(hue, 1.0), 0.8, 1.0)
		shader_mat.set_shader_parameter("outline_color", outline_color)


# 脚本结束

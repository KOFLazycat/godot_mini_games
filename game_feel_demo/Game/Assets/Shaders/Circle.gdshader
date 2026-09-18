shader_type canvas_item;

// 1. 基础配置（纹理）
uniform sampler2D rings_ease_sampler;

// 2. 颜色配置（强化渐变逻辑，新增渐变强度）
uniform bool use_gradient = false; // 渐变/恒定颜色切换
uniform vec3 ring_color : source_color; // 恒定颜色（关闭渐变时生效）
uniform vec3 ring_color_center : source_color; // 渐变中心色
uniform vec3 ring_color_edge : source_color; // 渐变边缘色
uniform bool gradient_smooth = true; // 渐变平滑开关
uniform float gradient_strength : hint_range(1.0, 5.0) = 2.0; // 新增：渐变强度，放大对比度

// 3. 原有可控Uniform（完整保留）
uniform float ring_scroll_speed : hint_range(0.0, 2.0) = 0.5;
uniform float ring_density : hint_range(1.0, 5.0) = 2.0;
uniform float ring_intensity : hint_range(0.0, 2.0) = 0.8;
uniform float soft_base_intensity : hint_range(0.0, 1.0) = 0.35;
uniform float ring_crop_range : hint_range(0.0, 1.0) = 1.0;
uniform bool enable_brightness_pulse = false;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.0;
uniform float pulse_strength : hint_range(0.0, 0.5) = 0.2;

void fragment() {
	// 步骤1：坐标归一化与居中平移
	vec2 c_uv = UV * 2.0 - 1.0;
	
	// 步骤2：中心衰减因子（双层限制，四角无残留）
	float dist = 1.0 - length(c_uv);
	float clamped_dist = clamp(dist, 0.0, 1.0);
	clamped_dist = smoothstep(0.0, ring_crop_range, clamped_dist);
	
	// 步骤3：光环强度计算（完整保留）
	float sample_u = mod(clamped_dist * ring_density + TIME * ring_scroll_speed, 1.0);
	sample_u = smoothstep(0.0, 1.0, sample_u);
	float ring_sample = texture(rings_ease_sampler, vec2(sample_u, 0.0)).x;
	float rings = max(0.0, ring_sample) * clamped_dist;
	// 强化：光环强度归一化，确保渐变绑定后效果稳定
	float ring_strength = smoothstep(0.0, 0.5, rings);

	// 步骤4：可选亮度波动（完整保留）
	float brightness_multiplier = 1.0;
	if (enable_brightness_pulse) {
		brightness_multiplier = 1.0 + sin(TIME * pulse_speed) * pulse_strength;
		brightness_multiplier = clamp(brightness_multiplier, 0.8, 1.2);
	}
	
	// 步骤5：渐变颜色计算（核心优化，确保清晰可见）
	vec3 final_color = ring_color;
	if (use_gradient) {
		// 优化1：混合因子强化，放大渐变差异
		float mix_factor = clamped_dist;
		// 平滑渐变（可选）
		if (gradient_smooth) {
			mix_factor = smoothstep(0.0, 1.0, mix_factor);
		}
		// 优化2：提升渐变对比度，通过gradient_strength放大颜色差异
		vec3 gradient_color = mix(ring_color_edge, ring_color_center, mix_factor);
		gradient_color = pow(gradient_color, vec3(1.0 / gradient_strength)); // 亮度强化
		// 优化3：将渐变与光环强度深度绑定，仅在光环区域显示清晰渐变
		gradient_color = mix(gradient_color, ring_color_center, ring_strength);
		final_color = gradient_color;
	}
	// 叠加亮度波动
	final_color *= brightness_multiplier;
	
	// 步骤6：不透明度计算（完整保留）
	float base_alpha = clamped_dist * soft_base_intensity;
	float ring_alpha = rings * ring_intensity * brightness_multiplier;
	COLOR.a = clamp(base_alpha + ring_alpha, 0.0, 1.0);
	
	// 步骤7：最终颜色赋值
	COLOR.rgb = final_color;
}

shader_type canvas_item;
// 🔒 商业版独占 - 元素附魔效果
// 简洁的武器/物品附魔光效

uniform int element_type : hint_range(0, 4) = 0; // 0=火, 1=冰, 2=雷, 3=毒, 4=暗
uniform float intensity : hint_range(0.0, 2.0) = 0.8;
uniform float flow_speed : hint_range(0.0, 5.0) = 1.5;

// 元素颜色
vec3 get_element_color(int type) {
	if (type == 0) { // 火焰
		return vec3(1.0, 0.4, 0.0); // 橙红色
	} else if (type == 1) { // 冰霜
		return vec3(0.3, 0.7, 1.0); // 冰蓝色
	} else if (type == 2) { // 雷电
		return vec3(0.6, 0.8, 1.0); // 亮蓝色
	} else if (type == 3) { // 毒
		return vec3(0.3, 0.9, 0.3); // 翠绿色
	} else { // 暗影
		return vec3(0.5, 0.2, 0.7); // 紫色
	}
}

// 噪声函数
float noise(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 element_color = get_element_color(element_type);
	
	// 1. 边缘光晕 - 物品轮廓发光
	vec2 texel_size = vec2(1.0) / vec2(textureSize(TEXTURE, 0));
	float alpha_sum = 0.0;
	
	// 检测边缘（采样周围像素）
	for (float x = -2.0; x <= 2.0; x += 1.0) {
		for (float y = -2.0; y <= 2.0; y += 1.0) {
			if (x == 0.0 && y == 0.0) continue;
			vec2 offset = vec2(x, y) * texel_size;
			alpha_sum += texture(TEXTURE, UV + offset).a;
		}
	}
	
	// 边缘光效果
	float edge = (1.0 - tex.a) * step(0.1, alpha_sum);
	float edge_glow = edge * 0.5;  // 从0.3增加到0.5
	
	// 2. 能量流动 - 沿物品表面流动的能量
	vec2 uv = UV;
	float flow = sin(uv.x * 5.0 + uv.y * 3.0 - TIME * flow_speed) * 0.5 + 0.5;
	float flow_mask = tex.a * flow * 0.25;  // 从0.15增加到0.25
	
	// 3. 轻微脉冲
	float pulse = sin(TIME * 2.0) * 0.5 + 0.5;
	pulse = mix(0.8, 1.0, pulse); // 限制脉冲范围
	
	// 4. 元素特效（简化版）
	vec3 element_effect = vec3(0.0);
	
	if (element_type == 0) { // 火焰 - 闪烁
		float flicker = noise(UV * 10.0 + TIME * 3.0) * 0.3 + 0.7;
		element_effect = element_color * (edge_glow + flow_mask) * flicker;
	} else if (element_type == 1) { // 冰霜 - 霜冻纹理
		float frost = step(0.6, noise(UV * 15.0 + TIME * 0.5));
		element_effect = element_color * (edge_glow + flow_mask + frost * tex.a * 0.1);
	} else if (element_type == 2) { // 雷电 - 电弧闪烁
		float spark = step(0.95, noise(UV * 20.0 + TIME * 5.0));
		element_effect = element_color * (edge_glow + flow_mask + spark * 0.5);
	} else if (element_type == 3) { // 毒 - 毒液流动
		float drip = sin(UV.y * 8.0 - TIME * 2.0) * 0.5 + 0.5;
		element_effect = element_color * (edge_glow + flow_mask * drip);
	} else { // 暗影 - 暗影波动
		float shadow = sin(length(UV - 0.5) * 10.0 - TIME * 2.0) * 0.5 + 0.5;
		element_effect = element_color * (edge_glow + flow_mask * shadow);
	}
	
	// 混合原始纹理和附魔效果
	vec3 final_color = tex.rgb;
	
	// 添加元素光效
	final_color += element_effect * intensity * pulse;
	
	// 轻微的色调染色
	final_color = mix(final_color, final_color * (vec3(1.0) + element_color * 0.3), tex.a * intensity * 0.35);  // 从0.2增加到0.35
	
	COLOR = vec4(final_color, tex.a);
}

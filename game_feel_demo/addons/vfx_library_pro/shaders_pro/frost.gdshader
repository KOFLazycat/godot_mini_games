shader_type canvas_item;
// 🔒 商业版独占 - 冰霜效果
// 创造冰冻和霜冻的视觉效果

uniform float frost_amount : hint_range(0.0, 1.0) = 0.6;
uniform float ice_speed : hint_range(0.0, 2.0) = 0.5;
uniform vec4 frost_color : source_color = vec4(0.7, 0.9, 1.0, 1.0);
uniform vec4 ice_color : source_color = vec4(0.9, 0.95, 1.0, 1.0);

// 噪声函数
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float voronoi(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	
	float min_dist = 1.0;
	for(int y = -1; y <= 1; y++) {
		for(int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 point = hash(i + neighbor) * vec2(0.5) + neighbor;
			float dist = length(f - point);
			min_dist = min(min_dist, dist);
		}
	}
	return min_dist;
}

void fragment() {
	vec2 uv = UV;
	float time = TIME * ice_speed;
	
	// 基础纹理
	vec4 tex = texture(TEXTURE, UV);
	
	// 冰晶生长图案
	float ice_pattern = voronoi(uv * 15.0 + vec2(time * 0.1, 0.0));
	ice_pattern = smoothstep(0.1, 0.5, ice_pattern);
	
	// 霜冻纹理
	float frost1 = noise(uv * 20.0 + vec2(time * 0.2, 0.0));
	float frost2 = noise(uv * 35.0 - vec2(0.0, time * 0.15));
	float frost = (frost1 + frost2) * 0.5;
	
	// 冰晶边缘
	float edge = 1.0 - smoothstep(0.0, 0.1, ice_pattern);
	
	// 冰的反光
	float highlight = pow(frost, 2.0) * ice_pattern;
	
	// 冷色调处理
	vec3 cold_tint = frost_color.rgb;
	vec3 frozen_color = mix(tex.rgb, cold_tint, frost_amount * 0.4);
	
	// 添加冰晶
	frozen_color = mix(frozen_color, ice_color.rgb, ice_pattern * frost_amount * 0.6);
	
	// 添加高光
	frozen_color += vec3(highlight * 0.5);
	
	// 边缘增亮（冰霜边缘效果）
	frozen_color += vec3(edge * 0.3);
	
	// 整体降低饱和度
	float gray = dot(frozen_color, vec3(0.299, 0.587, 0.114));
	frozen_color = mix(frozen_color, vec3(gray), frost_amount * 0.3);
	
	// 闪烁效果（冰面反光）
	float sparkle = pow(frost1 * frost2, 3.0);
	frozen_color += vec3(sparkle * 0.8);
	
	COLOR = vec4(frozen_color, tex.a);
}

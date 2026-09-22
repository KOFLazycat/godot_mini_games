shader_type canvas_item;
// 🔒 商业版独占 - 火焰效果
// 创造逼真的动态火焰燃烧效果

uniform float flame_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float flame_speed : hint_range(0.0, 5.0) = 2.0;
uniform vec4 flame_color : source_color = vec4(1.0, 0.5, 0.1, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.8, 0.3, 1.0);

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

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for(int i = 0; i < 5; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 uv = UV;
	float time = TIME * flame_speed;
	
	// 火焰从下往上燃烧
	uv.y = 1.0 - uv.y;
	
	// 创建火焰形状
	float flame_noise = fbm(vec2(uv.x * 3.0, uv.y * 2.0 - time));
	flame_noise += fbm(vec2(uv.x * 5.0, uv.y * 3.0 - time * 1.5)) * 0.5;
	
	// 火焰强度随高度衰减
	float height_falloff = 1.0 - uv.y;
	flame_noise *= height_falloff;
	
	// 添加扰动
	float distortion = fbm(vec2(uv.x * 2.0 + time, uv.y * 4.0)) * 0.1;
	flame_noise += distortion;
	
	// 火焰阈值
	float flame_threshold = 0.3 + uv.y * 0.3;
	float flame_mask = smoothstep(flame_threshold - 0.1, flame_threshold, flame_noise * flame_intensity);
	
	// 火焰核心（更亮的部分）
	float core_mask = smoothstep(flame_threshold + 0.2, flame_threshold + 0.4, flame_noise * flame_intensity);
	
	// 混合颜色
	vec4 base_tex = texture(TEXTURE, UV);
	vec4 flame = mix(flame_color, core_color, core_mask);
	
	// 添加闪烁效果
	float flicker = 0.9 + 0.1 * sin(time * 10.0 + uv.x * 20.0);
	flame.rgb *= flicker;
	
	// 最终合成
	COLOR = mix(base_tex, flame, flame_mask);
	COLOR.a = base_tex.a * (1.0 + flame_mask * 0.5);
}

shader_type canvas_item;
// 🔒 商业版独占 - 闪电效果
// 创造炫酷的电流和闪电视觉效果

uniform float lightning_speed : hint_range(0.0, 10.0) = 3.0;
uniform float branch_density : hint_range(0.0, 2.0) = 1.0;
uniform vec4 lightning_color : source_color = vec4(0.5, 0.8, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float intensity : hint_range(0.0, 2.0) = 1.0;

// 快速哈希函数
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

void fragment() {
	vec2 uv = UV;
	float time = TIME * lightning_speed;
	
	// 主闪电路径（之字形）
	float lightning_path = uv.x;
	float zigzag = sin(uv.y * 20.0 + time) * 0.1;
	lightning_path += zigzag;
	
	// 添加随机分支
	float branch = noise(vec2(uv.y * 10.0, time * 0.5)) * branch_density;
	lightning_path += branch * 0.05;
	
	// 创建闪电主干
	float main_bolt = abs(uv.x - 0.5 + sin(uv.y * 15.0 + time * 2.0) * 0.1);
	main_bolt = 1.0 - smoothstep(0.0, 0.02, main_bolt);
	
	// 次级分支
	float branch1 = abs(uv.x - 0.3 + sin(uv.y * 20.0 - time * 3.0) * 0.08);
	branch1 = 1.0 - smoothstep(0.0, 0.015, branch1);
	branch1 *= step(0.3, noise(vec2(uv.y * 5.0, time)));
	
	float branch2 = abs(uv.x - 0.7 + sin(uv.y * 18.0 + time * 2.5) * 0.08);
	branch2 = 1.0 - smoothstep(0.0, 0.015, branch2);
	branch2 *= step(0.3, noise(vec2(uv.y * 4.0, time * 1.5)));
	
	// 组合所有闪电
	float lightning = max(main_bolt, max(branch1, branch2));
	
	// 闪烁效果
	float flicker = 0.7 + 0.3 * noise(vec2(time * 20.0, uv.y * 100.0));
	lightning *= flicker;
	
	// 电弧核心（更亮）
	float core = pow(lightning, 3.0);
	
	// 外发光
	float glow = lightning * 0.5;
	
	// 混合颜色
	vec4 base_tex = texture(TEXTURE, UV);
	vec4 bolt_color = mix(lightning_color, core_color, core);
	
	// 添加能量脉冲
	float pulse = 0.8 + 0.2 * sin(time * 15.0 - uv.y * 50.0);
	bolt_color.rgb *= pulse * intensity;
	
	// 最终合成
	COLOR = mix(base_tex, bolt_color, lightning);
	COLOR.rgb += bolt_color.rgb * glow;
	COLOR.a = base_tex.a;
}

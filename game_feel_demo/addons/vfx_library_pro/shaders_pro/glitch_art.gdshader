shader_type canvas_item;
// 🔒 商业版独占 - 故障艺术效果
// 赛博朋克风格的数字故障和RGB分离

uniform float glitch_amount : hint_range(0.0, 1.0) = 0.5;
uniform float block_size : hint_range(0.0, 0.1) = 0.02;
uniform float color_drift : hint_range(0.0, 0.1) = 0.01;
uniform float scan_line_intensity : hint_range(0.0, 1.0) = 0.3;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// 随机数生成
float random(vec2 st) {
	return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// 噪声函数
float noise(vec2 st) {
	vec2 i = floor(st);
	vec2 f = fract(st);
	float a = random(i);
	float b = random(i + vec2(1.0, 0.0));
	float c = random(i + vec2(0.0, 1.0));
	float d = random(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
	vec2 uv = UV;
	
	// 时间跳动
	float time = floor(TIME * 10.0) / 10.0;
	
	// 随机块状故障
	vec2 block_uv = floor(UV / block_size) * block_size;
	float block_glitch = random(vec2(block_uv.y, time));
	
	if (block_glitch > 1.0 - glitch_amount * 0.3) {
		float offset = (random(vec2(time, block_uv.y)) - 0.5) * glitch_amount * 0.1;
		uv.x += offset;
	}
	
	// RGB 色彩分离
	float drift = color_drift * glitch_amount;
	float drift_angle = time * 6.28318;
	vec2 drift_offset = vec2(cos(drift_angle), sin(drift_angle)) * drift;
	
	float r = texture(TEXTURE, uv + drift_offset).r;
	float g = texture(TEXTURE, uv).g;
	float b = texture(TEXTURE, uv - drift_offset).b;
	
	// 扫描线
	float scan_line = sin(UV.y * 500.0 + TIME * 10.0) * scan_line_intensity;
	
	// 水平故障条
	float h_glitch = step(0.98, random(vec2(time, floor(UV.y * 50.0))));
	if (h_glitch > 0.5) {
		float shift = (random(vec2(time, UV.y)) - 0.5) * glitch_amount * 0.2;
		r = texture(TEXTURE, vec2(uv.x + shift, uv.y)).r;
		g = texture(TEXTURE, vec2(uv.x - shift * 0.5, uv.y)).g;
		b = texture(TEXTURE, vec2(uv.x + shift * 0.3, uv.y)).b;
	}
	
	// 随机色块
	float color_block = step(0.99, random(block_uv + time));
	vec3 random_color = vec3(
		random(block_uv + vec2(time, 0.0)),
		random(block_uv + vec2(0.0, time)),
		random(block_uv + time)
	);
	
	// 组合颜色
	vec3 color = vec3(r, g, b);
	color += scan_line;
	color = mix(color, random_color, color_block * glitch_amount);
	
	// 数字噪点
	float digital_noise = random(uv * 100.0 + time) * 0.1 * glitch_amount;
	color += digital_noise;
	
	// 透明度
	float alpha = texture(TEXTURE, UV).a;
	
	COLOR = vec4(color, alpha);
}

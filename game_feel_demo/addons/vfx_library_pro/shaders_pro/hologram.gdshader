shader_type canvas_item;
// 🔒 商业版独占 - 全息投影效果
// 科幻风格的全息图显示效果

uniform float scan_speed : hint_range(0.0, 5.0) = 1.5;
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float flicker_speed : hint_range(0.0, 20.0) = 10.0;
uniform vec4 hologram_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform float edge_brightness : hint_range(0.0, 5.0) = 2.0;
uniform sampler2D noise_texture;

// 随机函数
float random(vec2 st) {
	return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	
	// 扫描线效果
	float scan_line = fract((UV.y + TIME * scan_speed) * 100.0);
	float scan = smoothstep(0.0, 0.3, scan_line) * smoothstep(1.0, 0.7, scan_line);
	
	// 水平扫描条
	float h_scan = step(0.95, fract(UV.y * 200.0));
	
	// 故障效果
	float glitch = random(vec2(floor(UV.y * 10.0), floor(TIME * 5.0)));
	vec2 glitch_offset = vec2(
		(glitch - 0.5) * glitch_intensity * step(0.95, glitch),
		0.0
	);
	
	vec4 glitched_tex = texture(TEXTURE, UV + glitch_offset);
	
	// RGB分离
	float offset = 0.003 * glitch_intensity;
	float r = texture(TEXTURE, UV + vec2(offset, 0.0)).r;
	float g = texture(TEXTURE, UV).g;
	float b = texture(TEXTURE, UV - vec2(offset, 0.0)).b;
	
	// 边缘检测
	float edge = 0.0;
	vec2 pixel_size = vec2(1.0) / vec2(textureSize(TEXTURE, 0));
	for(int x = -1; x <= 1; x++) {
		for(int y = -1; y <= 1; y++) {
			edge += texture(TEXTURE, UV + vec2(float(x), float(y)) * pixel_size).a;
		}
	}
	edge = abs(edge - tex.a * 9.0);
	
	// 闪烁效果
	float flicker = 0.85 + 0.15 * sin(TIME * flicker_speed + random(UV) * 6.28);
	
	// 组合效果
	vec3 color = vec3(r, g, b) * hologram_color.rgb;
	color += scan * hologram_color.rgb * 0.5;
	color += h_scan * hologram_color.rgb * 0.3;
	color += edge * hologram_color.rgb * edge_brightness;
	color *= flicker;
	
	float alpha = tex.a * (0.7 + 0.3 * scan);
	
	COLOR = vec4(color, alpha);
}

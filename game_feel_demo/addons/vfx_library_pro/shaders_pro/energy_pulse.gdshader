shader_type canvas_item;
// 🔒 商业版独占 - 能量脉冲波
// 从中心向外扩散的能量冲击波

uniform vec2 pulse_center = vec2(0.5, 0.5);
uniform float pulse_speed : hint_range(0.0, 5.0) = 2.0;
uniform float pulse_width : hint_range(0.01, 0.5) = 0.1;
uniform float pulse_intensity : hint_range(0.0, 3.0) = 1.5;
uniform vec4 pulse_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform bool auto_pulse = true;
uniform float manual_radius : hint_range(0.0, 2.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 uv_offset = UV - pulse_center;
	float dist = length(uv_offset);
	
	// 脉冲半径（自动或手动）
	float pulse_radius;
	if (auto_pulse) {
		pulse_radius = fract(TIME * pulse_speed);
	} else {
		pulse_radius = manual_radius;
	}
	
	// 计算脉冲强度
	float pulse_diff = abs(dist - pulse_radius);
	float pulse = smoothstep(pulse_width, 0.0, pulse_diff);
	
	// 多层脉冲
	float pulse2_radius = fract(pulse_radius + 0.33);
	float pulse2_diff = abs(dist - pulse2_radius);
	float pulse2 = smoothstep(pulse_width * 0.7, 0.0, pulse2_diff) * 0.6;
	
	float pulse3_radius = fract(pulse_radius + 0.66);
	float pulse3_diff = abs(dist - pulse3_radius);
	float pulse3 = smoothstep(pulse_width * 0.5, 0.0, pulse3_diff) * 0.3;
	
	float total_pulse = (pulse + pulse2 + pulse3) * pulse_intensity;
	
	// 脉冲扭曲效果
	float angle = atan(uv_offset.y, uv_offset.x);
	float distortion = sin(pulse_radius * 10.0) * pulse * 0.02;
	vec2 distorted_uv = UV + vec2(cos(angle), sin(angle)) * distortion;
	
	vec4 distorted_tex = texture(TEXTURE, distorted_uv);
	
	// 脉冲光晕
	vec3 glow = pulse_color.rgb * total_pulse;
	
	// 边缘增强
	float edge_pulse = smoothstep(pulse_width * 1.5, pulse_width * 0.5, pulse_diff);
	glow += pulse_color.rgb * edge_pulse * pulse_intensity * 0.5;
	
	// 混合
	vec3 final_color = mix(tex.rgb, distorted_tex.rgb, total_pulse * 0.3);
	final_color += glow;
	
	COLOR = vec4(final_color, tex.a);
}

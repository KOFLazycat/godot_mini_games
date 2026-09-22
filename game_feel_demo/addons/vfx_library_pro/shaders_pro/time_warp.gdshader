shader_type canvas_item;
// 🔒 商业版独占 - 时间扭曲效果
// 创造时间减速/加速的视觉扭曲

uniform float time_scale : hint_range(-2.0, 5.0) = 0.3;
uniform float distortion_strength : hint_range(0.0, 0.5) = 0.15;
uniform float wave_speed : hint_range(0.0, 10.0) = 2.0;
uniform vec4 tint_color : source_color = vec4(0.5, 0.7, 1.0, 1.0);
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	// 时间波动
	float time = TIME * wave_speed * time_scale;
	
	// 创建径向扭曲
	vec2 center = vec2(0.5, 0.5);
	vec2 uv_offset = UV - center;
	float dist = length(uv_offset);
	
	// 螺旋扭曲
	float angle = atan(uv_offset.y, uv_offset.x);
	float twist = sin(dist * 10.0 - time) * distortion_strength * (1.0 - dist);
	
	// 应用扭曲
	vec2 distorted_uv = UV + vec2(
		cos(angle + twist) * twist * 0.5,
		sin(angle + twist) * twist * 0.5
	);
	
	// 波纹效果
	float wave = sin(dist * 20.0 - time * 2.0) * 0.01;
	distorted_uv += wave;
	
	// 采样纹理
	vec4 tex = texture(TEXTURE, distorted_uv);
	vec4 screen = texture(screen_texture, SCREEN_UV + wave);
	
	// 混合颜色和色调
	vec4 color = mix(tex, screen, 0.3);
	color = mix(color, tint_color, 0.2);
	
	// 添加脉冲效果
	float pulse = 0.5 + 0.5 * sin(time * 2.0);
	color.rgb *= 0.8 + 0.2 * pulse;
	
	COLOR = color;
}

shader_type canvas_item;
// 🔒 商业版独占 - 水面波纹效果
// 模拟水面反射和波动

uniform float wave_speed : hint_range(0.1, 5.0) = 1.0;
uniform float wave_amplitude : hint_range(0.0, 0.1) = 0.02;
uniform float wave_frequency : hint_range(1.0, 20.0) = 8.0;
uniform vec4 water_tint : source_color = vec4(0.3, 0.6, 1.0, 1.0);
uniform float reflection_strength : hint_range(0.0, 1.0) = 0.4;
uniform float ripple_count : hint_range(1.0, 10.0) = 3.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

// 简单噪声
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    float time = TIME * wave_speed;
    
    // 多层波纹（转换成整型迭代以确保兼容性）
    float waves = 0.0;
    int rc = int(clamp(ripple_count, 1.0, 10.0));
    for (int i = 0; i < rc; i++) {
        float fi = float(i);
        float offset = fi * PI * 2.0 / ripple_count;
        waves += sin(uv.x * wave_frequency + time + offset) * 0.5;
        waves += sin(uv.y * wave_frequency * 0.7 + time * 1.3 + offset) * 0.5;
    }
    waves /= ripple_count;
    
    // 径向波纹（从中心扩散）
    vec2 center = vec2(0.5, 0.5);
    float dist = length(uv - center);
    float radial_wave = sin(dist * 20.0 - time * 3.0) * 0.3;
    
    // 组合波纹
    float total_wave = (waves + radial_wave) * wave_amplitude;
    
    // 应用波形扭曲
    vec2 distorted_uv = uv + vec2(total_wave, total_wave * 0.5);
    
    // 采样纹理
    vec4 tex = texture(TEXTURE, distorted_uv);
    
    // 水面反光
    float highlight = max(0.0, waves) * reflection_strength;
    vec3 water_reflection = vec3(1.0) * highlight;
    
    // 焦散效果（Caustics）
    float caustic_time = time * 0.5;
    float caustic1 = abs(sin(uv.x * 15.0 + caustic_time) * cos(uv.y * 15.0 - caustic_time));
    float caustic2 = abs(sin(uv.x * 10.0 - caustic_time * 1.3) * cos(uv.y * 10.0 + caustic_time * 0.7));
    float caustics = pow(max(caustic1, caustic2), 3.0) * 0.3;
    
    // 水面色调
    vec3 final_color = mix(tex.rgb, water_tint.rgb, water_tint.a * 0.3);
    
    // 添加反光和焦散
    final_color += water_reflection;
    final_color += vec3(caustics) * vec3(0.8, 0.9, 1.0);
    
    // 波峰高光
    float wave_highlight = smoothstep(0.7, 1.0, abs(waves)) * 0.5;
    final_color += vec3(wave_highlight);
    
    COLOR = vec4(final_color, tex.a);
}

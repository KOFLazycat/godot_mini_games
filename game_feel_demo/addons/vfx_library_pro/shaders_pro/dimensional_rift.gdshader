shader_type canvas_item;

// 次元裂缝 - 时空扭曲的维度裂痕效果
// 商业版独占高级shader

uniform float intensity : hint_range(0.0, 2.0) = 1.0;
uniform float rift_width : hint_range(0.01, 0.3) = 0.08;
uniform float distortion_strength : hint_range(0.0, 0.5) = 0.15;
uniform vec4 rift_color : source_color = vec4(0.5, 0.2, 1.0, 1.0);
uniform vec4 edge_color : source_color = vec4(0.8, 0.4, 1.0, 1.0);

// Noise函数
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
    
    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
}

void fragment() {
    vec2 uv = UV;
    vec2 center = vec2(0.5, 0.5);
    
    // 旋转的裂缝
    float angle = TIME * 0.3;
    vec2 dir = vec2(cos(angle), sin(angle));
    
    // 计算到裂缝中心线的距离
    vec2 to_center = uv - center;
    float dist_to_line = abs(dot(to_center, vec2(-dir.y, dir.x)));
    
    // 裂缝的扭曲噪声
    float n = fbm(uv * 5.0 + TIME * 0.2);
    float rift_noise = fbm(uv * 8.0 - TIME * 0.3);
    
    // 裂缝宽度随位置变化
    float dynamic_width = rift_width * (1.0 + 0.5 * sin(dot(uv, dir) * 10.0 + TIME));
    
    // 裂缝遮罩
    float rift_mask = smoothstep(dynamic_width, dynamic_width * 0.5, dist_to_line);
    rift_mask *= (0.5 + 0.5 * rift_noise);
    
    // 边缘光晕
    float edge_mask = smoothstep(dynamic_width * 2.0, dynamic_width * 0.8, dist_to_line);
    edge_mask -= rift_mask;
    
    // 时空扭曲
    vec2 distortion = vec2(
        noise(uv * 6.0 + TIME * 0.5),
        noise(uv * 6.0 + TIME * 0.5 + 100.0)
    ) * 2.0 - 1.0;
    
    distortion *= distortion_strength * rift_mask;
    
    // 扭曲后的纹理采样
    vec4 distorted_color = texture(TEXTURE, uv + distortion);
    
    // 裂缝内部颜色 - 多层次的能量流动
    float flow1 = sin(dot(uv, dir) * 15.0 - TIME * 3.0);
    float flow2 = sin(dot(uv, dir) * 20.0 + TIME * 2.0);
    vec4 inner_color = mix(rift_color, edge_color, (flow1 + flow2) * 0.5 + 0.5);
    
    // 混合裂缝效果
    vec4 final_color = distorted_color;
    final_color = mix(final_color, inner_color, rift_mask * intensity);
    final_color = mix(final_color, edge_color, edge_mask * intensity * 0.5);
    
    // 添加闪烁的能量火花
    float spark = smoothstep(0.95, 1.0, noise(uv * 30.0 + TIME * 2.0));
    final_color.rgb += spark * edge_color.rgb * rift_mask * 2.0;
    
    COLOR = final_color;
}

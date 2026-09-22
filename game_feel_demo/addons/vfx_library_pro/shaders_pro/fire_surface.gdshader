shader_type canvas_item;
// 🔒 商业版独占 - 火焰表面效果
// 让物体表面燃烧起来

uniform vec4 fire_color_1 : source_color = vec4(1.0, 0.9, 0.3, 1.0);  // 黄色火焰
uniform vec4 fire_color_2 : source_color = vec4(1.0, 0.4, 0.1, 1.0);  // 橙色火焰
uniform vec4 fire_color_3 : source_color = vec4(0.8, 0.1, 0.0, 1.0);  // 红色火焰
uniform float flame_speed : hint_range(0.1, 5.0) = 2.0;
uniform float flame_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float distortion_strength : hint_range(0.0, 0.3) = 0.1;
uniform float emission_strength : hint_range(0.0, 3.0) = 1.5;

// Perlin噪声函数
vec2 hash(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(
        mix(dot(hash(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
            dot(hash(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
        mix(dot(hash(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
            dot(hash(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x),
        u.y
    );
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for(int i = 0; i < 5; i++) {
        value += amplitude * noise(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
}

void fragment() {
    vec2 uv = UV;
    
    // 火焰向上流动
    float time = TIME * flame_speed;
    vec2 fire_uv = vec2(uv.x * 3.0, uv.y * 4.0 - time);
    
    // 多层噪声创建火焰形状
    float noise1 = fbm(fire_uv);
    float noise2 = fbm(fire_uv * 2.0 + vec2(time * 0.5, 0.0));
    float noise3 = fbm(fire_uv * 4.0 - vec2(0.0, time));
    
    // 组合噪声
    float fire_pattern = noise1 * 0.5 + noise2 * 0.3 + noise3 * 0.2;
    
    // 从下到上渐变（火焰底部更强）
    float vertical_gradient = 1.0 - uv.y;
    fire_pattern *= vertical_gradient * 1.5;
    
    // 边缘渐隐
    float edge_fade = smoothstep(0.0, 0.1, uv.x) * smoothstep(1.0, 0.9, uv.x);
    fire_pattern *= edge_fade;
    
    // 火焰强度
    fire_pattern = clamp(fire_pattern * flame_intensity, 0.0, 1.0);
    
    // 三色火焰渐变
    vec3 fire_color;
    if (fire_pattern > 0.7) {
        fire_color = mix(fire_color_2.rgb, fire_color_1.rgb, (fire_pattern - 0.7) / 0.3);
    } else if (fire_pattern > 0.3) {
        fire_color = mix(fire_color_3.rgb, fire_color_2.rgb, (fire_pattern - 0.3) / 0.4);
    } else {
        fire_color = fire_color_3.rgb * (fire_pattern / 0.3);
    }
    
    // 热扭曲效果
    float distortion = noise(uv * 10.0 + vec2(0.0, time * 2.0)) * distortion_strength;
    vec2 distorted_uv = UV + vec2(distortion, distortion * 0.5);
    vec4 tex = texture(TEXTURE, distorted_uv);
    
    // 混合原始纹理和火焰
    vec3 final_color = mix(tex.rgb, fire_color, fire_pattern * 0.7);
    
    // 发光效果
    final_color += fire_color * fire_pattern * emission_strength;
    
    // 火焰边缘闪烁
    float flicker = sin(TIME * 10.0 + uv.x * 20.0) * 0.1 + 0.9;
    final_color *= flicker;
    
    COLOR = vec4(final_color, tex.a);
}

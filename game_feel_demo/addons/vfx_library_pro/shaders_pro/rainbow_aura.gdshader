shader_type canvas_item;

// 彩虹光环 - 流动的彩虹色光晕效果
// 商业版独占高级shader

uniform float intensity : hint_range(0.0, 2.0) = 1.0;
uniform float speed : hint_range(0.5, 5.0) = 2.0;
uniform float wave_count : hint_range(1.0, 10.0) = 3.0;
uniform float glow_size : hint_range(0.1, 0.5) = 0.3;

void fragment() {
    vec2 uv = UV;
    vec4 base_color = texture(TEXTURE, uv);
    
    // 计算到中心的距离
    vec2 center = vec2(0.5, 0.5);
    float dist = length(uv - center);
    
    // 旋转的彩虹波
    float angle = atan(uv.y - 0.5, uv.x - 0.5);
    float rainbow_offset = angle / 6.28318 + TIME * speed * 0.1;
    
    // 脉冲效果
    float pulse = sin(TIME * speed) * 0.5 + 0.5;
    
    // 彩虹色计算
    float hue = fract(rainbow_offset + dist * wave_count - TIME * speed * 0.2);
    
    // HSV to RGB
    vec3 rainbow_color;
    float h = hue * 6.0;
    float x = 1.0 - abs(mod(h, 2.0) - 1.0);
    
    if (h < 1.0) rainbow_color = vec3(1.0, x, 0.0);
    else if (h < 2.0) rainbow_color = vec3(x, 1.0, 0.0);
    else if (h < 3.0) rainbow_color = vec3(0.0, 1.0, x);
    else if (h < 4.0) rainbow_color = vec3(0.0, x, 1.0);
    else if (h < 5.0) rainbow_color = vec3(x, 0.0, 1.0);
    else rainbow_color = vec3(1.0, 0.0, x);
    
    // 光环遮罩
    float aura_inner = smoothstep(0.4 - glow_size, 0.4, dist);
    float aura_outer = 1.0 - smoothstep(0.4, 0.4 + glow_size, dist);
    float aura_mask = aura_inner * aura_outer;
    
    // 添加脉冲亮度变化
    aura_mask *= (0.7 + pulse * 0.3);
    
    // 混合彩虹光环
    vec3 final_color = base_color.rgb;
    final_color = mix(final_color, rainbow_color, aura_mask * intensity * 0.5);
    final_color += rainbow_color * aura_mask * intensity * 0.3;
    
    COLOR = vec4(final_color, base_color.a);
}

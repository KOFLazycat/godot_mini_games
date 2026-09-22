shader_type canvas_item;

// 能量护盾 - 动态的六边形护盾效果
// 商业版独占高级shader

uniform float intensity : hint_range(0.0, 2.0) = 1.0;
uniform float hex_scale : hint_range(5.0, 50.0) = 20.0;
uniform float pulse_speed : hint_range(0.5, 5.0) = 2.0;
uniform vec4 shield_color : source_color = vec4(0.3, 0.7, 1.0, 1.0);
uniform vec4 impact_color : source_color = vec4(1.0, 0.8, 0.3, 1.0);
uniform vec2 impact_point = vec2(0.5, 0.5);
uniform float impact_strength : hint_range(0.0, 1.0) = 0.0;

// 六边形距离函数
float hex_dist(vec2 p) {
    p = abs(p);
    float c = dot(p, normalize(vec2(1.0, 1.73)));
    c = max(c, p.x);
    return c;
}

// 六边形网格
vec4 hex_grid(vec2 uv) {
    vec2 r = vec2(1.0, 1.73);
    vec2 h = r * 0.5;
    
    vec2 a = mod(uv, r) - h;
    vec2 b = mod(uv - h, r) - h;
    
    vec2 gv = length(a) < length(b) ? a : b;
    vec2 id = uv - gv;
    
    float d = hex_dist(gv);
    
    return vec4(gv, id);
}

float noise(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
    vec2 uv = (UV - 0.5) * hex_scale;
    
    // 六边形网格
    vec4 hex = hex_grid(uv);
    vec2 gv = hex.xy;
    vec2 id = hex.zw;
    
    float hex_d = hex_dist(gv);
    
    // 六边形边缘
    float hex_edge = smoothstep(0.05, 0.02, abs(hex_d - 0.5));
    
    // 时间脉冲
    float pulse = sin(TIME * pulse_speed + noise(id) * 6.28) * 0.5 + 0.5;
    
    // 冲击波效果
    vec2 impact_uv = UV - impact_point;
    float dist_to_impact = length(impact_uv);
    
    // 扩散的冲击波
    float wave = sin(dist_to_impact * 20.0 - TIME * 10.0) * 0.5 + 0.5;
    float impact_mask = smoothstep(0.5, 0.0, abs(dist_to_impact - impact_strength * 0.8));
    impact_mask *= impact_strength;
    
    // 六边形闪烁
    float hex_glow = 0.0;
    if (dist_to_impact < impact_strength * 1.2) {
        float local_intensity = (1.0 - dist_to_impact / (impact_strength * 1.2));
        hex_glow = local_intensity * wave * noise(id);
    }
    
    // 能量流动
    float flow = sin(id.x * 0.5 + id.y * 0.3 + TIME * 1.5) * 0.5 + 0.5;
    
    // 组合颜色
    vec4 base_color = shield_color;
    vec4 current_color = mix(base_color, impact_color, impact_mask);
    
    // 六边形网格显示
    float hex_alpha = hex_edge * (0.3 + pulse * 0.3 + flow * 0.2);
    hex_alpha += hex_glow * 0.8;
    
    // 内部填充（半透明）
    float inner_fill = smoothstep(0.55, 0.5, hex_d);
    hex_alpha += inner_fill * 0.1 * pulse;
    
    // 原始纹理
    vec4 base_texture = texture(TEXTURE, UV);
    
    // 混合护盾效果
    vec4 shield_effect = current_color;
    shield_effect.a = hex_alpha * intensity;
    
    // 叠加模式
    COLOR = mix(base_texture, shield_effect, shield_effect.a * 0.8);
    COLOR.rgb += shield_effect.rgb * hex_alpha * intensity * 0.5;
}

shader_type canvas_item;
// 🔒 商业版独占 - 冰霜覆盖效果
// 物体表面结冰和冰晶扩散

uniform vec4 ice_color_1 : source_color = vec4(0.7, 0.9, 1.0, 1.0);  // 浅蓝
uniform vec4 ice_color_2 : source_color = vec4(0.4, 0.7, 0.9, 1.0);  // 深蓝
uniform float frost_coverage : hint_range(0.0, 1.0) = 0.6;  // 冰霜覆盖度
uniform float crystal_scale : hint_range(1.0, 20.0) = 8.0;  // 冰晶大小
uniform float frost_speed : hint_range(0.0, 2.0) = 0.3;  // 冰霜扩散速度
uniform float shimmer_speed : hint_range(0.0, 5.0) = 2.0;  // 闪光速度
uniform float refraction_strength : hint_range(0.0, 0.1) = 0.03;  // 折射强度

// Voronoi噪声（创建冰晶图案）
vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453);
}

float voronoi(vec2 x) {
    vec2 n = floor(x);
    vec2 f = fract(x);
    
    float min_dist = 8.0;
    for(int j = -1; j <= 1; j++) {
        for(int i = -1; i <= 1; i++) {
            vec2 g = vec2(float(i), float(j));
            vec2 o = hash2(n + g);
            
            // 晶体生长动画
            o = 0.5 + 0.5 * sin(TIME * frost_speed + 6.2831 * o);
            
            vec2 r = g + o - f;
            float d = dot(r, r);
            
            min_dist = min(min_dist, d);
        }
    }
    
    return sqrt(min_dist);
}

// 简单噪声
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(
        mix(dot(hash2(i + vec2(0.0, 0.0)) - 0.5, f - vec2(0.0, 0.0)),
            dot(hash2(i + vec2(1.0, 0.0)) - 0.5, f - vec2(1.0, 0.0)), u.x),
        mix(dot(hash2(i + vec2(0.0, 1.0)) - 0.5, f - vec2(0.0, 1.0)),
            dot(hash2(i + vec2(1.0, 1.0)) - 0.5, f - vec2(1.0, 1.0)), u.x),
        u.y
    ) + 0.5;
}

void fragment() {
    vec2 uv = UV;
    
    // 冰晶图案（Voronoi）
    float crystals = voronoi(uv * crystal_scale);
    crystals = smoothstep(0.0, 0.3, crystals);
    
    // 霜花图案（多层噪声）
    float frost_pattern = noise(uv * 15.0);
    frost_pattern *= noise(uv * 30.0 + vec2(TIME * frost_speed));
    frost_pattern = pow(frost_pattern, 2.0);
    
    // 从边缘向中心扩散
    vec2 center = vec2(0.5, 0.5);
    float dist_from_center = length(uv - center);
    float spread = 1.0 - smoothstep(0.0, 0.7, dist_from_center - TIME * frost_speed * 0.1);
    
    // 组合冰霜图案
    float ice_mask = (crystals * 0.6 + frost_pattern * 0.4) * frost_coverage * spread;
    ice_mask = clamp(ice_mask, 0.0, 1.0);
    
    // 冰霜边缘（更强的效果）
    float edge_frost = smoothstep(0.3, 0.5, ice_mask);
    
    // 冰面折射
    vec2 refraction = vec2(
        noise(uv * 20.0) - 0.5,
        noise(uv * 20.0 + vec2(100.0, 100.0)) - 0.5
    ) * refraction_strength * ice_mask;
    
    vec4 tex = texture(TEXTURE, uv + refraction);
    
    // 冰霜颜色
    vec3 ice_color = mix(ice_color_1.rgb, ice_color_2.rgb, crystals);
    
    // 闪光效果
    float shimmer = sin(uv.x * 30.0 + TIME * shimmer_speed) * 
                   sin(uv.y * 30.0 - TIME * shimmer_speed * 0.7);
    shimmer = pow(max(0.0, shimmer), 3.0) * 0.5;
    
    // 冰晶高光
    float highlight = smoothstep(0.8, 1.0, crystals) * edge_frost;
    
    // 混合颜色
    vec3 final_color = mix(tex.rgb, ice_color, ice_mask * 0.6);
    
    // 降低饱和度（冰冻效果）
    float gray = dot(final_color, vec3(0.299, 0.587, 0.114));
    final_color = mix(final_color, vec3(gray), ice_mask * 0.4);
    
    // 添加亮度（冰面反光）
    final_color += vec3(shimmer + highlight) * ice_mask;
    
    // 边缘发光
    final_color += ice_color * edge_frost * 0.3;
    
    COLOR = vec4(final_color, tex.a);
}

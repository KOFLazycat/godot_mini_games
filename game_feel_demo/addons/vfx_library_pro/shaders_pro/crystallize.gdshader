shader_type canvas_item;

// 水晶化 - 菱形水晶折射效果
// 商业版独占高级shader

uniform float crystal_amount : hint_range(0.0, 1.0) = 0.5;
uniform float crystal_size : hint_range(5.0, 50.0) = 20.0;
uniform vec4 crystal_tint : source_color = vec4(0.7, 0.9, 1.0, 1.0);
uniform float refraction_strength : hint_range(0.0, 0.1) = 0.03;
uniform float sparkle_intensity : hint_range(0.0, 2.0) = 1.0;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// 菱形距离场
float diamond_dist(vec2 p) {
    p = abs(p);
    return max(p.x * 0.866 + p.y * 0.5, p.y);
}

void fragment() {
    vec2 uv = UV;
    
    // 水晶网格
    vec2 crystal_scale = vec2(crystal_size);
    vec2 grid_uv = uv * crystal_scale;
    vec2 grid_id = floor(grid_uv);
    vec2 grid_local = fract(grid_uv) - 0.5;
    
    // 菱形水晶形状
    float crystal_d = diamond_dist(grid_local);
    float crystal_mask = 1.0 - smoothstep(0.4, 0.5, crystal_d);
    crystal_mask *= crystal_amount;
    
    // 折射效果
    vec2 normal = normalize(grid_local);
    vec2 refract_uv = uv + normal * refraction_strength * crystal_mask;
    
    // 采样颜色
    vec4 refracted_color = texture(TEXTURE, refract_uv);
    vec4 base_color = texture(TEXTURE, uv);
    
    // 水晶边缘高光
    float edge = smoothstep(0.45, 0.5, crystal_d);
    float edge_highlight = (1.0 - edge) * crystal_mask;
    
    // 闪烁效果
    float sparkle_random = hash(grid_id + floor(TIME * 2.0));
    float sparkle = step(0.95, sparkle_random) * crystal_mask;
    
    // 混合颜色
    vec3 final_color = mix(base_color.rgb, refracted_color.rgb, crystal_mask * 0.8);
    
    // 添加水晶色调
    final_color = mix(final_color, crystal_tint.rgb, crystal_mask * 0.3);
    
    // 添加边缘高光
    final_color += vec3(1.0) * edge_highlight * 0.5;
    
    // 添加闪烁
    final_color += vec3(1.0) * sparkle * sparkle_intensity;
    
    COLOR = vec4(final_color, base_color.a);
}

shader_type canvas_item;

// 星光闪烁 - 闪烁的星光粒子效果
// 商业版独占高级shader

uniform float star_density : hint_range(0.1, 1.0) = 0.5;
uniform float twinkle_speed : hint_range(0.5, 5.0) = 2.0;
uniform float star_size : hint_range(1.0, 10.0) = 3.0;
uniform vec4 star_color : source_color = vec4(1.0, 1.0, 0.8, 1.0);
uniform float glow_intensity : hint_range(0.0, 2.0) = 1.0;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 hash2(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

// 星星形状
float star_shape(vec2 p, float size) {
    // 4个方向的光芒
    float d1 = abs(p.x);
    float d2 = abs(p.y);
    float d3 = abs(p.x + p.y) * 0.707;
    float d4 = abs(p.x - p.y) * 0.707;
    
    float star = min(min(d1, d2), min(d3, d4));
    return smoothstep(size, size * 0.3, star);
}

void fragment() {
    vec2 uv = UV;
    vec4 base_color = texture(TEXTURE, uv);
    
    // 星光网格
    float grid_size = 30.0;
    vec2 grid_uv = uv * grid_size;
    vec2 grid_id = floor(grid_uv);
    vec2 grid_local = fract(grid_uv) - 0.5;
    
    vec3 stars = vec3(0.0);
    
    // 检查周围9个格子
    for (float y = -1.0; y <= 1.0; y += 1.0) {
        for (float x = -1.0; x <= 1.0; x += 1.0) {
            vec2 neighbor_id = grid_id + vec2(x, y);
            
            // 随机决定是否有星星
            float star_random = hash(neighbor_id);
            if (star_random > (1.0 - star_density)) {
                // 星星在格子内的随机位置
                vec2 star_offset = hash2(neighbor_id + 10.0) - 0.5;
                vec2 star_pos = grid_local - vec2(x, y) - star_offset;
                
                // 闪烁效果
                float twinkle_offset = hash(neighbor_id + 20.0) * 6.28318;
                float twinkle = sin(TIME * twinkle_speed + twinkle_offset) * 0.5 + 0.5;
                twinkle = pow(twinkle, 3.0); // 更尖锐的闪烁
                
                // 星星大小变化
                float size = star_size * 0.01 * (0.5 + twinkle * 0.5);
                
                // 绘制星星
                float star = star_shape(star_pos, size);
                
                // 中心点
                float center_dist = length(star_pos);
                float center_glow = exp(-center_dist * center_dist * 500.0);
                
                // 星光颜色
                vec3 star_light = star_color.rgb * (star + center_glow * 2.0) * twinkle;
                
                stars += star_light;
            }
        }
    }
    
    // 叠加星光效果
    vec3 final_color = base_color.rgb + stars * glow_intensity;
    
    COLOR = vec4(final_color, base_color.a);
}

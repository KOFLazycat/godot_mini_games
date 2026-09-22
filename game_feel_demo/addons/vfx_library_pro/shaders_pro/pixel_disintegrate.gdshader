shader_type canvas_item;

// 像素分解 - 物体分解为像素块飞散的效果
// 商业版独占高级shader

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float pixel_size : hint_range(2.0, 30.0) = 10.0;
uniform float scatter_strength : hint_range(0.0, 1.0) = 0.5;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 hash2(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    
    // 像素块尺寸（基于屏幕尺寸）
    vec2 pixel_block_size = vec2(pixel_size) / vec2(textureSize(TEXTURE, 0));
    
    // 像素块ID
    vec2 block_id = floor(uv / pixel_block_size);
    vec2 block_center = (block_id + 0.5) * pixel_block_size;
    
    // 块内的本地UV
    vec2 local_uv = fract(uv / pixel_block_size);
    
    // 每个块的随机值
    float block_hash = hash(block_id);
    vec2 block_hash2 = hash2(block_id);
    
    // 分解进度 - 错开各块的消失时间
    float stagger = block_hash * 0.4;
    float block_progress = clamp((progress - stagger) / (1.0 - stagger), 0.0, 1.0);
    
    // 飞散方向
    float angle = block_hash2.x * 6.28318;
    vec2 scatter_dir = vec2(cos(angle), sin(angle));
    
    // 飞散距离
    float scatter_dist = block_progress * block_progress * scatter_strength * 0.5;
    vec2 scattered_uv = uv + scatter_dir * scatter_dist;
    
    // 采样颜色
    vec4 base_color = texture(TEXTURE, scattered_uv);
    
    // 旋转效果
    float rotation = block_hash * 6.28318 * block_progress * 2.0;
    float cos_r = cos(rotation);
    float sin_r = sin(rotation);
    
    // 以块中心为原点旋转
    vec2 rel_pos = local_uv - vec2(0.5);
    vec2 rotated = vec2(
        rel_pos.x * cos_r - rel_pos.y * sin_r + 0.5,
        rel_pos.x * sin_r + rel_pos.y * cos_r + 0.5
    );
    
    // 检查是否在旋转后的块范围内
    float in_block = step(0.0, rotated.x) * step(rotated.x, 1.0) * step(0.0, rotated.y) * step(rotated.y, 1.0);
    
    // 淡出效果
    float alpha = 1.0 - smoothstep(0.5, 1.0, block_progress);
    alpha *= in_block;
    
    // 边缘发光
    float edge = 1.0 - smoothstep(0.35, 0.5, length(local_uv - 0.5));
    vec3 glow_color = vec3(0.8, 0.4, 1.0);
    
    base_color.rgb = mix(base_color.rgb, glow_color, edge * block_progress * 0.3);
    base_color.a = alpha;
    
    COLOR = base_color;
}

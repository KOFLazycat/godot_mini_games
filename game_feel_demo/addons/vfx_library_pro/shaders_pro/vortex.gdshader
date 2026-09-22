shader_type canvas_item;

// 漩涡扭曲 - 旋转的漩涡扭曲效果
// 商业版独占高级shader

uniform float vortex_strength : hint_range(0.0, 2.0) = 1.0;
uniform float rotation_speed : hint_range(0.5, 5.0) = 2.0;
uniform vec2 vortex_center = vec2(0.5, 0.5);
uniform float vortex_radius : hint_range(0.1, 1.0) = 0.5;

void fragment() {
    vec2 uv = UV;
    vec2 to_center = uv - vortex_center;
    float dist = length(to_center);
    
    // 漩涡强度随距离衰减
    float vortex_mask = smoothstep(vortex_radius, 0.0, dist);
    
    // 旋转角度
    float angle = vortex_mask * vortex_strength * 3.14159;
    angle += TIME * rotation_speed;
    
    // 旋转UV
    float cos_a = cos(angle);
    float sin_a = sin(angle);
    vec2 rotated = vec2(
        to_center.x * cos_a - to_center.y * sin_a,
        to_center.x * sin_a + to_center.y * cos_a
    );
    
    vec2 distorted_uv = vortex_center + rotated;
    
    // 采样颜色
    vec4 base_color = texture(TEXTURE, distorted_uv);
    
    // 漩涡中心发光
    float center_glow = exp(-dist * dist * 10.0) * vortex_mask;
    vec3 glow_color = vec3(0.5, 0.8, 1.0);
    
    base_color.rgb += glow_color * center_glow * 0.3;
    
    // 漩涡螺旋线
    float spiral_angle = atan(to_center.y, to_center.x);
    float spiral = sin(spiral_angle * 3.0 - dist * 10.0 + TIME * rotation_speed) * 0.5 + 0.5;
    base_color.rgb += glow_color * spiral * vortex_mask * 0.2;
    
    COLOR = base_color;
}

shader_type canvas_item;

// 传送特效 - 物体传送时的扫描线和分解效果
// 商业版独占高级shader

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 teleport_color : source_color = vec4(0.3, 0.8, 1.0, 1.0);
uniform float beam_width : hint_range(0.05, 0.5) = 0.15;
uniform float beam_intensity : hint_range(0.5, 3.0) = 2.0;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    vec4 base_color = texture(TEXTURE, uv);
    
    // 扫描光束从上向下（y轴从1到0）
    float beam_pos = 1.0 - progress; // 从顶部扫向底部
    float dist_to_beam = abs(uv.y - beam_pos);
    
    // 光束内部
    float in_beam = smoothstep(beam_width, 0.0, dist_to_beam);
    
    // 光束边缘光晕
    float beam_glow = exp(-dist_to_beam * dist_to_beam * 20.0) * 0.5;
    
    // 在光束范围内：
    // 分解阶段 (progress 0-0.5)：逐渐分解图像
    // 重组阶段 (progress 0.5-1.0)：逐渐重组图像
    
    float dissolve_progress = progress;
    
    // 光束前面的部分逐渐透明
    float ahead_of_beam = step(uv.y, beam_pos);
    float behind_beam = step(beam_pos, uv.y);
    
    float image_alpha = 1.0;
    
    if (progress < 0.5) {
        // 分解阶段：光束扫过的地方消失
        float local_progress = progress * 2.0;
        image_alpha = mix(1.0, 0.0, ahead_of_beam * local_progress);
    } else {
        // 重组阶段：光束扫过的地方重现
        float local_progress = (progress - 0.5) * 2.0;
        image_alpha = mix(0.0, 1.0, ahead_of_beam * local_progress);
    }
    
    // 光束区域的粒子化效果
    vec2 pixelate_uv = uv;
    if (in_beam > 0.1) {
        float pixel_scale = 0.02;
        pixelate_uv = floor(uv / pixel_scale) * pixel_scale;
    }
    
    vec4 pixel_color = texture(TEXTURE, pixelate_uv);
    
    // 混合原始和粒子化颜色
    vec4 display_color = mix(base_color, pixel_color, in_beam * 0.5);
    
    // 应用alpha
    display_color.a = image_alpha;
    
    // 光束颜色叠加
    vec3 beam_color = teleport_color.rgb * (in_beam + beam_glow) * beam_intensity;
    
    // 最终输出
    vec3 final_rgb = mix(display_color.rgb, beam_color, in_beam * 0.3);
    
    // 确保光束始终可见
    float final_alpha = max(display_color.a, in_beam * 0.5 + beam_glow * 0.3);
    
    COLOR = vec4(final_rgb, final_alpha);
}

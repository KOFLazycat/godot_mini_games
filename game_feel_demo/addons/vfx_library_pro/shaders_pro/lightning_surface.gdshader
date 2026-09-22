shader_type canvas_item;
// 🔒 商业版独占 - 闪电覆盖效果
// 电流在物体表面流动

uniform vec4 lightning_color : source_color = vec4(0.5, 0.8, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float lightning_speed : hint_range(0.1, 10.0) = 3.0;
uniform float branch_count : hint_range(1.0, 10.0) = 5.0;
uniform float intensity : hint_range(0.0, 2.0) = 1.0;
uniform float thickness : hint_range(0.001, 0.05) = 0.01;
uniform float glow_strength : hint_range(0.0, 3.0) = 2.0;

// 随机函数
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// 噪声函数
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// 生成闪电路径
float lightning_bolt(vec2 uv, float seed, float time_offset) {
    float lightning = 0.0;
    
    // 主闪电路径（曲线）
    float x = uv.x;
    float target_y = 0.5 + noise(vec2(seed, time_offset)) * 0.3;
    
    // 使用噪声创建弯曲路径
    for (int ii = 0; ii < 5; ii++) {
        float segment = float(ii) / 5.0;
        float deviation = noise(vec2(x * 10.0 + seed, segment + time_offset)) * 0.2 - 0.1;
        target_y += deviation;
    }
    
    // 计算到闪电路径的距离
    float dist = abs(uv.y - target_y);
    
    // 主闪电
    float main_bolt = smoothstep(thickness, 0.0, dist);
    
    // 核心（更亮）
    float core = smoothstep(thickness * 0.3, 0.0, dist);
    
    lightning = main_bolt + core * 2.0;
    
    // 分支
    int bc = int(clamp(branch_count, 1.0, 20.0));
    for (int ii = 0; ii < bc; ii++) {
        float branch_x = random(vec2(seed, float(ii))) * 0.7 + 0.15;
        if (abs(x - branch_x) < 0.1) {
            float branch_angle = (random(vec2(seed + i, 0.0)) - 0.5) * 0.5;
            float branch_y = target_y + (x - branch_x) * branch_angle;
            float branch_dist = abs(uv.y - branch_y);
            lightning += smoothstep(thickness * 0.5, 0.0, branch_dist) * 0.5;
        }
    }
    
    return lightning;
}

void fragment() {
    vec2 uv = UV;
    float time = TIME * lightning_speed;
    
    // 闪烁效果
    float flicker = step(0.3, random(vec2(floor(time * 10.0))));
    
    // 多条闪电
    float lightning = 0.0;
    for (int ii = 0; ii < 3; ii++) {
        float seed = float(ii) * 100.0;
        float time_offset = time + float(ii) * 0.3;
        
        // 闪电闪烁（随机出现/消失）
        float bolt_flicker = step(0.6, random(vec2(floor(time_offset), i)));
        
        lightning += lightning_bolt(uv, seed, time_offset) * bolt_flicker;
    }
    
    // 整体闪烁
    lightning *= flicker;
    
    // 电弧扫描线（额外细节）
    float scan_line = abs(sin(uv.y * 50.0 + time * 5.0));
    lightning += scan_line * 0.05 * flicker;
    
    // 应用强度
    lightning *= intensity;
    lightning = clamp(lightning, 0.0, 3.0);
    
    // 采样原始纹理
    vec4 tex = texture(TEXTURE, uv);
    
    // 颜色渐变（核心白色，边缘蓝色）
    vec3 bolt_color;
    if (lightning > 1.5) {
        bolt_color = core_color.rgb;
    } else if (lightning > 0.5) {
        bolt_color = mix(lightning_color.rgb, core_color.rgb, (lightning - 0.5) / 1.0);
    } else {
        bolt_color = lightning_color.rgb * (lightning / 0.5);
    }
    
    // 混合纹理和闪电
    vec3 final_color = tex.rgb + bolt_color * lightning * 0.5;
    
    // 发光
    final_color += bolt_color * smoothstep(0.0, 1.0, lightning) * glow_strength;
    
    // 电流对原图的影响（轻微变亮）
    final_color += tex.rgb * lightning * 0.3;
    
    COLOR = vec4(final_color, tex.a);
}

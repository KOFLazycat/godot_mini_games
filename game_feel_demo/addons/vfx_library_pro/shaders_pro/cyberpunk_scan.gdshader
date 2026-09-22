shader_type canvas_item;

// 赛博朋克扫描 - 未来科技风格的扫描效果
// 商业版独占高级shader

uniform float scan_speed : hint_range(0.5, 5.0) = 2.0;
uniform float scan_width : hint_range(0.01, 0.3) = 0.1;
uniform float line_density : hint_range(5.0, 50.0) = 20.0;
uniform vec4 scan_color : source_color = vec4(0.0, 1.0, 0.8, 1.0);
uniform vec4 grid_color : source_color = vec4(0.0, 0.8, 1.0, 0.5);
uniform float grid_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float chromatic_aberration : hint_range(0.0, 0.02) = 0.005;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    
    // 扫描线位置
    float scan_pos = fract(TIME * scan_speed);
    float dist_to_scan = abs(uv.y - scan_pos);
    
    // 主扫描线
    float scan_line = smoothstep(scan_width, scan_width * 0.3, dist_to_scan);
    
    // 扫描区域的色差效果
    vec2 aberration_offset = vec2(chromatic_aberration, 0.0) * scan_line;
    vec4 color_r = texture(TEXTURE, uv + aberration_offset);
    vec4 color_g = texture(TEXTURE, uv);
    vec4 color_b = texture(TEXTURE, uv - aberration_offset);
    vec4 base_color = vec4(color_r.r, color_g.g, color_b.b, color_g.a);
    
    // 水平扫描线网格
    float h_lines = fract(uv.y * line_density);
    float h_grid = smoothstep(0.1, 0.0, h_lines) + smoothstep(0.9, 1.0, h_lines);
    
    // 垂直网格线
    float v_lines = fract(uv.x * line_density * 0.5);
    float v_grid = smoothstep(0.05, 0.0, v_lines) + smoothstep(0.95, 1.0, v_lines);
    
    // 组合网格
    float grid = (h_grid + v_grid) * grid_intensity;
    
    // 数据块效果
    float block_x = floor(uv.x * 10.0);
    float block_y = floor((uv.y - scan_pos + 0.5) * 5.0);
    float block_noise = hash(vec2(block_x, block_y + TIME * 2.0));
    float data_blocks = step(0.7, block_noise) * smoothstep(0.2, 0.0, dist_to_scan);
    
    // 扫描波纹
    float ripple1 = sin((dist_to_scan - TIME * 2.0) * 30.0) * 0.5 + 0.5;
    float ripple_mask = smoothstep(0.3, 0.0, dist_to_scan);
    float ripple = ripple1 * ripple_mask * 0.3;
    
    // 扫描光晕
    float glow = exp(-dist_to_scan * 10.0) * 0.5;
    
    // 边缘检测效果
    float edge_detect = 0.0;
    if (scan_line > 0.1) {
        vec2 offset = vec2(0.01, 0.01);
        float center = texture(TEXTURE, uv).r;
        float top = texture(TEXTURE, uv + vec2(0.0, offset.y)).r;
        float bottom = texture(TEXTURE, uv - vec2(0.0, offset.y)).r;
        float left = texture(TEXTURE, uv - vec2(offset.x, 0.0)).r;
        float right = texture(TEXTURE, uv + vec2(offset.x, 0.0)).r;
        
        edge_detect = abs(center * 4.0 - top - bottom - left - right);
        edge_detect = smoothstep(0.1, 0.3, edge_detect);
    }
    
    // 组合所有效果
    vec4 final_color = base_color;
    
    // 添加网格
    final_color.rgb = mix(final_color.rgb, grid_color.rgb, grid);
    
    // 添加扫描效果
    final_color.rgb = mix(final_color.rgb, scan_color.rgb, scan_line * 0.5);
    final_color.rgb += scan_color.rgb * glow;
    final_color.rgb += scan_color.rgb * ripple;
    
    // 添加数据块
    final_color.rgb += vec3(data_blocks) * scan_color.rgb * 0.5;
    
    // 添加边缘高亮
    final_color.rgb += edge_detect * scan_color.rgb * scan_line;
    
    // 整体色调调整
    final_color.rgb = mix(final_color.rgb, final_color.rgb * vec3(0.5, 1.0, 1.0), 0.2);
    
    // 扫描区域提亮
    final_color.rgb *= (1.0 + scan_line * 0.3);
    
    COLOR = final_color;
}

shader_type canvas_item;

// 矩阵代码雨 - 黑客帝国风格的数字流
// 商业版独占高级shader

uniform float speed : hint_range(0.5, 5.0) = 2.0;
uniform float density : hint_range(0.1, 1.0) = 0.5;
uniform vec4 code_color : source_color = vec4(0.2, 1.0, 0.3, 1.0);
uniform vec4 bright_color : source_color = vec4(0.8, 1.0, 0.9, 1.0);
uniform float overlay_strength : hint_range(0.0, 1.0) = 0.7;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float hash13(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    
    // 列宽
    float column_width = 0.02;
    float column_id = floor(uv.x / column_width);
    float column_x = fract(uv.x / column_width);
    
    // 每列的随机偏移
    float column_offset = hash(vec2(column_id, 0.0));
    float column_speed = 0.5 + hash(vec2(column_id, 1.0)) * 1.5;
    
    // 代码流动
    float y_offset = fract(TIME * speed * column_speed + column_offset);
    float char_y = fract(uv.y - y_offset);
    
    // 字符网格
    float char_height = 0.05;
    float char_id_y = floor((uv.y - y_offset) / char_height);
    float char_local_y = fract((uv.y - y_offset) / char_height);
    
    // 字符随机性
    float char_random = hash13(vec3(column_id, char_id_y, floor(TIME * 2.0)));
    
    // 只在一定密度下显示字符
    float char_visible = step(1.0 - density, char_random);
    
    // 字符形状（简化的矩形）
    float char_shape = step(0.1, column_x) * step(column_x, 0.9);
    char_shape *= step(0.2, char_local_y) * step(char_local_y, 0.8);
    
    // 字符强度
    float char_intensity = char_visible * char_shape;
    
    // 头部明亮字符
    float head_bright = smoothstep(0.1, 0.0, char_y) * smoothstep(0.0, 0.05, char_y);
    
    // 尾部渐弱
    float tail_fade = smoothstep(1.0, 0.3, char_y);
    
    // 最终字符颜色
    vec4 char_color = mix(code_color, bright_color, head_bright);
    float final_intensity = char_intensity * tail_fade;
    
    // 添加随机闪烁
    float flicker = step(0.95, hash13(vec3(column_id, char_id_y, TIME * 10.0)));
    final_intensity += flicker * 0.3;
    
    // 原始纹理
    vec4 base_color = texture(TEXTURE, UV);
    
    // 混合代码雨效果
    vec4 matrix_effect = vec4(char_color.rgb, final_intensity);
    
    // 叠加到原始纹理
    COLOR = mix(base_color, matrix_effect, overlay_strength * final_intensity);
    COLOR.rgb += matrix_effect.rgb * final_intensity * 0.3;
    
    // 整体绿色色调
    COLOR.rgb = mix(COLOR.rgb, COLOR.rgb * vec3(0.3, 1.0, 0.3), overlay_strength * 0.3);
}

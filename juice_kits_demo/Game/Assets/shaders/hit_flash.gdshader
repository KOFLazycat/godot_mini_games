// Whitens a sprite without touching its alpha, so the flash never leaks outside
// the silhouette. Mixing toward a colour rather than adding to it means it reads
// the same on dark and bright sprites.
shader_type canvas_item;


uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	COLOR.rgb = mix(COLOR.rgb, flash_color.rgb, flash_amount * flash_color.a);
}

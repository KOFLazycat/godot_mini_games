// CRT filter. Curvature, scanlines, phosphor mask, bloom, grain, flicker and
// vignette all in one pass, because every extra full screen pass re-reads the
// whole screen texture and that adds up fast on weak hardware.
// clock is fed from GDScript instead of using TIME so the grain keeps moving
// during a hitstop. A frozen screen with frozen grain looks like a crash.
shader_type canvas_item;


uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D noise_texture : repeat_enable, filter_linear;

uniform float curvature : hint_range(0.0, 1.0) = 0.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.0;
uniform float scanline_count = 540.0;
uniform float mask_strength : hint_range(0.0, 1.0) = 0.0;
uniform float grain : hint_range(0.0, 1.0) = 0.0;
uniform float flicker : hint_range(0.0, 1.0) = 0.0;
uniform float bloom : hint_range(0.0, 2.0) = 0.0;
uniform float brightness : hint_range(0.0, 2.0) = 1.0;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;
uniform vec4 border_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform float aberration : hint_range(0.0, 0.05) = 0.0;
uniform float vignette : hint_range(0.0, 1.0) = 0.0;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float warp : hint_range(0.0, 1.0) = 0.0;

uniform float clock = 0.0;

const float PI2 = 6.2831853;

vec2 curve_uv(vec2 uv, float amount) {
	uv = uv * 2.0 - 1.0;
	vec2 offset = abs(uv.yx) / vec2(6.0, 4.0);
	uv += uv * offset * offset * amount;
	return uv * 0.5 + 0.5;
}

vec3 phosphor_mask(vec2 frag) {
	float column = mod(frag.x, 3.0);
	vec3 tint = vec3(0.86);
	if (column < 1.0) {
		tint.r = 1.25;
	} else if (column < 2.0) {
		tint.g = 1.25;
	} else {
		tint.b = 1.25;
	}
	return tint;
}

vec3 sample_bloom(vec2 uv, vec2 texel) {
	vec3 sum = vec3(0.0);
	sum += texture(screen_texture, uv + vec2(texel.x, texel.y) * 2.0).rgb;
	sum += texture(screen_texture, uv + vec2(-texel.x, texel.y) * 2.0).rgb;
	sum += texture(screen_texture, uv + vec2(texel.x, -texel.y) * 2.0).rgb;
	sum += texture(screen_texture, uv + vec2(-texel.x, -texel.y) * 2.0).rgb;
	sum *= 0.25;
	return max(sum - 0.55, vec3(0.0));
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 texel = SCREEN_PIXEL_SIZE;

	if (curvature > 0.001) {
		uv = curve_uv(uv, curvature);
	}

	if (warp > 0.001) {
		float wave = sin(uv.y * 80.0 + clock * 14.0) * sin(uv.y * 13.0 - clock * 5.0);
		uv.x += wave * warp * 0.02;
	}

	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = border_color;
	} else {
		vec2 center_offset = uv - vec2(0.5);

		vec3 color;
		if (aberration > 0.0001) {
			color.r = texture(screen_texture, uv - center_offset * aberration).r;
			color.g = texture(screen_texture, uv).g;
			color.b = texture(screen_texture, uv + center_offset * aberration).b;
		} else {
			color = texture(screen_texture, uv).rgb;
		}

		if (bloom > 0.001) {
			color += sample_bloom(uv, texel) * bloom;
		}

		if (scanline_strength > 0.001) {
			float line = 0.5 + 0.5 * sin(uv.y * scanline_count * PI2 * 0.5);
			color *= 1.0 - scanline_strength * line;
		}

		if (mask_strength > 0.001) {
			color *= mix(vec3(1.0), phosphor_mask(FRAGCOORD.xy), mask_strength);
		}

		if (grain > 0.001) {
			vec2 grain_uv = uv * 3.0 + vec2(fract(clock * 1.7), fract(clock * 2.3));
			vec3 speckle = texture(noise_texture, grain_uv).rgb - 0.5;
			color += speckle * grain * 0.25;
		}

		if (flicker > 0.001) {
			color *= 1.0 - flicker * 0.06 * (0.5 + 0.5 * sin(clock * 96.0));
		}

		if (saturation < 0.999 || saturation > 1.001) {
			float grey = dot(color, vec3(0.299, 0.587, 0.114));
			color = mix(vec3(grey), color, saturation);
		}

		color *= brightness;

		if (vignette > 0.001) {
			float dist = length(center_offset) * 1.414;
			color = mix(color, vignette_color.rgb, smoothstep(0.35, 1.0, dist) * vignette);
		}

		COLOR = vec4(color, 1.0);
	}
}

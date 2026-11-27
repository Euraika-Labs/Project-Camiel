shader_type canvas_item;
render_mode unshaded, blend_disabled;

uniform sampler2D scene_color : hint_screen_texture, repeat_disable, filter_linear;

float luma(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 pixel = SCREEN_PIXEL_SIZE;
	vec2 uv = SCREEN_UV;
	vec3 center = texture(scene_color, uv).rgb;
	float nw = luma(texture(scene_color, uv + pixel * vec2(-1.0, -1.0)).rgb);
	float ne = luma(texture(scene_color, uv + pixel * vec2(1.0, -1.0)).rgb);
	float sw = luma(texture(scene_color, uv + pixel * vec2(-1.0, 1.0)).rgb);
	float se = luma(texture(scene_color, uv + pixel * vec2(1.0, 1.0)).rgb);
	float center_luma = luma(center);
	float bright = max(center_luma, max(max(nw, ne), max(sw, se)));
	float dark = min(center_luma, min(min(nw, ne), min(sw, se)));
	vec2 edge = vec2(nw + ne - sw - se, ne + se - nw - sw);
	float longest = max(abs(edge.x), abs(edge.y));
	if (bright - dark > max(0.035, bright * 0.12) && longest > 0.01) {
		vec2 step_along_edge = edge * pixel * (0.75 / longest);
		vec3 softened = 0.5 * (texture(scene_color, uv - step_along_edge).rgb
			+ texture(scene_color, uv + step_along_edge).rgb);
		center = mix(center, softened, 0.75);
	}
	COLOR = vec4(center, 1.0);
}

shader_type spatial;
render_mode specular_disabled;

uniform vec4 grass : source_color = vec4(0.34, 0.50, 0.31, 1.0);
uniform vec4 grass_light : source_color = vec4(0.53, 0.65, 0.41, 1.0);
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_position.xz;
	float sweeps = sin(p.x * 0.83 + cos(p.y * 0.47) * 1.6) * 0.26;
	float patches = cos(p.y * 1.19 - p.x * 0.62) * 0.12;
	vec2 cell = fract(p * 4.0) - 0.5;
	float tuft = 1.0 - smoothstep(0.09, 0.24, length(cell * vec2(1.0, 0.62)));
	float detail = tuft * 0.06 * (1.0 - smoothstep(0.035, 0.13, length(fwidth(p))));
	ALBEDO = mix(grass.rgb, grass_light.rgb, 0.46 + sweeps + patches + detail);
	ROUGHNESS = 1.0;
}

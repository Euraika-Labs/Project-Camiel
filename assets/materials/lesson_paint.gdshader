shader_type spatial;
render_mode unshaded, fog_disabled;

uniform vec4 pigment : source_color = vec4(1.0);
uniform bool completed = false;
varying vec3 world_normal;

void vertex() {
	world_normal = MODEL_NORMAL_MATRIX * NORMAL;
}

void fragment() {
	// Follow the garden's light direction with a limited range of values.
	// The painted faces keep their hue even in the brightest part of the yard.
	vec3 sun_direction = normalize(vec3(-0.29, 0.83, 0.48));
	float facing_sun = max(dot(normalize(world_normal), sun_direction), 0.0);
	float brightness = mix(0.79, 1.0, facing_sun);
	float sheen = smoothstep(0.58, 0.98, facing_sun) * 0.06;
	vec3 color = mix(pigment.rgb * brightness, vec3(1.0), sheen);
	ALBEDO = completed ? color * 0.88 : color;
}

shader_type canvas_item;

uniform float vignette_strength : hint_range(0.0, 2.0) = 0.98;
uniform float vignette_radius : hint_range(0.0, 1.5) = 0.59;
uniform float vignette_softness : hint_range(0.0, 1.0) = 0.99;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv);
	float vignette = smoothstep(vignette_radius, vignette_radius - vignette_softness, dist);
	COLOR = vec4(0.0, 0.0, 0.0, (1.0 - vignette) * vignette_strength);
}
shader_type canvas_item;

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = (UV - 0.5);
	float d = length(uv);
	float vig = smoothstep(0.15, 0.9, d) * vignette_strength;
	COLOR = vec4(0.0, 0.0, 0.0, vig);
}
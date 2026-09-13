shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 3.0) = 1.4;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.54;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 centered = uv - vec2(0.5);
	float dist = length(centered) * vignette_intensity;
	float vignette = smoothstep(0.4, 1.15, dist);
	COLOR = vec4(0.0, 0.0, 0.0, vignette * vignette_opacity);
}
shader_type canvas_item;
uniform float fire_gain = 1.0;
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec2 pixel = UV * vec2(256.0, 320.0);
	float region = step(18.0, pixel.x) * step(pixel.x, 90.0) * step(40.0, pixel.y) * step(pixel.y, 164.0);
	float heat = smoothstep(0.45, 0.75, source.r) * smoothstep(0.10, 0.30, source.g) * smoothstep(0.10, 0.35, source.r - source.b);
	COLOR.rgb *= mix(1.0, fire_gain, region * heat);
}

shader_type canvas_item;
render_mode unshaded;
uniform vec4 overlay = vec4(0.0);
uniform vec4 tone = vec4(0.0);
uniform float opacity = 1.0;
void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	float gray = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
	pixel.rgb = clamp(mix(pixel.rgb, vec3(gray), tone.a) + tone.rgb, vec3(0.0), vec3(1.0));
	pixel.rgb = mix(pixel.rgb, overlay.rgb, overlay.a);
	pixel.a *= opacity;
	COLOR = pixel;
}

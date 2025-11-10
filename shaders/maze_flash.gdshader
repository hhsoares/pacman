shader_type canvas_item;
uniform float flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a < 0.1) discard;

	if (c.r < 0.01 && c.g < 0.01 && c.b < 0.01) {
		COLOR = c;
	} else {
		COLOR = mix(c, vec4(1.0), flash);
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}

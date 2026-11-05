shader_type canvas_item;
// post-processing z Remasteru: vinětace, zrno, chromatická aberace, scanlines, glitch
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear;
uniform float uT = 0.0;
uniform float uVig = 0.75;
uniform float uGrain = 0.04;
uniform float uCA = 0.002;
uniform float uScan = 0.0;
uniform float uGlitch = 0.0;
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = SCREEN_UV;
	float row = floor(uv.y * 48.0);
	float g = step(1.0 - uGlitch * .35, h(vec2(row, floor(uT * 24.0))));
	uv.x += g * (h(vec2(row, uT)) - .5) * .12 * uGlitch;
	vec2 d = (uv - .5) * (uCA + uGlitch * .012);
	vec3 c = vec3(texture(SCREEN_TEXTURE, uv + d).r, texture(SCREEN_TEXTURE, uv).g, texture(SCREEN_TEXTURE, uv - d).b);
	c += (h(uv * 512.0 + uT * 7.0) - .5) * uGrain;
	c *= 1.0 - uVig * dot(uv - .5, uv - .5) * 2.0;
	c *= 1.0 - uScan * .28 * step(.5, fract(FRAGCOORD.y * .5));
	COLOR = vec4(c, 1.0);
}

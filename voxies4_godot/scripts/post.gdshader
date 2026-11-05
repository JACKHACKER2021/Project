shader_type canvas_item;
// post-processing z Remasteru: vinětace, zrno, chromatická aberace, scanlines, glitch
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear;
uniform float uT = 0.0;
uniform float uVig = 0.75;
uniform float uGrain = 0.04;
uniform float uCA = 0.002;
uniform float uScan = 0.0;
uniform float uGlitch = 0.0;
uniform float uSway = 0.0;    // závrať: vlnění obrazu
uniform float uDouble = 0.0;  // dvojité vidění
uniform float uSick = 0.0;    // nevolnost: zelenavý nádech a pulzování
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = SCREEN_UV;
	float row = floor(uv.y * 48.0);
	float g = step(1.0 - uGlitch * .35, h(vec2(row, floor(uT * 24.0))));
	uv.x += g * (h(vec2(row, uT)) - .5) * .12 * uGlitch;
	uv += vec2(sin(uv.y * 9.0 + uT * 1.7), cos(uv.x * 7.0 + uT * 1.3)) * uSway;
	uv = (uv - .5) * (1.0 - uSick * .03 * (.5 + .5 * sin(uT * 2.2))) + .5;
	vec2 d = (uv - .5) * (uCA + uGlitch * .012 + uSway * .4);
	vec3 c = vec3(texture(SCREEN_TEXTURE, uv + d).r, texture(SCREEN_TEXTURE, uv).g, texture(SCREEN_TEXTURE, uv - d).b);
	vec2 off = vec2(uDouble * sin(uT * .9), uDouble * .4 * cos(uT * 1.1));
	c = mix(c, texture(SCREEN_TEXTURE, uv + off).rgb, clamp(uDouble * 18.0, 0.0, .45));
	float lum = dot(c, vec3(.3, .59, .11));
	c = mix(c, vec3(lum * .8, lum * 1.05, lum * .55), uSick * .55);
	c += (h(uv * 512.0 + uT * 7.0) - .5) * uGrain;
	c *= 1.0 - uVig * dot(uv - .5, uv - .5) * 2.0;
	c *= 1.0 - uScan * .28 * step(.5, fract(FRAGCOORD.y * .5));
	COLOR = vec4(c, 1.0);
}

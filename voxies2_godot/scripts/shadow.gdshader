shader_type spatial;
// stínová Cocoa: černá silueta s fialovým okrajem a pomalu stoupajícím kouřem
render_mode unshaded, cull_back, depth_draw_always, blend_mix;
uniform float uT = 0.0;
uniform float uOp = 0.9;
varying vec3 vW;
float h(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
float n3(vec3 p) { vec3 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h(i), h(i + vec3(1,0,0)), f.x), mix(h(i + vec3(0,1,0)), h(i + vec3(1,1,0)), f.x), f.y), mix(mix(h(i + vec3(0,0,1)), h(i + vec3(1,0,1)), f.x), mix(h(i + vec3(0,1,1)), h(i + vec3(1,1,1)), f.x), f.y), f.z); }
void vertex() { vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float fr = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.2);
	float sm = n3(vW * 4.0 + vec3(0.0, -uT * .6, uT * .2)) * .6 + n3(vW * 9.0 - vec3(0.0, uT * 1.1, 0.0)) * .4;
	ALBEDO = vec3(.2, .15, .3) * pow(fr, 1.8) * 1.3 + vec3(.012) * sm;
	ALPHA = clamp(uOp + .2, .0, 1.) * (.94 + .06 * sm);
}

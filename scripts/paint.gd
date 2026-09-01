class_name Paint
## Procedural shader layer — all shader code lives in these strings, so the
## zero-asset-files rule still holds. This is what lifts the flat _draw()
## polygons toward realism: per-pixel noise texture on big surfaces, fbm
## clouds and sun glow in the sky, and a gentle full-screen colour grade.
## Everything is slow and soft — nothing flashes.

## Noise comes from a runtime-generated seamless NoiseTexture2D — sampling a
## texture is precision-safe on the mobile renderer's half floats, where
## arithmetic sin() hashes shatter into visible facets.
const _NOISE_LIB := """
uniform sampler2D noise_tex : repeat_enable, filter_linear;
float vnoise(vec2 p) {
	return texture(noise_tex, p * 0.13).r;
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	mat2 rot = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p = rot * p * 2.03 + vec2(7.3);
		a *= 0.5;
	}
	return v * 1.07;
}
"""

## Sky: three-stop gradient, sun disc with a soft glow, and two layers of
## slowly drifting fbm clouds with shaded undersides.
const SKY_SHADER := """
shader_type canvas_item;
uniform vec2 sun_pos = vec2(0.867, 0.163);
uniform float aspect = 1.6;
""" + _NOISE_LIB + """
float cloud_cov(vec2 sp, float t) {
	vec2 cp = sp * 1.9 + vec2(t * 0.005, 0.0);
	float n = fbm(cp);
	float n2 = fbm(cp * 2.3 + vec2(4.7, 9.1) + t * 0.003);
	return smoothstep(0.46, 0.72, n * 0.62 + n2 * 0.44);
}
void fragment() {
	vec2 uv = UV;
	vec3 top = vec3(0.58, 0.78, 0.91);
	vec3 mid = vec3(0.79, 0.90, 0.96);
	vec3 low = vec3(0.97, 0.93, 0.84);
	vec3 col = mix(top, mid, smoothstep(0.0, 0.45, uv.y));
	col = mix(col, low, smoothstep(0.45, 0.76, uv.y));
	// sun glow + disc
	vec2 d = (uv - sun_pos) * vec2(aspect, 1.0);
	float sd = length(d);
	col += vec3(1.0, 0.85, 0.55) * 0.30 * exp(-sd * sd * 30.0);
	col += vec3(1.0, 0.90, 0.60) * 0.10 * exp(-sd * 4.0);
	col = mix(col, vec3(1.0, 0.90, 0.62), smoothstep(0.064, 0.052, sd));
	col = mix(col, vec3(1.0, 0.95, 0.76), smoothstep(0.050, 0.034, sd));
	// clouds — isotropic in screen space (slightly squashed for perspective),
	// kept in the upper sky and faded well before the horizon
	vec2 sp = vec2(uv.x * aspect, uv.y * 1.35);
	float cov = cloud_cov(sp, TIME);
	float above = cloud_cov(sp + vec2(0.0, -0.06), TIME);
	float band = 1.0 - smoothstep(0.30, 0.60, uv.y);
	float shade = clamp(above - cov * 0.35, 0.0, 1.0);
	vec3 cloud_col = mix(vec3(1.0), vec3(0.80, 0.845, 0.885), shade * 0.9);
	// sunlit warmth on cloud faces near the sun
	cloud_col += vec3(0.10, 0.06, 0.0) * exp(-sd * 3.0);
	col = mix(col, cloud_col, cov * band * 0.92);
	COLOR = vec4(col, 1.0);
}
"""

## Organic mottled grain overlaid on big flat fills (dirt, turf, wood).
## Pixels darker than the midtone tint toward `dark`, lighter toward `light`.
const GRAIN_SHADER := """
shader_type canvas_item;
uniform float scale = 46.0;
uniform float strength : hint_range(0.0, 1.0) = 0.14;
uniform vec4 dark : source_color = vec4(0.2, 0.12, 0.05, 1.0);
uniform vec4 light : source_color = vec4(1.0, 0.95, 0.8, 1.0);
uniform vec2 px_size = vec2(1000.0, 300.0);
uniform vec2 stretch = vec2(1.0, 1.0);
""" + _NOISE_LIB + """
void fragment() {
	vec2 p = UV * px_size / scale * stretch;
	float v = fbm(p) * 0.7 + vnoise(p * 2.1 + vec2(3.7, 1.9)) * 0.3;
	float s = (v - 0.5) * 2.0;
	vec3 tint = s > 0.0 ? light.rgb : dark.rgb;
	COLOR = vec4(tint, abs(s) * strength);
}
"""

## Full-screen grade: gentle S-curve, a touch more saturation, warm lights /
## cool shades, and a soft vignette. Sits under the HUD so UI stays clean.
const GRADE_SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float vignette = 0.14;
uniform float saturation = 1.07;
uniform float warmth = 0.035;
uniform float contrast = 0.14;
void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	c = mix(c, c * c * (3.0 - 2.0 * c), contrast);
	float g = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(g), c, saturation);
	c += (g - 0.5) * vec3(warmth, warmth * 0.35, -warmth);
	vec2 d = SCREEN_UV - 0.5;
	c *= 1.0 - vignette * smoothstep(0.2, 0.75, dot(d, d) * 2.0);
	COLOR = vec4(c, 1.0);
}
"""


static var _noise_tex: NoiseTexture2D = null


## Seamless perlin noise texture, generated once at runtime (no asset file).
static func noise_tex() -> Texture2D:
	if _noise_tex == null:
		var n := FastNoiseLite.new()
		n.noise_type = FastNoiseLite.TYPE_PERLIN
		n.frequency = 0.016
		n.seed = 7
		_noise_tex = NoiseTexture2D.new()
		_noise_tex.width = 256
		_noise_tex.height = 256
		_noise_tex.seamless = true
		_noise_tex.noise = n
	return _noise_tex


static func _material(code: String) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = code
	var mat := ShaderMaterial.new()
	mat.shader = sh
	if code.contains("noise_tex"):
		mat.set_shader_parameter("noise_tex", noise_tex())
	return mat


static func sky_material() -> ShaderMaterial:
	return _material(SKY_SHADER)


## A grain overlay covering `rect` (in the parent's coordinate space).
static func grain(rect: Rect2, scale: float, strength: float, dark: Color, light: Color,
		stretch := Vector2.ONE) -> ColorRect:
	var cr := ColorRect.new()
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cr.position = rect.position
	cr.size = rect.size
	var mat := _material(GRAIN_SHADER)
	mat.set_shader_parameter("scale", scale)
	mat.set_shader_parameter("strength", strength)
	mat.set_shader_parameter("dark", dark)
	mat.set_shader_parameter("light", light)
	mat.set_shader_parameter("px_size", rect.size)
	mat.set_shader_parameter("stretch", stretch)
	cr.material = mat
	return cr


## The screen-space grade, on its own CanvasLayer. Add it just BEFORE the Hud
## so it draws above the world but under every UI layer.
static func grade_layer() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 1
	layer.add_child(Fullscreen.new(_material(GRADE_SHADER)))
	return layer


## A ColorRect that keeps itself sized to the whole viewport.
class Fullscreen extends ColorRect:
	func _init(mat: ShaderMaterial) -> void:
		material = mat
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		_fit()
		get_viewport().size_changed.connect(_fit)

	func _fit() -> void:
		position = Vector2.ZERO
		size = get_viewport().get_visible_rect().size

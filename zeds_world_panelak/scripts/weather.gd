extends Node3D
## Venku je růžová obloha a prší.

var slunce: DirectionalLight3D
var prostredi: Environment
var dest: GPUParticles3D
var hrac: Node3D

func _ready() -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var mat := ProceduralSkyMaterial.new()
	mat.sky_top_color = Color(0.86, 0.44, 0.62)        # sytě růžová nahoře
	mat.sky_horizon_color = Color(0.98, 0.72, 0.78)    # bledší u obzoru
	mat.ground_bottom_color = Color(0.16, 0.12, 0.15)
	mat.ground_horizon_color = Color(0.72, 0.52, 0.58)
	mat.sun_angle_max = 24.0
	mat.energy_multiplier = 0.9
	sky.sky_material = mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.42
	env.fog_enabled = true
	env.fog_light_color = Color(0.85, 0.58, 0.66)
	env.fog_density = 0.0035
	env.fog_sky_affect = 0.5
	env.fog_aerial_perspective = 0.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08

	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	prostredi = env

	slunce = DirectionalLight3D.new()
	slunce.light_color = Color(1.0, 0.78, 0.84)
	slunce.light_energy = 0.55                  # zataženo, prší
	slunce.rotation_degrees = Vector3(-28, 36, 0)
	slunce.shadow_enabled = true
	slunce.directional_shadow_max_distance = 120.0
	add_child(slunce)

	_postav_dest()
	await get_tree().process_frame
	hrac = get_tree().get_first_node_in_group("hrac")

func _postav_dest() -> void:
	dest = GPUParticles3D.new()
	dest.amount = 900
	dest.lifetime = 1.6
	dest.visibility_aabb = AABB(Vector3(-25, -25, -25), Vector3(50, 50, 50))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(22, 0.5, 22)
	pm.direction = Vector3(0.12, -1, 0.05)
	pm.spread = 2.0
	pm.initial_velocity_min = 14.0
	pm.initial_velocity_max = 19.0
	pm.gravity = Vector3(0, -9.8, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	dest.process_material = pm
	var m := QuadMesh.new()
	m.size = Vector2(0.015, 0.5)
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.86, 0.80, 0.88, 0.45)
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	sm.billboard_keep_scale = true
	m.material = sm
	dest.draw_pass_1 = m
	add_child(dest)

func _process(_d: float) -> void:
	if hrac == null:
		return
	var venku: bool = absf(hrac.global_position.x) > ZWConfig.HX \
		or absf(hrac.global_position.z) > ZWConfig.HZ
	# déšť se veze s hráčem, ale uvnitř domu ho nekreslíme
	dest.global_position = hrac.global_position + Vector3(0, 14, 0)
	dest.emitting = venku
	# uvnitř se mlha i obloha musí vypnout, jinak je celý byt růžový
	if prostredi:
		prostredi.fog_enabled = venku
		prostredi.ambient_light_energy = 0.42 if venku else 0.06
	if slunce:
		slunce.light_energy = 0.55 if venku else 0.06

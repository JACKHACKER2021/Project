extends Node3D
## Pouliční lampy kolem paneláku. Kánon (fáze 14–15): dokud člověk stojí
## v kuželu světla, sirény ani Zéd si ho venku netroufnou vzít.
## Útěk z domu je proto běh od lampy k lampě.

var hrac: CharacterBody3D
var lampy: Array[Node3D] = []
const ROZTEC := 18.0
const POLOMER_SVETLA := 5.5

func _ready() -> void:
	for sx in [-1.0, 1.0]:
		for i in 9:
			var z := -ZWConfig.HZ - 8.0 + i * ROZTEC
			_lampa(Vector3(sx * (ZWConfig.HX + 9.5), 0.0, z))
	await get_tree().process_frame
	if hrac == null:
		hrac = get_tree().get_first_node_in_group("hrac")

func _lampa(kde: Vector3) -> void:
	var n := Node3D.new()
	n.position = kde
	add_child(n)
	var stozar := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.09
	cm.bottom_radius = 0.13
	cm.height = 8.0
	stozar.mesh = cm
	stozar.position.y = 4.0
	n.add_child(stozar)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var cap := CylinderShape3D.new()
	cap.radius = 0.16
	cap.height = 8.0
	cs.shape = cap
	cs.position.y = 4.0
	sb.add_child(cs)
	n.add_child(sb)
	var sv := OmniLight3D.new()
	sv.position.y = 7.6
	sv.light_color = Color(1.0, 0.86, 0.66)
	sv.light_energy = 6.0
	sv.omni_range = 16.0
	sv.shadow_enabled = false
	n.add_child(sv)
	n.set_meta("svetlo", sv)
	lampy.append(n)

func v_bezpeci(p: Vector3) -> bool:
	for n in lampy:
		var sv: OmniLight3D = n.get_meta("svetlo")
		if sv.visible and Vector2(p.x - n.position.x, p.z - n.position.z).length() < POLOMER_SVETLA:
			return true
	return false

func _process(_d: float) -> void:
	if hrac == null:
		return
	# fáze 7: lampa, ke které se přiblížíš, zhasne — smrt stojí hned vedle
	for n in lampy:
		var sv: OmniLight3D = n.get_meta("svetlo")
		if not sv.visible:
			continue
		if hrac.global_position.distance_to(n.global_position) < 3.0 and randf() < 0.004:
			sv.visible = false
	hrac.set_meta("ve_svetle", v_bezpeci(hrac.global_position))
